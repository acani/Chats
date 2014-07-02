import AudioToolbox
import UIKit

let messageFontSize: CGFloat = 17
let toolBarMinHeight: CGFloat = 44
let textViewMaxHeight: (portrait: CGFloat, landscape: CGFloat) = (portrait: 272, landscape: 90)
let messageSoundOutgoing: SystemSoundID = createMessageSoundOutgoing()

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    let chat: Chat
    var tableView: UITableView!
    var toolBar: UIToolbar!
    var textView: UITextView!
    var sendButton: UIButton!
    var rotating = false

    override var inputAccessoryView: UIView! {
    get {
        if !toolBar {
            toolBar = UIToolbar(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))

            textView = UITextView(frame: CGRectZero)
            textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
            textView.delegate = self
            textView.font = UIFont.systemFontOfSize(messageFontSize)
            textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
            textView.layer.borderWidth = 0.5
            textView.layer.cornerRadius = 5
//        textView.placeholder = "Message"
            textView.scrollsToTop = false
            textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
            toolBar.addSubview(textView)

            sendButton = UIButton.buttonWithType(.System) as UIButton
            sendButton.enabled = false
            sendButton.titleLabel.font = UIFont.boldSystemFontOfSize(17)
            sendButton.setTitle("Send", forState: .Normal)
            sendButton.setTitleColor(UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1), forState: .Disabled)
            sendButton.setTitleColor(UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1), forState: .Normal)
            sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            sendButton.addTarget(self, action: "sendAction", forControlEvents: UIControlEvents.TouchUpInside)
            toolBar.addSubview(sendButton)

            // Auto Layout allows `sendButton` to change width, e.g., for localization.
            textView.setTranslatesAutoresizingMaskIntoConstraints(false)
            sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: toolBar, attribute: .Left, multiplier: 1, constant: 8))
            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: toolBar, attribute: .Top, multiplier: 1, constant: 7.5))
            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: sendButton, attribute: .Left, multiplier: 1, constant: -2))
            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -8))
            toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Right, relatedBy: .Equal, toItem: toolBar, attribute: .Right, multiplier: 1, constant: 0))
            toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -4.5))
        }
        return toolBar
    }
    }

    init(chat: Chat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        title = chat.user.name
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        chat.loadedMessages += [
            Message(incoming: true, text: "Hey, would you like to spend some time together tonight and work on Acani?", sentDate: NSDate(timeIntervalSinceNow: 33)),
            Message(incoming: false, text: "Sure, I'd love to. How's 6 PM?", sentDate: NSDate(timeIntervalSinceNow: 19)),
            Message(incoming: true, text: "6 sounds good :-)", sentDate: NSDate.date())
        ]

        let whiteColor = UIColor.whiteColor()
        view.backgroundColor = whiteColor // fixes push animation

        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = whiteColor
        let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolBarMinHeight, right: 0)
        tableView.contentInset = edgeInsets
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .Interactive
        tableView.registerClass(MessageCell.self, forCellReuseIdentifier: NSStringFromClass(MessageCell))
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .None
        view.addSubview(tableView)

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
    }

//    // #iOS7.1
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)

        if UIInterfaceOrientationIsLandscape(toInterfaceOrientation) {
            if toolBar.frame.height > textViewMaxHeight.landscape {
                toolBar.frame.size.height = textViewMaxHeight.landscape+8*2-0.5
            }
        } else { // portrait
            updateTextViewHeight()
        }
    }
//    // #iOS8
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator!) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//    }


    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return chat.loadedMessages.count
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(MessageCell), forIndexPath: indexPath) as MessageCell
        cell.configureWithMessage(chat.loadedMessages[indexPath.row])
        return cell
    }

    // #iOS7 - not needed for #iOS8
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = chat.loadedMessages[indexPath.row]
        let height = (message.text as NSString).boundingRectWithSize(CGSize(width: 218, height: CGFLOAT_MAX), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(messageFontSize)], context: nil).height
        #if arch(x86_64) || arch(arm64)
            return ceil(height) + 24
        #else
            return ceilf(height) + 24
        #endif
    }

    func textViewDidChange(textView: UITextView!) {
        updateTextViewHeight()
        sendButton.enabled = textView.hasText()
    }

    func keyboardWillShow(notification: NSNotification) {
        println("show")
        let userInfo = notification.userInfo
        let frameNew = userInfo[UIKeyboardFrameEndUserInfoKey].CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        let insetOld = tableView.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = tableView.contentSize.height - (tableView.frame.height-insetOld.top-insetOld.bottom)

        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey].doubleValue
        let animations: (() -> Void) = {
            println(self.tableView.tracking)
            println(self.tableView.dragging)
            println(self.tableView.decelerating)
            if !(self.tableView.tracking || self.tableView.decelerating) {
                // Scroll content with keyboard
                if overflow > 0 {                   // scrollable before
                    self.tableView.contentOffset.y = self.tableView.contentOffset.y+insetChange
                } else if overflow > -insetChange { // scrollable after
                    self.tableView.contentOffset.y = self.tableView.contentOffset.y+insetChange+overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(UInt(userInfo[UIKeyboardAnimationCurveUserInfoKey].integerValue << 16)) // http://stackoverflow.com/a/18873820/242933
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    func keyboardDidShow(notification: NSNotification) {
        let userInfo = notification.userInfo
        let frameNew = userInfo[UIKeyboardFrameEndUserInfoKey].CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height

        // Inset `tableView` with keyboard
        let contentOffsetY = tableView.contentOffset.y
        tableView.contentInset.bottom = insetNewBottom
        tableView.scrollIndicatorInsets.bottom = insetNewBottom
        tableView.contentOffset.y = contentOffsetY
    }

    func updateTextViewHeight() {
        let oldHeight = textView.frame.height
        let maxHeight = UIInterfaceOrientationIsPortrait(interfaceOrientation) ? textViewMaxHeight.portrait : textViewMaxHeight.landscape
        var newHeight = min(textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFLOAT_MAX)).height, maxHeight)
        #if arch(x86_64) || arch(arm64)
            newHeight = ceil(newHeight)
        #else
            newHeight = ceilf(newHeight)
        #endif
        if newHeight != oldHeight {
            toolBar.frame.size.height = newHeight+8*2-0.5
        }
    }

    func sendAction() {
        chat.loadedMessages += Message(incoming: false, text: textView.text, sentDate: NSDate.date())
        textView.text = nil
        updateTextViewHeight()
        sendButton.enabled = false
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: tableView.numberOfRowsInSection(0), inSection: 0)], withRowAnimation: .Automatic)
        tableViewScrollToBottomAnimated(true)
        AudioServicesPlaySystemSound(messageSoundOutgoing)
    }

    func tableViewScrollToBottomAnimated(animated: Bool) {
        let numberOfRows = tableView.numberOfRowsInSection(0)
        if numberOfRows > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfRows-1, inSection: 0), atScrollPosition: .Bottom, animated: animated)
        }
    }
}

func createMessageSoundOutgoing() -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "MessageOutgoing", "aiff", nil)
    AudioServicesCreateSystemSoundID(soundURL, &soundID)
    CFRelease(soundURL)
    return soundID
}
