import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - properties

    var window: UIWindow?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        window.rootViewController = ViewController()

        window.makeKeyAndVisible()

        return true
    }
}
