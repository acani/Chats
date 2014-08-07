import UIKit

class ChatCell: AChatCell {
    func configureWithChat(chat: Chat) {
        userPictureImageView.image = UIImage(named: chat.user.pictureName())
        if !userPictureImageView.image {
            if chat.user.name.initials.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) == 0 {
                userPictureImageView.image = UIImage(named: "ProfilePicture")
                userNameInitialsLabel.hidden = true
            } else {
                userNameInitialsLabel.text = chat.user.name.initials
                userNameInitialsLabel.hidden = false
            }
        } else {
            userNameInitialsLabel.hidden = true
        }
        userNameLabel.text = chat.user.name
        lastMessageTextLabel.text = chat.lastMessageText
        lastMessageSentDateLabel.text = chat.lastMessageSentDateString
    }
}

