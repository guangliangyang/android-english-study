import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure for background audio playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle YouTube URLs
        if url.scheme == "https" && (url.host == "www.youtube.com" || url.host == "youtu.be") {
            handleYouTubeURL(url)
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
    
    private func handleYouTubeURL(_ url: URL) {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.englishstudy.app/youtube",
            binaryMessenger: controller.binaryMessenger
        )
        
        let videoId = extractVideoId(from: url)
        if let videoId = videoId {
            channel.invokeMethod("receiveVideoId", arguments: videoId)
        }
    }
    
    private func extractVideoId(from url: URL) -> String? {
        if url.host == "youtu.be" {
            return url.pathComponents.last
        } else if url.host == "www.youtube.com" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            return components?.queryItems?.first(where: { $0.name == "v" })?.value
        }
        return nil
    }
}