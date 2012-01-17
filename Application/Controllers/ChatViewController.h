// Old
#import <AudioToolbox/AudioToolbox.h>

#import "ChatBar.h"

//@class Message;

@interface ChatViewController : UIViewController <
UITableViewDelegate, UITableViewDataSource,  UIActionSheetDelegate,

ChatBarDelegate
> {

    SystemSoundID receiveMessageSound;
    NSMutableArray *cellMap;
    UITableView *chatContent;
    ChatBar *chatBar;
    
}
/*
@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, strong) UITableView *chatContent;

@property (nonatomic, strong) ChatBar *chatBar;

//@property (nonatomic, copy) NSMutableArray *cellMap;
*/
- (id) createNewMessageWithText: (NSString*) text;

@property (nonatomic, strong) NSArray * array; 

@end
