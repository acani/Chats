import UIKit

class User {
    var name: String
    var profilePicture: UIImage?
    
    init(name: String, profilePicture: UIImage?) {
        self.name = name
        self.profilePicture = profilePicture;
    }
    
    convenience init(name: String) {
        self.init(name: name, profilePicture: nil)
    }
}
