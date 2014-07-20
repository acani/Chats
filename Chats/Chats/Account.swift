class Account {
    let user: User
    var chats = [Chat]()

    init(user: User) {
        self.user = user
    }
}
