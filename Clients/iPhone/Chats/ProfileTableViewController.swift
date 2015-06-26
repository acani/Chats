import MobileCoreServices
import UIKit

class ProfileTableViewController: UITableViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var saveChanges = false
    let user: User

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil) // iOS bug: should be: super.init(style: .Plain)
        title = "Profile"

        if user === account.user {
            navigationItem.rightBarButtonItem = editButtonItem()
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "chatAction")
        }
    }

    required init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(TextFieldTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextFieldTableViewCell))
        tableView.separatorInset.left = 12 + 60 + 12 + 22
        tableView.tableFooterView = UIView(frame: CGRectZero) // hides trailing separators

        addPictureAndName()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if editing {
            saveChanges = true

            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelEditingAction")
            tableView.setEditing(false, animated: false)
            tableView.tableHeaderView = nil
            tableView.viewWithTag(3)?.removeFromSuperview()

            let pictureButton = UIButton.buttonWithType(.System) as! UIButton
            pictureButton.addTarget(self, action: "editPictureAction", forControlEvents: .TouchUpInside)
            pictureButton.adjustsImageWhenHighlighted = false
            pictureButton.clipsToBounds = true
            pictureButton.frame = CGRect(x: 15, y: 12, width: 60, height: 60)
            pictureButton.layer.borderColor = UIColor(white: 200/255, alpha: 1).CGColor
            pictureButton.layer.borderWidth = 1
            pictureButton.layer.cornerRadius = 60/2
            if let pictureName = user.pictureName() {
                pictureButton.setBackgroundImage(UIImage(named: pictureName), forState: .Normal)
            } else {
                pictureButton.setTitle("add photo", forState: .Normal)
            }
            pictureButton.tag = 4
            pictureButton.titleLabel?.font = UIFont.systemFontOfSize(13)
            pictureButton.titleLabel?.numberOfLines = 0
            pictureButton.titleLabel?.textAlignment = .Center
            tableView.addSubview(pictureButton)

            if user.pictureName() != nil {
                addEditPictureButton()
            }
        } else {
            let firstNameTextField = tableView.textFieldForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
            let lastNameTextField = tableView.textFieldForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!

            if saveChanges {
                if firstNameTextField.hasText() {
                    user.firstName = firstNameTextField.text
                } else {
                    let alertView = UIAlertView(title: "First Name Required", message: nil, delegate: nil, cancelButtonTitle: "OK")
                    alertView.show()
                    setEditing(true, animated: false)
                    return
                }

                if lastNameTextField.hasText() {
                    user.lastName = lastNameTextField.text
                } else {
                    let alertView = UIAlertView(title: "Last Name Required", message: nil, delegate: nil, cancelButtonTitle: "OK")
                    alertView.show()
                    setEditing(true, animated: false)
                    return
                }
            }

            navigationItem.leftBarButtonItem = nil

            tableView.viewWithTag(4)!.removeFromSuperview()
            tableView.viewWithTag(5)?.removeFromSuperview()

            addPictureAndName()
        }
        tableView.reloadData()
    }

    func addEditPictureButton() {
        let editPictureButton = UIButton.buttonWithType(.System) as! UIButton
        editPictureButton.frame = CGRect(x: 28, y: 12+60-0.5, width: 34, height: 21)
        editPictureButton.setTitle("edit", forState: .Normal)
        editPictureButton.tag = 5
        editPictureButton.titleLabel?.font = UIFont.systemFontOfSize(13)
        editPictureButton.userInteractionEnabled = false
        tableView.addSubview(editPictureButton)
    }

    func addPictureAndName() {
        let userPictureImageView = UserPictureImageView(frame: CGRect(x: 15, y: 12, width: 60, height: 60))
        userPictureImageView.configureWithUser(user)
        userPictureImageView.tag = 3
        tableView.addSubview(userPictureImageView)

        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 12+60+12))
        tableHeaderView.autoresizingMask = .FlexibleWidth
        tableHeaderView.userInteractionEnabled = false
        tableView.tableHeaderView = tableHeaderView

        let nameLabel = UILabel(frame: CGRect(x: 91, y: 31, width: tableHeaderView.frame.width-91, height: 21))
        nameLabel.autoresizingMask = .FlexibleWidth
        nameLabel.font = UIFont.boldSystemFontOfSize(17)
        nameLabel.text = user.name
        tableHeaderView.addSubview(nameLabel)
    }

    // MARK: Actions

    func chatAction() {
        let chat = Chat(user: user, lastMessageText: "", lastMessageSentDate: NSDate()) // TODO: Pass nil for text & date
        navigationController?.pushViewController(ChatViewController(chat: chat), animated: true)
    }

    func editPictureAction() {
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Take Photo", "Choose Photo")
        if user.pictureName() != nil {
            // actionSheet.addButtonWithTitle("Edit Photo")
            actionSheet.addButtonWithTitle("Delete Photo")
            actionSheet.destructiveButtonIndex = 3
        }
        actionSheet.showInView(tableView.window)
    }

    func cancelEditingAction() {
        saveChanges = false
        setEditing(false, animated: true)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editing ? 2 : 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(TextFieldTableViewCell), forIndexPath: indexPath) as! TextFieldTableViewCell
        cell.textFieldLeftLayoutConstraint.constant = tableView.separatorInset.left + 1
        let textField = cell.textField
        textField.clearButtonMode = .WhileEditing

        var placeholder: String!
        if indexPath.row == 0 {
            placeholder = "First Name"
            textField.text = user.firstName
        } else {
            placeholder = "Last Name"
            textField.text = user.lastName
        }
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSForegroundColorAttributeName: UIColor(white: 127/255, alpha: 1)])
        return cell
    }

    // MARK: UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 1, 2: // Camera, Photo
            let sourceType: UIImagePickerControllerSourceType = buttonIndex == 1 ? .Camera : .PhotoLibrary
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                let imagePickerController = UIImagePickerController()
                imagePickerController.allowsEditing = true
                imagePickerController.delegate = self
                imagePickerController.sourceType = sourceType
                presentViewController(imagePickerController, animated: true, completion: nil)
            } else {
                let sourceString = sourceType == .Camera ? "Camera" : "Photo Library"
                let alertView = UIAlertView(title: "\(sourceString) Unavailable", message: nil, delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
            }
        case 3: // Delete
            let pictureButton = tableView.viewWithTag(4) as! UIButton
            pictureButton.setBackgroundImage(nil, forState: .Normal)
            pictureButton.setTitle("add photo", forState: .Normal)
            tableView.viewWithTag(5)?.removeFromSuperview()
        default: // Cancel
            break
        }
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! CFString!
        if UTTypeConformsTo(mediaType, kUTTypeImage) != 0 {
            var image = info[UIImagePickerControllerEditedImage] as! UIImage!
            if image == nil {
                image = info[UIImagePickerControllerOriginalImage] as! UIImage!
            }

            // Resize image to 2048px max width
            image = image.resizedImage(2048)
            println(image.size)

            // TEST: Save image to documents directory.
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            var uuid = NSUUID().UUIDString // E621E1F8-C36C-495A-93FC-0C247A3E6E5F
            let range = Range<String.Index>(start: uuid.startIndex, end: advance(uuid.endIndex, -12))
            uuid = uuid.stringByReplacingOccurrencesOfString("-", withString: "", options: .LiteralSearch, range: range).lowercaseString
            let filePath = paths[0].stringByAppendingPathComponent("\(uuid).jpg")
            let imageData = UIImageJPEGRepresentation(image, 0.9)
//            imageData.writeToFile(filePath, atomically: true)
            println(filePath)

            // Upload image to server

            let pictureButton = tableView.viewWithTag(4) as! UIButton
            pictureButton.setBackgroundImage(image, forState: .Normal)
            if pictureButton.titleForState(.Normal) != nil {
                pictureButton.setTitle(nil, forState: .Normal)
                addEditPictureButton()
            }

            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

extension UIImage {
    func resizedImage(max: CGFloat) -> UIImage {
        let width = size.width
        let height = size.height

        let scale = width > height ? max/width : max/height
        if scale >= 1 {
            return self
        } else {
            let newWidth = width * scale
            let newHeight = height * scale

            UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 0)
            drawInRect(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resizedImage
        }
    }
}
