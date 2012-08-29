### Getting Started

This project uses [Objective-C literals][1], so I recommend you download Xcode 4.5 or later from the [iOS Dev Center : Beta Downloads][2]. If you know how to translate Objective-C literals, however, you probably can get it running with the App-Store version of Xcode (currently 4.4.1).

    git clone https://github.com/acani/AcaniChat.git
    cd AcaniChat
    git checkout edge
    git submodule update --init
    open AcaniChat.xcproj

### License

Some of the images used were taken from Apple's ChatKit.framework:

    open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk/System/Library/PrivateFrameworks/ChatKit.framework

I found them here by doing:

    find /Applications/Xcode.app/ -name *.png

Then, I saw images in the ChatKit.framework directory. E.g.:

    find /Applications/Xcode.app/ -name SendButton.png


 [1]: http://clang.llvm.org/docs/ObjectiveCLiterals.html
 [2]: https://developer.apple.com/devcenter/ios/index.action#betadownloads
