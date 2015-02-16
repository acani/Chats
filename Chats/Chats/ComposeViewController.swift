import UIKit

class ComposeViewController: UIViewController, UITableViewDataSource, UITextViewDelegate {
    var searchResults: [User] = []
    var searchResultsTableView = UITableView(frame: CGRectZero, style: .Plain)
    var toTextView = UITextView(frame: CGRectZero)

    convenience override init() {
        self.init(nibName: nil, bundle: nil)
        automaticallyAdjustsScrollViewInsets = false
        title = "New Message"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()

        toTextView.backgroundColor = UIColor(white: 248/255.0, alpha: 1)
        let attributedString = NSMutableAttributedString(string: "To: ")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1), range: NSMakeRange(0, 3))
        toTextView.attributedText = attributedString
        toTextView.font = UIFont.systemFontOfSize(15)
        toTextView.contentInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 0)
        view.addSubview(toTextView)

        searchResultsTableView.frame = view.bounds
        searchResultsTableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        searchResultsTableView.dataSource = self
        searchResultsTableView.hidden = true
        searchResultsTableView.keyboardDismissMode = .OnDrag
        searchResultsTableView.scrollsToTop = false
        searchResultsTableView.registerClass(UserCell.self, forCellReuseIdentifier: NSStringFromClass(UserCell))
        view.addSubview(searchResultsTableView)

        toTextView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0))
        toTextView.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 44))
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(UserCell), forIndexPath: indexPath) as UserCell
        let user = searchResults[indexPath.row]
        cell.pictureImageView.image = UIImage(named: user.pictureName())
        cell.nameLabel.text = user.name
        cell.usernameLabel.text = "$" + user.username
        return cell
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(textView: UITextField) {
        println(textView.text)
    }

    // MARK: - Actions

    func cancelAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
