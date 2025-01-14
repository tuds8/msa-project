import UIKit
import Flutter
import GoogleMaps
import flutter_dotenv

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Load environment variables
        dotenv.load(fileName: ".env")

        // Provide the Google Maps API key from the .env file
        if let googleMapsAPIKey = dotenv.env["GOOGLE_MAPS_API_KEY"] {
            GMSServices.provideAPIKey(googleMapsAPIKey)
        } else {
            print("Error: GOOGLE_MAPS_API_KEY not found in .env file")
        }

        // Register plugins
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
