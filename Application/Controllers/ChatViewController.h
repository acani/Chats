// Old
#import <AudioToolbox/AudioToolbox.h>

#import "ChatBar.h"

@class Message;

@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate,
UITableViewDelegate, UITableViewDataSource,  UIActionSheetDelegate,

ChatBarDelegate
> {

}

@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, retain) UITableView *chatContent;

@property (nonatomic, retain) ChatBar *chatBar;

@property (nonatomic, copy) NSMutableArray *cellMap;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;


- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)resizeViewWithOptions:(NSDictionary *)options;
- (void)scrollToBottomAnimated:(BOOL)animated;

//- (void)sendMessage;
//- (void)clearChatInput;
- (NSUInteger)addMessage:(Message *)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

- (void)fetchResults;

@end
