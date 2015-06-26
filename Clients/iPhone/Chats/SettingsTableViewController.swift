import UIKit

class SettingsTableViewController: UITableViewController, UIActionSheetDelegate {
    enum Section : Int {
        case Phone
        case LogOut
        case DeleteAccount
    }

    convenience init() {
        self.init(style: .Grouped)
        title = "Settings"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Set style & identifier based on section
        let section = Section(rawValue: indexPath.section)!
        var style: UITableViewCellStyle = .Default
        var identifier = "Default"
        if section == .Phone {
            style = .Value1
            identifier = "Value1"
        }

        // Dequeue or create cell with style & identifier
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! UITableViewCell!
        if cell == nil {
            cell = UITableViewCell(style: style, reuseIdentifier: identifier)
            cell.textLabel?.font = UIFont.systemFontOfSize(18)
        }

        // Customize cell
        cell.textLabel?.textAlignment = .Center
        switch section {
        case .Phone:
            cell.accessoryType = .DisclosureIndicator
            cell.detailTextLabel?.text = account.phone
            cell.textLabel?.text = "Phone Number"
            cell.textLabel?.textAlignment = .Left
        case .LogOut:
            cell.textLabel?.text = "Log Out"
            cell.textLabel?.textColor = UIColor(red: 0/255, green: 88/255, blue: 249/255, alpha: 1)
        default:
            cell.textLabel?.text = "Delete Account"
            cell.textLabel?.textColor = UIColor(red: 252/255, green: 53/255, blue: 56/255, alpha: 1)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .Phone:
            navigationController?.pushViewController(EditPhoneTableViewController(), animated: true)
        case .LogOut:
            if account.accessToken == "guest_access_token" {
                account.logOutGuest()
            } else {
                account.logOut()
            }
        default:
            let actionSheet = UIActionSheet(title: "Deleting your account will permanently delete your phone number, picture, and first & last name.\n\nAre you sure you want to delete your account?", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Delete Accout")
            actionSheet.showInView(tableView.window)
        }
    }

    // MARK: - UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            if account.accessToken == "guest_access_token" {
                account.logOutGuest()
            } else {
                account.deleteAccount()
            }
        }
    }
}
