// Old
#import <AudioToolbox/AudioToolbox.h>

@class Message;

@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate> {

}

@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, retain) UITableView *chatContent;

@property (nonatomic, retain) UIImageView *chatBar;
@property (nonatomic, retain) UITextView *chatInput;
@property (nonatomic, assign) CGFloat previousContentHeight;
@property (nonatomic, retain) UIButton *sendButton;

@property (nonatomic, copy) NSMutableArray *cellMap;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (void)enableSendButton;
- (void)disableSendButton;
- (void)resetSendButton;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)resizeViewWithOptions:(NSDictionary *)options;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)sendMessage;
- (void)clearChatInput;
- (NSUInteger)addMessage:(Message *)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

- (void)fetchResults;

@end
