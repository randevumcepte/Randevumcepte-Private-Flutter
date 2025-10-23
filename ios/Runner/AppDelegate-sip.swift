import Flutter
import UIKit
import CTSoftPhone
import PushKit
import CallKit
import Firebase
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CTSoftPhoneDelegate, PKPushRegistryDelegate, CXProviderDelegate {
    
    var pjsipInstance: CTSoftPhone?
    
    // PushKit ve CallKit için değişkenler
    var voipRegistry: PKPushRegistry!
    var callKitProvider: CXProvider!
    var callKitCallController = CXCallController()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        // PushKit setup
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        
        // CallKit setup
        let configuration = CXProviderConfiguration(localizedName: "YourAppName")
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.phoneNumber]
        // İstersen icon ekle, yoksa kaldırabilirsin:
        // configuration.iconTemplateImageData = UIImage(named: "AppIcon")?.pngData()
        callKitProvider = CXProvider(configuration: configuration)
        callKitProvider.setDelegate(self, queue: nil)
        
        // FlutterMethodChannel ve CTSoftPhone setup'un orijinal haliyle devam ediyor
        let controller = window.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "ctsoftphone", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "initialize":
                let config = CTSoftPhoneConfig(port: 5060, transport: .TCP)
                self.pjsipInstance = CTSoftPhone.sharedInstance(with: self, config: config)
                CTSoftPhone.setDebugLevel(.debug)
                result(nil)
                
            case "register":
                if let args = call.arguments as? [String: String],
                   let number = args["number"],
                   let host = args["host"],
                   let password = args["password"] {
                    self.pjsipInstance?.register(withNumber: number, withHost: host, withCredentials: password)
                    result(nil)
                }
                
            case "destroy":
                self.pjsipInstance?.destroy()
                result(nil)
                
            case "hangup":
                self.pjsipInstance?.hangup()
                result(nil)
                
            case "mute":
                self.pjsipInstance?.mute()
                result(nil)
                
            case "unmute":
                self.pjsipInstance?.unmute()
                result(nil)
                
            case "speakerOn":
                self.pjsipInstance?.speakeron()
                result(nil)
                
            case "speakerOff":
                self.pjsipInstance?.speakeroff()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - CTSoftPhoneDelegate
    
    func onRegistrationState(_ state: CTSoftPhoneRegistrationState) {
        print("SIP Registration state: \(state.rawValue)")
    }
    
    func onCallState(_ state: CTSoftPhoneCallState) {
        print("Call state: \(state.rawValue)")
    }
    
    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let tokenData = pushCredentials.token
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP Push Token: \(tokenString)")
        
        // TODO: Token'u backend'e gönder (sunucunun push için kullanması gerekiyor)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("VoIP Push Bildirimi Geldi: \(payload.dictionaryPayload)")
        
        // Örnek arayan numara, gerçek numarayı payload’dan çekmelisin
        let callerNumber = "+905316237563"
        reportIncomingCall(uuid: UUID(), handle: callerNumber)
        
        // Burada CTSoftPhone ile gelen çağrıyı kabul işlemi yapabilirsin (opsiyonel)
    }
    
    // MARK: - CallKit
    
    func reportIncomingCall(uuid: UUID, handle: String) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = false
        
        callKitProvider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("CallKit incoming call error: \(error.localizedDescription)")
            } else {
                print("CallKit incoming call bildirildi")
                // Burada çağrıyı CTSoftPhone ile bağla istersen
            }
        }
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("CallKit provider resetlendi")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("Arama cevaplandı")
        // CTSoftPhone üzerinden çağrıyı cevapla
        // Örnek: pjsipInstance?.answerCall()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("Arama sonlandırıldı")
        pjsipInstance?.hangup()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("Arama başlatılıyor")
        // CTSoftPhone ile çağrıyı başlat
        action.fulfill()
    }
}

/*

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}   
 */
