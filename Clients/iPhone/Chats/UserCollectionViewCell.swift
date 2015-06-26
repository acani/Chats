import UIKit

let userCollectionViewCellHeight: CGFloat = 93

class UserCollectionViewCell: UICollectionViewCell {
    let nameLabel = UILabel(frame: CGRect(x: 3, y: userCollectionViewCellHeight-20, width: userCollectionViewCellHeight-6, height: 20))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 248/255, alpha: 1)
        layer.borderColor = UIColor(white: 178/255, alpha: 1).CGColor
        layer.borderWidth = 0.5

        backgroundView = UIImageView(frame: frame)
        selectedBackgroundView = UIView(frame: frame)
        selectedBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)

        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.font = UIFont.systemFontOfSize(13)
        nameLabel.lineBreakMode = NSLineBreakMode.ByClipping
        nameLabel.shadowColor = UIColor.blackColor()
        nameLabel.shadowOffset = CGSize(width: 1, height: 1)
        nameLabel.textColor = UIColor.whiteColor()
        contentView.addSubview(nameLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
