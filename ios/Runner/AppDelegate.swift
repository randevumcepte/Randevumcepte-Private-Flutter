import UIKit
import Flutter
import PushKit

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
    voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry?.delegate = self
    voipRegistry?.desiredPushTypes = [.voIP]
  }

  // Token güncellemesi (voip device token)
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    let tokenData = pushCredentials.token
    let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()

    // 1) Flutter tarafına MethodChannel ile gönder
    if let controller = window?.rootViewController as? FlutterViewController {
      let ch = FlutterMethodChannel(name: "com.randevumcepte.voiptoken", binaryMessenger: controller.binaryMessenger)
      ch.invokeMethod("voipToken", arguments: tokenString)
    }

    // 2) (opsiyonel) veya doğrudan backend'e gönder
    //sendTokenToMyServer(token: tokenString)
  }

  // Gelen VoIP push (iOS 13+)
  func pushRegistry(_ regæistry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    // gelen push payload - CallKit/uygulama açma vb. buradan yapılabilir
    // Forward to Flutter if needed
    completion()
  }
}
