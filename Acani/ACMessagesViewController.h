#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class ACConversation, ACPlaceholderTextView, SRWebSocket;

@interface ACMessagesViewController : UIViewController

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ACPlaceholderTextView *textView;
@property (strong, nonatomic) UIButton *sendButton;

@property (strong, nonatomic) ACConversation *conversation;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)scrollToBottomAnimated:(BOOL)animated;

@end
