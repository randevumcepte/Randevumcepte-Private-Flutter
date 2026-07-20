import UIKit
import Flutter
import FirebaseMessaging

// SIP/softphone (VoIP push + CallKit) tamamen kaldirildi. Yalnizca Firebase
// bildirim (APNS -> FCM) altyapisi korunuyor.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // APNS token alindiginda Firebase'e ELLE ilet.
  // Info.plist'te FirebaseAppDelegateProxyEnabled=false oldugundan
  // GULAppDelegateSwizzler devre disi; bu yuzden firebase_messaging
  // eklentisi APNS token'i otomatik yakalayamiyor. Burada manuel set
  // etmezsek FIRMessaging.APNSToken nil kalir, getToken() bos doner.
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
}
