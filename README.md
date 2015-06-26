# Acani Chats

Acani Chats is an [instant messaging][1] [social application][2]. Use it as an example for building an app that requires user accounts, profiles, communication, etc.


![Screenshots][3]


## Instructions for OS X

1. Download & install [Xcode 6.3.2 from the App Store][4]

2. Download this project, including its submodules

        git clone --recursive git@github.com:acani/Chats.git

3. Open `Clients/iPhone/Chats.xcodeproj` and press Command-R to run the app

Note: User data (e.g., phone number, first & last names, email address, etc.) are sent over SSL to [Heroku][5], stored with [PostgreSQL][6], and may be deleted at anytime for any reason.


## License

This project, excluding [works credited][7], are released under the [Unlicense][98].


  [1]: https://en.wikipedia.org/wiki/Instant_messaging
  [2]: https://en.wikipedia.org/wiki/Social_software
  [3]: Documents/iPhone-Screenshots.gif
  [4]: http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12
  [5]: https://www.heroku.com
  [6]: http://www.postgresql.org
  [7]: https://github.com/acani/Chats/blob/master/CREDITS.md
  [8]: http://unlicense.org
