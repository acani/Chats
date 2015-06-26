import Foundation.NSString

class User {
    let ID: UInt
    var username: String
    var firstName: String
    var lastName: String
    var name: String {
        return firstName + " " + lastName
    }
    var initials: String? {
        var initials: String?
        for name in [firstName, lastName] {
            var initial = name.substringToIndex(advance(name.startIndex, 1))
            if initial.lengthOfBytesUsingEncoding(NSNEXTSTEPStringEncoding) > 0 {
                initials = (initials == nil ? initial : initials! + initial)
            }
        }
        return initials
    }

    init(ID: UInt, username: String, firstName: String, lastName: String) {
        self.ID = ID
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
    }

    func pictureName() -> String? {
        return ID > 21 ? nil : "User\(ID).jpg"
    }
}
