#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#define HOST @"ws://acani-chat-server.jit.su/"
//#define HOST @"ws://localhost:5000/"

@class Conversation, PlaceholderTextView, SRWebSocket;

@interface MessagesViewController : UIViewController

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) PlaceholderTextView *textView;
@property (strong, nonatomic) UIButton *sendButton;

@property (strong, nonatomic) Conversation *conversation;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) SRWebSocket *webSocket;

@end
