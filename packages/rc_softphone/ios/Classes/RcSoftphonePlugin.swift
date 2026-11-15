import AVFoundation
import Flutter
import UIKit
import WebRTC

/// CallKit <-> WebRTC ses oturumu koprusu.
///
/// iOS'ta gelen cagri CallKit ile cevaplandiginda ses oturumunu CallKit acar.
/// WebRTC bunu kendiliginden bilmez; haber verilmezse cagri baglanir ama SES
/// GELMEZ. Normalde bu AppDelegate'te (CallkitIncomingAppDelegate) yapilir;
/// biz AppDelegate'e dokunmamak icin flutter_callkit_incoming'in Dart'a
/// gonderdigi ACTION_CALL_TOGGLE_AUDIO_SESSION olayini Dart'ta yakalayip
/// buraya iletiyoruz.
///
/// Giden aramalar CallKit kullanmaz; WebRTC ses oturumunu kendisi yonetir
/// (otomatik mod). Manuel mod yalnizca CallKit cagrisi suresince aciktir.
public class RcSoftphonePlugin: NSObject, FlutterPlugin {
  private var sesAcik = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let kanal = FlutterMethodChannel(
      name: "rc_softphone/ios_ses", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(RcSoftphonePlugin(), channel: kanal)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let rtc = RTCAudioSession.sharedInstance()
    switch call.method {
    case "callkitIcinHazirla":
      // Gelen cagri gosterilmeden once: sesi CallKit acana kadar WebRTC beklesin.
      rtc.useManualAudio = true
      rtc.isAudioEnabled = false
      result(nil)

    case "callkitSesAktif":
      rtc.audioSessionDidActivate(AVAudioSession.sharedInstance())
      rtc.isAudioEnabled = true
      sesAcik = true
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

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
