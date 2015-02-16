import UIKit

var account = Account(user: User(ID: 1, username: "mattdipasquale", firstName: "Matt", lastName: "Di Pasquale"))

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.backgroundColor = UIColor.whiteColor()
        window.rootViewController = UINavigationController(rootViewController: ChatsViewController())
        window.makeKeyAndVisible()
        return true
    }
}
