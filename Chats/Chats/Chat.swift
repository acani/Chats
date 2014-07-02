import Foundation

var dateFormatter = NSDateFormatter()

class Chat {
    let user: User
    var lastMessageText: String
    var lastMessageSentDate: NSDate
    var lastMessageSentDateString: String {
    return formatDate(lastMessageSentDate)
    }
    var loadedMessages = Message[]()
    var unreadMessageCount: UInt = 0 // subtacted from total when read
    var hasUnloadedMessages = false
    var draft = ""

    init(user: User, lastMessageText: String, lastMessageSentDate: NSDate) {
        self.user = user
        self.lastMessageText = lastMessageText
        self.lastMessageSentDate = lastMessageSentDate
    }

    func formatDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()

        // #iOS7.1
        let last18hours = (-18*60*60 < date.timeIntervalSinceNow)
        let dateComponents = calendar.components(.EraCalendarUnit | .YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit, fromDate: NSDate.date())
        let isToday = (calendar.dateFromComponents(dateComponents).compare(date) != .OrderedDescending)
        dateComponents.day -= 7
        let isLast7Days = (calendar.dateFromComponents(dateComponents).compare(date) == .OrderedAscending)
//        // #iOS8
//        let isToday = calendar.isDateInToday(date)
//        let isLast7Days = (calendar.compareDate(NSDate(timeIntervalSinceNow: -7*24*60*60), toDate: date, toUnitGranularity: .CalendarUnitDay) == NSComparisonResult.OrderedAscending)

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
