# AcaniChat - HTML5 WebSockets & Node.js chat on the iPhone

An open-source version of iPhone's native Messages app

![AcaniChat screenshot][1]

## Features

Currently, AcaniChat features message persistence with Core Data and a chat view
that allows you to send chat bubbles to yourself. Next, we'll implement sending
messages over the network through the Acani chat server.

* ConversationsViewController: List of conversations (`UITableViewController`)
  * Coming soon...

* ChatViewController: One-on-one Chat (`UIViewController`)
  * chatContent (`UITableView`)
      * Identical UI (colors, layout, and font size) to iPhone's Messages app
      * Conditional timestamps (only shown every so often)
      * Delete edit-mode: Delete one message at a time or clear all at once
      * Trims whitespace on ends of messages; prevents sending blank messages
  * chatInput (`UITextView`)
      * `sendButton.enabled = [chatInput isEmpty] ? NO : YES`
      * Collapses & expands (between one & four lines) with content
      * becomes scrollable after content exceeds four lines

## iOS Technologies

* UIKit
  * `UINavigationController`
  * Custom `UITableViewCell`s
  * Core Data

* Coming Soon
  * ZTWebSocket & AsyncSocket

## Design Practices

AcaniChat is simple yet modular, implementation-agnostic, and extensible.

* Create views programmatically

### Authentication: Facebook Connect & NSURLConnection

AcaniChat will implement authentication through various third-party accounts,
such as Facebook, Twitter, GitHub, etc.

### Connection: HTML5 WebSockets - ZTWebSocket & AsyncSocket

AcaniChat will soon be able to connect to web servers that support HTML5
WebSockets. It will use ZTWebSocket, built on top of AsyncSocket, to support a
WebSockets connection.

### Server: HTML5 WebSockets - Node.js & Redis

Using [Node.js][] & [node-websocket-server][], we built a chat server called
[acani-chat-server][] (coming soon) that supports HTML5 WebSockets connections.

### Chat: Redis PUB/SUB

The Acani chat server uses [Redis][] & the [Redis PUB/SUB functions][] to
implement chat. Each user subscribes to the channel named after her username.

## Contributors

* [Matt Di Pasquale][7]
* Peng Wan
* Abhinav Sharma
* Nick LeMay
* Eugene Bae

## Related Projects & Links

* [SSMessagesViewController][6]
* [Twitterfon][2]
* [Video Tutorial on SMS style bubbles][3]
* [StackOverflow: Implement view like standard iPhone SMS-chat bubbles view][4]
* [StackOverflow: Creating a “chat bubble” on the iPhone, like Tweetie.][5]


  [1]: https://github.com/acani/AcaniChat/raw/master/Resources/chatview-screenshot.png
  [2]: https://github.com/jpick/twitterfon
  [3]: http://vimeo.com/8718829
  [4]: http://stackoverflow.com/questions/663435/implement-view-like-standard-iphone-sms-chat-bubbles-view
  [5]: http://stackoverflow.com/questions/351602/creating-a-chat-bubble-on-the-iphone-like-tweetie
  [6]: https://github.com/samsoffes/ssmessagesviewcontroller
  [7]: http://www.mattdipasquale.com/
