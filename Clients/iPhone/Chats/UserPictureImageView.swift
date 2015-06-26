import UIKit

class UserPictureImageView: UIImageView {
    private let userNameInitialsLabel: UILabel

    override init(frame: CGRect) {
        userNameInitialsLabel = UILabel(frame: CGRectZero)
        super.init(frame: frame)

        backgroundColor = UIColor(red: 199/255, green: 199/255, blue: 204/255, alpha: 1)
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true

        userNameInitialsLabel.font = UIFont.systemFontOfSize(frame.width/2+1)
        userNameInitialsLabel.textAlignment = .Center
        userNameInitialsLabel.textColor = UIColor.whiteColor()
        addSubview(userNameInitialsLabel)

        userNameInitialsLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addConstraint(NSLayoutConstraint(item: userNameInitialsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: userNameInitialsLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: -1))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithUser(user: User) {
        if let pictureName = user.pictureName() {
            image = UIImage(named: pictureName)
            userNameInitialsLabel.hidden = true
        } else {
            let initials = user.initials
            if initials != nil {
                userNameInitialsLabel.text = initials
                userNameInitialsLabel.hidden = false
            } else {
                image = UIImage(named: "User0")
                userNameInitialsLabel.hidden = true
            }
        }
    }
}
