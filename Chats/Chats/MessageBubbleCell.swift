import UIKit

class MessageBubbleCell: AMessageBubbleCell {

    func configureWithMessage(message: Message) {
        messageLabel.text = message.text

        if message.incoming != (tag == incomingTag) {
            var layoutAttribute: NSLayoutAttribute
            var layoutConstant: CGFloat

            if message.incoming {
                tag = incomingTag
                bubbleImageView.image = bubbleImage.incoming
                bubbleImageView.highlightedImage = bubbleImage.incomingHighlighed
                messageLabel.textColor = UIColor.blackColor()
                layoutAttribute = .Left
                layoutConstant = 10
            } else { // outgoing
                tag = outgoingTag
                bubbleImageView.image = bubbleImage.outgoing
                bubbleImageView.highlightedImage = bubbleImage.outgoingHighlighed
                messageLabel.textColor = UIColor.whiteColor()
                layoutAttribute = .Right
                layoutConstant = -10
            }

            let layoutConstraint: NSLayoutConstraint = bubbleImageView.constraints()[1] as NSLayoutConstraint // `messageLabel` CenterX
            layoutConstraint.constant = -layoutConstraint.constant

            let constraints: NSArray = contentView.constraints()
            let indexOfConstraint = constraints.indexOfObjectPassingTest { (var constraint, idx, stop) in
                return (constraint.firstItem as UIView).tag == bubbleTag && (constraint.firstAttribute == NSLayoutAttribute.Left || constraint.firstAttribute == NSLayoutAttribute.Right)
            }
            contentView.removeConstraint(constraints[indexOfConstraint] as NSLayoutConstraint)
            contentView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: layoutAttribute, relatedBy: .Equal, toItem: contentView, attribute: layoutAttribute, multiplier: 1, constant: layoutConstant))
        }
    }
}
