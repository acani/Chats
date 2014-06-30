import Foundation

class Message {
    let incoming: Bool
    let text: String
    let sentDate: NSDate

    init(incoming: Bool, text: String, sentDate: NSDate) {
        self.incoming = incoming
        self.text = text
        self.sentDate = sentDate
    }
}
