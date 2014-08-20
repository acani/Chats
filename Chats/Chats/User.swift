import Foundation

class User {
    let ID: Int
    var firstName: String?
    var lastName: String?
    var name: String? {
    if firstName != nil && lastName != nil {
        return firstName! + " " + lastName!
    } else if firstName != nil {
        return firstName
    } else {
        return lastName
    }
    }
    var initials: String? {
    var initials: String?
        for name in [firstName, lastName] {
            if let definiteName = name {
                var initial = definiteName.substringToIndex(advance(definiteName.startIndex, 1))
                if initial.lengthOfBytesUsingEncoding(NSNEXTSTEPStringEncoding) > 0 {
                    initials = (initials == nil ? initial : initials! + initial)
                }
            }
        }
        return initials
    }

    init(ID: Int) {
        self.ID = ID
    }

    convenience init(ID: Int, firstName: String?, lastName: String?) {
        self.init(ID: ID)
        self.firstName = firstName
        self.lastName = lastName
    }

    func pictureName() -> String {
        return "User\(ID).jpg"
    }
}
