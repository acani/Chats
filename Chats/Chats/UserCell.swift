import UIKit

let userCellHeight: CGFloat = 56.5

class UserCell: UITableViewCell {
    let pictureImageView: UIImageView
    let nameLabel: UILabel
    let usernameLabel: UILabel

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        let pictureSize = userCellHeight - 0.5
        pictureImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: pictureSize, height: pictureSize))
        pictureImageView.backgroundColor = UIColor(white: 238/255, alpha: 1)

        nameLabel = UILabel(frame: CGRectZero)
        nameLabel.autoresizingMask = .FlexibleWidth
//        nameLabel.backgroundColor = UIColor.orangeColor()
        nameLabel.font = UIFont.systemFontOfSize(17)

        usernameLabel = UILabel(frame: CGRectZero)
        usernameLabel.autoresizingMask = .FlexibleWidth
//        usernameLabel.backgroundColor = UIColor.orangeColor()
        usernameLabel.font = UIFont.systemFontOfSize(15)
        usernameLabel.textColor = UIColor(white: 143/255.0, alpha: 1)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.frame = CGRect(x: userCellHeight+10, y: 7, width: contentView.frame.width, height: 22)
        usernameLabel.frame = CGRect(x: userCellHeight+10, y: 29, width: contentView.frame.width, height: 20)
        self.addSubview(pictureImageView)
        self.addSubview(nameLabel)
        self.addSubview(usernameLabel)
    }
}
