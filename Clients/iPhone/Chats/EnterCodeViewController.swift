import UIKit

class EnterCodeViewController: UIViewController, CodeInputViewDelegate, UIAlertViewDelegate {
    var signingUp = false

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()

        let noticeLabel = UILabel(frame: CGRect(x: 20, y: 64, width: view.frame.width-40, height: 178))
        if signingUp {
            noticeLabel.text = "Sign Up\n\nNo user exists with the number above.\n\nTo sign up, enter the code we just sent you."
        } else {
            noticeLabel.text = "Log In\n\nA user exists with the number above.\n\nTo log in, enter the code we just sent you."
        }
        noticeLabel.textAlignment = .Center
        noticeLabel.numberOfLines = 0
        view.addSubview(noticeLabel)

        let codeInputView = CodeInputView(frame: CGRect(x: (view.frame.width-215)/2, y: 242, width: 215, height: 60))
        codeInputView.delegate = self
        codeInputView.tag = 17
        view.addSubview(codeInputView)
        codeInputView.becomeFirstResponder()
    }

    // MARK: - CodeInputViewDelegate

    func codeInputView(codeInputView: CodeInputView, didFinishWithCode code: String) {
        let activityOverlayView = ActivityOverlayView.sharedView()
        activityOverlayView.showWithTitle(signingUp ? "Verifying" : "Loging In")

        // Create code with phone number
        if signingUp {
            var request = api.formRequest("POST", "/keys", ["phone": title!, "code": code])
            let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                if response != nil {
                    let statusCode = (response as! NSHTTPURLResponse).statusCode
                    let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as! Dictionary<String, String>?

                    dispatch_async(dispatch_get_main_queue(), {
                        activityOverlayView.dismissAnimated(true)

                        if statusCode == 201 {
                            let newProfileTableViewController = NewProfileTableViewController(phone: self.title!, key: dictionary!["key"]!)
                            self.navigationController?.setViewControllers([newProfileTableViewController], animated: true)
                        } else {
                            UIAlertView(dictionary: dictionary, error: error, delegate: self).show()
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
        } else {
            var request = api.formRequest("POST", "/sessions", ["phone": title!, "code": code])
            let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                if response != nil {
                    let statusCode = (response as! NSHTTPURLResponse).statusCode
                    let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as! Dictionary<String, String>?

                    dispatch_async(dispatch_get_main_queue(), {
                        activityOverlayView.dismissAnimated(true)

                        if statusCode == 201 {
                            let accessToken = dictionary!["access_token"] as String!
                            account.setUserWithAccessToken(accessToken, firstName: "", lastName: "")
                            account.accessToken = accessToken
                        } else {
                            UIAlertView(dictionary: dictionary, error: error, delegate: self).show()
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
        }
    }

    // MARK: - UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        (view.viewWithTag(17) as! CodeInputView).clear()
    }
}
