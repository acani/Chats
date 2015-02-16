# Chats

* Add app icon

## ChatsViewController

* Is there a better way than lengthOfBytesUsingEncoding to check if string is ASCII?
* Add search bar
* Edit, done, sentDateLabel.x #bug
* Use KVO to set edit button enabled

## ChatViewController

* Revert `loadedMessages` to a one-dimensional array
* Then, write code that iterates through `loadedMessages` and groups them into sections in a new two-dimensional array based on their sent dates
* Add each new message to the last section (instead of a new section) if sent within a certain time interval
* Fix scroll-to-bottom after message-send #bug
* Format sent-date correctly
* Make sent-date bold and keep sent-time normal
* Add sent times off screen to right, accessible via swipe-left
* Enter multilines, scroll to top of tableView, delete line #bug
* Add "Load Earlier Messages" button
* Detect all data types in message text
* Show sending progress indicator
* Animate mesage during sending (going from textView to tableView)
* Send photos & videos
* Add red (!) button on failed message send
* Fix resulting contentOffset when pasting multiple lines into textView #bug #messenger
