import Foundation

var dateFormatter = NSDateFormatter()

class Chat {
    let user: User
    var lastMessageText: String
    var lastMessageSentDate: NSDate
    var lastMessageSentDateString: String {
    return formatDate(lastMessageSentDate)
    }
    var loadedMessages = [[Message]]()
    var unreadMessageCount: Int = 0 // subtacted from total when read
    var hasUnloadedMessages = false
    var draft = ""

    init(user: User, lastMessageText: String, lastMessageSentDate: NSDate) {
        self.user = user
        self.lastMessageText = lastMessageText
        self.lastMessageSentDate = lastMessageSentDate
    }

    func formatDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()

        let last18hours = (-18*60*60 < date.timeIntervalSinceNow)
        let isToday = calendar.isDateInToday(date)
        let isLast7Days = (calendar.compareDate(NSDate(timeIntervalSinceNow: -7*24*60*60), toDate: date, toUnitGranularity: .CalendarUnitDay) == NSComparisonResult.OrderedAscending)

        if last18hours || isToday {
            dateFormatter.dateStyle = .NoStyle
            dateFormatter.timeStyle = .ShortStyle
        } else if isLast7Days {
            dateFormatter.dateFormat = "ccc"
        } else {
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .NoStyle
        }
        return dateFormatter.stringFromDate(date)
    }
}
