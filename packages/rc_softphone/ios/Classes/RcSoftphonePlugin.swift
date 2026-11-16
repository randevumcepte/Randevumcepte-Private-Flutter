import AVFoundation
import Flutter
import PushKit
import UIKit
import WebRTC
import flutter_callkit_incoming

/// rc_softphone iOS native tarafi. Iki is yapar:
///
/// 1) CallKit <-> WebRTC ses oturumu koprusu (kanal: rc_softphone/ios_ses).
///    Gelen cagri CallKit ile cevaplandiginda ses oturumunu CallKit acar;
///    WebRTC'ye haber verilmezse cagri baglanir ama SES GELMEZ. Normalde bu
///    AppDelegate'te yapilir; AppDelegate'e dokunmamak icin callkit'in Dart'a
///    gonderdigi ACTION_CALL_TOGGLE_AUDIO_SESSION olayi Dart'tan buraya gelir.
///
/// 2) PushKit VoIP push (kanal: rc_softphone/ios_push). Uygulama kapali /
///    arka plandayken santral -> APNs VoIP push -> burada CallKit ekrani
///    HEMEN acilir (Apple kurali: her VoIP push'ta CallKit'e cagri bildirilmeli,
///    yoksa iOS uygulamayi oldurur ve push'u keser). Dart tarafi (SipService)
///    ardindan santrale register olup "hazirim" der; santral cagriyi o zaman
///    gonderir ve Dart onu bu CallKit cagrisina baglar.
///
/// PKPushRegistry plugin kaydinda (GeneratedPluginRegistrant, uygulama
/// acilisinda) kurulur; boylece AppDelegate'e hic kod yazilmaz ve softphone
/// kapaliyken (paket pubspec'te yokken) PushKit uygulamaya hic girmez.
public class RcSoftphonePlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate {
  private static var ortak: RcSoftphonePlugin?

  private var sesAcik = false
  private var pushKanal: FlutterMethodChannel?
  private var registry: PKPushRegistry?

  /// Son VoIP push ile acilan cagri (Dart baglanana kadar bekler).
  private var bekleyenPush: [String: Any]?
  private var bekleyenPushZamani: Date?

  /// Dart'in push olmadan (santral push'u atlayinca) kendi actigi CallKit
  /// cagrisi. Gec gelen push ikinci bir ekran acmasin diye ayni UUID ile
  /// bildirilir (CallKit "zaten var" der, yeni ekran acilmaz).
  private var dartCagriId: String?
  private var dartCagriZamani: Date?

  private static let tokenAnahtari = "rc_softphone_voip_token"

  public static func register(with registrar: FlutterPluginRegistrar) {
    // Birden fazla engine olusursa tek ornek + tek PushKit kaydi kullanilir.
    let ornek = ortak ?? RcSoftphonePlugin()
    if ortak == nil {
      ortak = ornek
      ornek.pushKitKur()
    }

    let sesKanal = FlutterMethodChannel(
      name: "rc_softphone/ios_ses", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ornek, channel: sesKanal)

    let pushKanal = FlutterMethodChannel(
      name: "rc_softphone/ios_push", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ornek, channel: pushKanal)
    ornek.pushKanal = pushKanal
  }

  private func pushKitKur() {
    let r = PKPushRegistry(queue: DispatchQueue.main)
    r.delegate = self
    r.desiredPushTypes = [.voIP]
    registry = r
  }

