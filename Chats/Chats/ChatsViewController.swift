import UIKit

class ChatsViewController: UITableViewController {
    var chats: [Chat] { return account.chats }

    convenience init() {
        self.init(style: .Plain)
        title = "Chats"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let minute: NSTimeInterval = 60, hour = minute * 60, day = hour * 24
        account.chats = [
            Chat(user: User(ID: 2, name: "Angel Rao"), lastMessageText: "6 sounds good :-)", lastMessageSentDate: NSDate()),
            Chat(user: User(ID: 3, name: "Valentine Sanchez"), lastMessageText: "Haha", lastMessageSentDate: NSDate(timeIntervalSinceNow: -minute)),
            Chat(user: User(ID: 4, name: "Aghbalu Amghar"), lastMessageText: "Damn", lastMessageSentDate: NSDate(timeIntervalSinceNow: -hour*13)),
            Chat(user: User(ID: 5, name: "Candice Meunier"), lastMessageText: "I can't wait to see you! ❤️", lastMessageSentDate: NSDate(timeIntervalSinceNow: -hour*34)),
            Chat(user: User(ID: 6, name: "Ferdynand Kaźmierczak"), lastMessageText: "http://youtu.be/UZb2NOHPA2A", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*2-1)),
            Chat(user: User(ID: 7, name: "Lauren Cooper"), lastMessageText: "Thinking of you...", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*3)),
            Chat(user: User(ID: 8, name: "Bradley Simpson"), lastMessageText: "👍", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*4)),
            Chat(user: User(ID: 9, name: "Clotilde Thomas"), lastMessageText: "Sounds good!", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*5)),
            Chat(user: User(ID: 10, name: "Tania Caramitru"), lastMessageText: "Cool. Thanks!", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*6)),
            Chat(user: User(ID: 11, name: "Ileana Mazilu"), lastMessageText: "Hey, what are you up to?", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*7)),
            Chat(user: User(ID: 12, name: "Asja Zuhrić"), lastMessageText: "Drinks tonight?", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*8)),
            Chat(user: User(ID: 13, name: "Sarah Lam"), lastMessageText: "Are you going to Blues on the Green tonight?", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*9)),
            Chat(user: User(ID: 14, name: "Ishan Sarin"), lastMessageText: "Thanks for open sourcing Chats.", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*10)),
            Chat(user: User(ID: 15, name: "Stella Vosper"), lastMessageText: "Those who dance are considered insane by those who can't hear the music.", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 16, name: "Georgeta Mihăileanu"), lastMessageText: "Hey, what are you up to?", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 17, name: "Alice Adams"), lastMessageText: "Hey, want to hang out tonight?", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 18, name: "Gerard Gómez"), lastMessageText: "Haha. Hell yeah! No problem, bro!", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 19, name: "Melinda Osváth"), lastMessageText: "I am excellent!!! I was thinking recently that you are a very inspirational person.", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 20, name: "Saanvi Sarin"), lastMessageText: "See you soon!", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11)),
            Chat(user: User(ID: 21, name: "Jade Roger"), lastMessageText: "😊", lastMessageSentDate: NSDate(timeIntervalSinceNow: -day*11))
        ]

        navigationItem.leftBarButtonItem = editButtonItem() // TODO: KVO
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.rowHeight = chatCellHeight
        tableView.separatorInset.left = chatCellInsetLeft
        tableView.registerClass(ChatCell.self, forCellReuseIdentifier: NSStringFromClass(ChatCell))
    }

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }

    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ChatCell), forIndexPath: indexPath) as ChatCell
        cell.configureWithChat(account.chats[indexPath.row])
        return cell
    }

    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            account.chats.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            if account.chats.count == 0 {
                navigationItem.leftBarButtonItem = nil  // TODO: KVO
            }
        }
    }

    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let chat = chats[indexPath.row]
        let chatViewController = ChatViewController(chat: chat)
        navigationController.pushViewController(chatViewController, animated: true)
    }
}
