# AcaniChat

## Native iPhone Messages.app with WebSocket & Bonjour over Bluetooth

![AcaniChat Conversations Screenshot][1] ![AcaniChat Messages Screenshot][11]


### Technology

#### Client (iOS)

* UIKit framework, mainly `UINavigationController` & `UITableViewController`, to display conversations & messages
* Copied images from Apple's ChatKit.framework to beautify the UI
* Core Data framework to persist conversations & messages by storing them to disk in an SQLite file
* [SocketRocket]][14] to communicate with the server via [WebSocket][15].
* Coming soon: Bonjour over Bluetoothh for peer-to-peer (p2p) communication.
* *Note*: Ability to delete messages was removed after commit b269281 to keep things simple.

#### Server (Node.js)

* [Nodejitsu][13]-hosted instance of [acani-chat-server][12]
* Node [`ws`][17] module to communicate with clients via [WebSocket][15]
* [Redis][16] to store messages in a list


### Getting Started

AcaniChat uses [Objective-C literals][8], so I recommend downloading Xcode 4.5 or later from the [iOS Dev Center : Beta Downloads][9]. If you know how to translate Objective-C literals and fix other compiler errors, however, you probably can get it running with the App-Store version of Xcode (currently 4.4.1).

    git clone https://github.com/acani/AcaniChat.git
    cd AcaniChat
    git checkout edge
    git submodule update --init
    open AcaniChat.xcproj


### License

Some of the images used for AcaniChat were copied from Apple's ChatKit.framework:

    open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk/System/Library/PrivateFrameworks/ChatKit.framework

You can these images like so:

    find /Applications/Xcode.app/ -name *.png

The above command lists images in the ChatKit.framework directory. E.g.:

    find /Applications/Xcode.app/ -name SendButton.png

AcaniChat, except for those images copied from Apple's ChatKit.framework, is released under the [MIT License][10].


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


  [1]: https://github.com/acani/AcaniChat/raw/master/Resources/ScreenshotConversations.png
  [2]: https://github.com/jpick/twitterfon
  [3]: http://vimeo.com/8718829
  [4]: http://stackoverflow.com/questions/663435/implement-view-like-standard-iphone-sms-chat-bubbles-view
  [5]: http://stackoverflow.com/questions/351602/creating-a-chat-bubble-on-the-iphone-like-tweetie
  [6]: https://github.com/samsoffes/ssmessagesviewcontroller
  [7]: http://www.mattdipasquale.com/
  [8]: http://clang.llvm.org/docs/ObjectiveCLiterals.html
  [9]: https://developer.apple.com/devcenter/ios/index.action#betadownloads
  [10]: http://www.opensource.org/licenses/MIT
  [11]: https://github.com/acani/AcaniChat/raw/master/Resources/ScreenshotMessages.png
  [12]: https://github.com/acani/acani-chat-server
  [13]: http://nodejitsu.com/
  [14]: https://github.com/square/SocketRocket
  [15]: http://en.wikipedia.org/wiki/WebSocket
  [16]: http://redis.io
  [17]: http://einaros.github.com/ws/
