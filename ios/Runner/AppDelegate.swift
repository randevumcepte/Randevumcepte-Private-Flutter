import UIKit
import Flutter
import PushKit
import FirebaseMessaging
import flutter_callkit_incoming

// Softphone (SIP/WebRTC + VoIP push) ana anahtari. Dart tarafindaki
// kSoftphoneEnabled ile ESLESMELI. App Store, VoIP/CallKit kullanmayan bir
// uygulamada 'voip' background mode'unu reddedebildigi (Guideline 2.5.4) ve
// ozellik henuz dogrulanmadigi icin bu surumde KAPALI. Kapaliyken VoIP push
// register edilmez. Acmak icin: bunu true yap + Info.plist UIBackgroundModes'a
// 'voip' ve 'audio'yu geri ekle + Dart kSoftphoneEnabled=true.
let kSoftphoneEnabled = false

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // VoIP push register
    self.registerVoIP()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func registerVoIP() {
    // Softphone kapaliyken VoIP push'a kayit olma (Info.plist'te 'voip'
    // background mode da yok; tutarli kalsin, Apple incelemesinde takilma).
    guard kSoftphoneEnabled else { return }
    voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry?.delegate = self
    voipRegistry?.desiredPushTypes = [.voIP]
  }

  // APNS token alindiginda Firebase'e ELLE ilet.
  // Info.plist'te FirebaseAppDelegateProxyEnabled=false oldugundan
  // GULAppDelegateSwizzler devre disi; bu yuzden firebase_messaging
  // eklentisi APNS token'i otomatik yakalayamiyor. Burada manuel set
  // etmezsek FIRMessaging.APNSToken nil kalir, getToken() bos doner
  // ("apns-token-not-set") ve uygulamada "Bildirimler su an calismiyor"
  // uyarisi cikar. Bu satir o zinciri tamamlar.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNS register hatasi: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Token güncellemesi (voip device token)
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    let tokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()

    // 1) Mevcut akış: Flutter tarafına MethodChannel ile gönder
    //    (Flutter saveVoipTokenToBackend ile backend'e platform=ios_voip yazar)
    if let controller = window?.rootViewController as? FlutterViewController {
      let ch = FlutterMethodChannel(name: "com.randevumcepte.voiptoken", binaryMessenger: controller.binaryMessenger)
      ch.invokeMethod("voipToken", arguments: tokenString)
    }

    // 2) flutter_callkit_incoming eklentisine de VoIP token'ı bildir
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(tokenString)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  // Gelen VoIP push (iOS 13+). KRİTİK: completion()'dan ÖNCE CallKit'e SENKRON
  // rapor verilmeli, aksi halde iOS uygulamanın VoIP push yetkisini iptal eder.
  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    guard type == .voIP else {
      completion()
      return
    }

    let p = payload.dictionaryPayload
    let id = (p["id"] as? String) ?? (p["call_id"] as? String) ?? UUID().uuidString
    let caller = (p["caller"] as? String) ?? (p["handle"] as? String) ?? "Bilinmeyen"
    let nameCaller = (p["nameCaller"] as? String) ?? caller

    let data = flutter_callkit_incoming.Data(id: id, nameCaller: nameCaller, handle: caller, type: 0)
    data.appName = "Randevumcepte"
    data.duration = 30000
    data.audioSessionMode = "default"
    data.audioSessionActive = true
    data.extra = ["type": "sip_incoming", "caller": caller]

    // CallKit'e senkron rapor ver (kilitli ekran dahil native gelen çağrı UI)
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
    completion()
  }
}
