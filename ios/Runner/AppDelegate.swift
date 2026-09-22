import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

// SIP/softphone (VoIP push + CallKit) tamamen kaldirildi. Yalnizca Firebase
// bildirim (APNS -> FCM) altyapisi korunuyor.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Proxy (swizzling) kapali oldugundan Firebase'i native tarafta erken
    // configure etmezsek, didRegisterForRemote... icinde apnsToken atadigimiz
    // anda FirebaseApp henuz hazir olmaz ve APNS->FCM baglanmaz. eczella'da
    // bu satir var ve iOS bildirimleri bu sayede calisiyor.
    FirebaseApp.configure()
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
