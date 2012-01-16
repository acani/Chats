// Old
#import <AudioToolbox/AudioToolbox.h>

#import "ChatBar.h"

@class Message;

@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate,
UITableViewDelegate, UITableViewDataSource,  UIActionSheetDelegate,

ChatBarDelegate
> {

    NSMutableArray *cellMap;
    UITableView *chatContent;
    ChatBar *chatBar;
    
    NSManagedObjectContext *managedObjectContext;
    
    NSFetchedResultsController *fetchedResultsController;
}

@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, strong) UITableView *chatContent;

@property (nonatomic, strong) ChatBar *chatBar;

@property (nonatomic, copy) NSMutableArray *cellMap;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;


- (void)fetchResults;

@end
