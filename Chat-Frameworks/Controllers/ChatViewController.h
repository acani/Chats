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

- (id) createNewMessageWithText: (NSString*) text;

@property (nonatomic, strong) NSArray * array; 

+ (NSArray *) sortDescriptors;

+ (Class) delimiterClass;

+ (Class) contentClass;

@end