  // MARK: - Flutter kanallari

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let rtc = RTCAudioSession.sharedInstance()
    switch call.method {
    // ---- ses koprusu ----
    case "callkitIcinHazirla":
      // Gelen cagri: sesi CallKit acana kadar WebRTC beklesin.
      rtc.useManualAudio = true
      rtc.isAudioEnabled = false
      result(nil)

    case "callkitSesAktif":
      if !sesAcik {
        rtc.audioSessionDidActivate(AVAudioSession.sharedInstance())
        sesAcik = true
      }
      rtc.isAudioEnabled = true
      result(nil)

    case "callkitSesPasif":
      if sesAcik {
        rtc.audioSessionDidDeactivate(AVAudioSession.sharedInstance())
        sesAcik = false
      }
      rtc.isAudioEnabled = false
      result(nil)

    case "otomatikSeseDon":
      // CallKit cagrisi bitti: giden aramalar icin WebRTC'nin kendi yonetimine don.
      if sesAcik {
        rtc.audioSessionDidDeactivate(AVAudioSession.sharedInstance())
        sesAcik = false
      }
      rtc.useManualAudio = false
      rtc.isAudioEnabled = true
      result(nil)

    // ---- VoIP push ----
    case "voipToken":
      result(UserDefaults.standard.string(forKey: RcSoftphonePlugin.tokenAnahtari) ?? "")

    case "bundleId":
      result(Bundle.main.bundleIdentifier ?? "")

    case "bekleyenPush":
      // 60 sn'den eski push'lar gecersiz (santral zaten vazgecmistir).
      if let p = bekleyenPush, let z = bekleyenPushZamani, Date().timeIntervalSince(z) < 60 {
        var kopya = p
        kopya["saniyeOnce"] = Int(Date().timeIntervalSince(z))
        result(kopya)
      } else {
        bekleyenPush = nil
        result(nil)
      }

    case "pushTuketildi":
      bekleyenPush = nil
      bekleyenPushZamani = nil
      result(nil)

    case "dartCagrisi":
      let args = call.arguments as? [String: Any]
      dartCagriId = args?["id"] as? String
      dartCagriZamani = dartCagriId == nil ? nil : Date()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - PKPushRegistryDelegate

  public func pushRegistry(
    _ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set(token, forKey: RcSoftphonePlugin.tokenAnahtari)
    pushKanal?.invokeMethod("voipToken", arguments: token)
  }

  public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    guard type == .voIP else { return }
    UserDefaults.standard.removeObject(forKey: RcSoftphonePlugin.tokenAnahtari)
    pushKanal?.invokeMethod("voipToken", arguments: "")
  }

  public func pushRegistry(
    _ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType, completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let d = payload.dictionaryPayload
    var uuid = (d["uuid"] as? String) ?? ""
    if UUID(uuidString: uuid) == nil { uuid = UUID().uuidString }
    let numara = (d["numara"] as? String) ?? ""
    let arayan = (d["arayan"] as? String) ?? ""

    // Dart bu arayani push'tan once kendisi gosterdiyse ayni UUID'yi kullan:
    // CallKit "zaten var" der, ikinci ekran acilmaz (Apple kurali yine saglanir).
    if let id = dartCagriId, let z = dartCagriZamani, Date().timeIntervalSince(z) < 60 {
      uuid = id
    } else {
      bekleyenPush = ["uuid": uuid, "numara": numara, "arayan": arayan]
      bekleyenPushZamani = Date()
    }

    let veri = flutter_callkit_incoming.Data(args: [
      "id": uuid,
      "nameCaller": arayan.isEmpty ? (numara.isEmpty ? "Gelen Arama" : numara) : arayan,
      "handle": numara,
      "type": 0,
      "duration": 30000,
      "textAccept": "Cevapla",
      "textDecline": "Reddet",
      "extra": ["kaynak": "voip_push"],
      "ios": [
        "handleType": "generic",
        "supportsVideo": false,
        "maximumCallGroups": 1,
        "maximumCallsPerCallGroup": 1,
        "audioSessionMode": "default",
        "audioSessionActive": true,
        "supportsDTMF": true,
        "supportsHolding": true,
        "supportsGrouping": false,
        "supportsUngrouping": false,
      ],
    ])

    // Dart calisiyorsa hemen haber ver (on plandaysa register'i beklemesin).
    pushKanal?.invokeMethod(
      "pushCagrisi", arguments: ["uuid": uuid, "numara": numara, "arayan": arayan])

    guard let callkit = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      // Olmamali (callkit plugin'i bizden once kaydolur). Yine de completion.
      completion()
      return
    }
    callkit.showCallkitIncoming(veri, fromPushKit: true) {
      completion()
    }
  }
}
