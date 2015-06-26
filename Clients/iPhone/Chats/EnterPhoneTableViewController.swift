import UIKit

class EnterPhoneTableViewController: UITableViewController {
    convenience init() {
        self.init(style: .Grouped)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Verify", style: .Done, target: self, action: "verifyAction")
        title = "Enter Phone Number"
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(TextFieldTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextFieldTableViewCell))

        let tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44+32))
        tableFooterView.autoresizingMask = .FlexibleWidth
        tableView.tableFooterView = tableFooterView

        let continueAsGuestButton = UIButton.buttonWithType(.System) as! UIButton
        continueAsGuestButton.addTarget(self, action: "continueAsGuestAction", forControlEvents: .TouchUpInside)
        continueAsGuestButton.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleTopMargin
        continueAsGuestButton.frame = CGRect(x: (view.frame.width-184)/2, y: 32, width: 184, height: 44)
        continueAsGuestButton.setTitle("Continue as Guest", forState: .Normal)
        continueAsGuestButton.titleLabel?.font = UIFont.systemFontOfSize(17)
        tableFooterView.addSubview(continueAsGuestButton)
    }

    // MARK: - UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(TextFieldTableViewCell), forIndexPath: indexPath) as! TextFieldTableViewCell
        let textField = cell.textField
        textField.clearButtonMode = .WhileEditing
        textField.keyboardType = .NumberPad
        textField.placeholder = "Phone Number"
        textField.becomeFirstResponder()
        return cell
    }

    // MARK: - Actions

    func verifyAction() {
        // Validate phone
        var phone = tableView.textFieldForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!.text!
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if phone.hasPrefix("1") { phone.removeAtIndex(phone.startIndex) }
        if let alertView = phoneInvalidAlertView(phone) {
            alertView.show()
            return
        }

        // Create code with phone number
        let activityOverlayView = ActivityOverlayView.sharedView()
        activityOverlayView.showWithTitle("Connecting")

        var request = api.formRequest("POST", "/codes", ["phone": phone])
        let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if response != nil {
                let statusCode = (response as! NSHTTPURLResponse).statusCode

                dispatch_async(dispatch_get_main_queue(), {
                    activityOverlayView.dismissAnimated(true)

                    switch statusCode {
                    case 201, 200: // sign-up, log-in
                        let enterCodeViewController = EnterCodeViewController(nibName: nil, bundle: nil)
                        enterCodeViewController.title = phone
                        enterCodeViewController.signingUp = statusCode == 201 ? true : false
                        self.navigationController?.pushViewController(enterCodeViewController, animated: true)
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
    }

    func continueAsGuestAction() {
        (UIApplication.sharedApplication().delegate as! AppDelegate).continueAsGuest()
    }

    // MARK: - Helpers

    func phoneInvalidAlertView(phone: String) -> UIAlertView? {
        let digitSet = NSCharacterSet.decimalDigitCharacterSet()
        let phoneSet = NSCharacterSet(charactersInString: phone)
        if !(count(phone) == 10 && digitSet.isSupersetOfSet(phoneSet)) {
            return UIAlertView(title: "", message: "Phone number must be 10 digits.", delegate: nil, cancelButtonTitle: "OK")
        } else {
            return nil
        }
    }
}
