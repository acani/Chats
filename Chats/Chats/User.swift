class User {
    let ID: Int
    var name: String

    init(ID: Int, name: String) {
        self.ID = ID
        self.name = name
    }

    func pictureName() -> String {
        return "User\(ID).jpg"
    }
}
