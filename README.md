# AcaniChat

## Native iPhone Messages.app with WebSocket & Bonjour over Bluetooth

![AcaniChat Conversations Screenshot][1] &nbsp;&nbsp;&nbsp;&nbsp; ![AcaniChat Messages Screenshot][11]


### Technology

#### Client (iOS)

* UIKit framework, mainly `UINavigationController` & `UITableViewController`, to display conversations & messages
* Copied images from Apple's ChatKit.framework to beautify the UI
* Core Data framework to persist conversations & messages (stores them to disk in an SQLite file)
* [SocketRocket][14] to communicate with the server via [WebSocket][15]
* Coming soon: Bonjour over Bluetoothh for peer-to-peer (p2p) communication
* *Note*: Ability to delete messages was removed after commit b269281 to keep things simple

#### Server ([Node.js][18])

* [Nodejitsu][13]-hosted instance of [acani-chat-server][12]
* [Node.js `ws` module][17] to communicate with clients via [WebSocket][15]
  * I chose `ws` because I think Socket.io (recommended by the Node.js website) uses `ws`. And, I didn't want the extra backwards compatibility that Socket.io offers.
* [Redis][16] to store messages in a list

##### Installation

* Install Node.js & NPM from http://nodejs.org
* Install Redis from http://redis.io or via `brew install redis`.

##### Hosting

Heroku doesn't support websockets yet, so I went with nodejitsu. modulus.io is another option. To host with nodejitsu, follow http://nodejitsu.com/paas/getting-started.html.


### Getting Started

AcaniChat uses [Objective-C literals][8], so make sure you have Xcode 4.5 or later, which you can download from [iOS Dev Center : Beta Downloads][9].

    git clone https://github.com/acani/AcaniChat.git
    cd AcaniChat
    git checkout edge
    git submodule update --init
    open AcaniChat.xcproj


### License

AcaniChat, except for those images copied from Apple's ChatKit.framework, is released under the [MIT License][10].

How to find Apple's ChatKit.framework images, e.g.:

    find /Applications/Xcode.app/ -name *.png
    find /Applications/Xcode.app/ -name SendButton.png
    open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk/System/Library/PrivateFrameworks/ChatKit.framework


### Contributors

* [Matt Di Pasquale][7]
* Peng Wan
* Abhinav Sharma
* Nick LeMay
* Eugene Bae


### Related Projects & Links

* [SSMessagesViewController][6]
* [Twitterfon][2]
* [Video Tutorial on SMS style bubbles][3]
* [StackOverflow: Implement view like standard iPhone SMS-chat bubbles view][4]
* [StackOverflow: Creating a “chat bubble” on the iPhone, like Tweetie.][5]


  [1]: https://github.com/acani/AcaniChat/raw/master/Screenshots/Conversations.png
  [2]: https://github.com/jpick/twitterfon
  [3]: http://vimeo.com/8718829
  [4]: http://stackoverflow.com/questions/663435/implement-view-like-standard-iphone-sms-chat-bubbles-view
  [5]: http://stackoverflow.com/questions/351602/creating-a-chat-bubble-on-the-iphone-like-tweetie
  [6]: https://github.com/samsoffes/ssmessagesviewcontroller
  [7]: http://www.mattdipasquale.com/
  [8]: http://clang.llvm.org/docs/ObjectiveCLiterals.html
  [9]: https://developer.apple.com/devcenter/ios/index.action#betadownloads
  [10]: http://www.opensource.org/licenses/MIT
  [11]: https://github.com/acani/AcaniChat/raw/master/Screenshots/Messages.png
  [12]: https://github.com/acani/acani-chat-server
  [13]: http://nodejitsu.com/
  [14]: https://github.com/square/SocketRocket
  [15]: http://en.wikipedia.org/wiki/WebSocket
  [16]: http://redis.io
  [17]: http://einaros.github.com/ws/
  [18]: http://nodejs.org/
