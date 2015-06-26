import UIKit

class TextFieldTableViewCell: UITableViewCell {
    var textFieldLeftLayoutConstraint: NSLayoutConstraint!
    let textField = UITextField(frame: CGRectZero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None

        // Add `textField`
        contentView.addSubview(textField)

        // Add `textField` constraints
        textField.setTranslatesAutoresizingMaskIntoConstraints(false)
        textFieldLeftLayoutConstraint = NSLayoutConstraint(item: textField, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: separatorInset.left+1)
        contentView.addConstraint(textFieldLeftLayoutConstraint)
        contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: .Right, relatedBy: .Equal, toItem: contentView, attribute: .Right, multiplier: 1, constant: -10))
        contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1, constant: 0))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITableView {
    func textFieldForRowAtIndexPath(indexPath: NSIndexPath) -> UITextField? {
        return (cellForRowAtIndexPath(indexPath) as! TextFieldTableViewCell?)?.textField
    }
}
