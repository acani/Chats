import UIKit

class Account: NSObject {
    var phone: String!
    dynamic var accessToken: String! {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(AccountAccessTokenKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: AccountAccessTokenKey)
        }
    }
    var user: User!
    dynamic var users = [User]()
    var email: String?
    var chats = [Chat]()

    func logOut() -> NSURLSessionDataTask {
        let activityOverlayView = ActivityOverlayView.sharedView()
        activityOverlayView.showWithTitle("Deleting")

        let request = NSMutableURLRequest(URL: api.URLWithPath("/sessions"))
        request.HTTPMethod = "DELETE"
        request.setValue("Bearer "+accessToken, forHTTPHeaderField: "Authorization")
        let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if response != nil {
                let statusCode = (response as! NSHTTPURLResponse).statusCode

                dispatch_async(dispatch_get_main_queue(), {
                    activityOverlayView.dismissAnimated(true)

                    if statusCode == 200 {
                        self.reset()
                    } else {
                        let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as! Dictionary<String, String>?
                        UIAlertView(dictionary: dictionary, error: error, delegate: nil).show()
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    activityOverlayView.dismissAnimated(true)
                    UIAlertView(dictionary: nil, error: error, delegate: nil).show()
                })
            }
        })
        dataTask.resume()
        return dataTask
    }

    func deleteAccount() -> NSURLSessionDataTask {
        let activityOverlayView = ActivityOverlayView.sharedView()
        activityOverlayView.showWithTitle("Deleting")

        let request = NSMutableURLRequest(URL: api.URLWithPath("/me"))
        request.HTTPMethod = "DELETE"
        request.setValue("Bearer "+accessToken, forHTTPHeaderField: "Authorization")
        let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if response != nil {
                let statusCode = (response as! NSHTTPURLResponse).statusCode

                dispatch_async(dispatch_get_main_queue(), {
                    activityOverlayView.dismissAnimated(true)

                    switch statusCode {
                    case 200:
                        self.reset()
                    default:
                        let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as! Dictionary<String, String>?
                        UIAlertView(dictionary: dictionary, error: error, delegate: nil).show()
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    activityOverlayView.dismissAnimated(true)
                    UIAlertView(dictionary: nil, error: error, delegate: nil).show()

                })
            }
        })
        dataTask.resume()
        return dataTask
    }

    func setUserWithAccessToken(accessToken: String, firstName: String, lastName: String) {
        let userIDString = accessToken.substringToIndex(advance(accessToken.endIndex, -33))
        let userID = UInt(userIDString.toInt()!)
        user = User(ID: userID, username: "", firstName: firstName, lastName: lastName)
    }

    private func reset() {
        phone = nil
        accessToken = nil
        user = nil
        users = []
        chats = []
    }

    func logOutGuest() {
        reset()
    }
}

private let AccountAccessTokenKey = "AccountAccessTokenKey"
