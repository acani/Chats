// Old
#import <AudioToolbox/AudioToolbox.h>

@class Message;

@interface ChatViewController : UIViewController <NSFetchedResultsControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate> {
    
    CGRect keyboardEndFrame;


}

@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UITableView *chatContent;

@property (nonatomic, retain) UIImageView *chatBar;
@property (nonatomic, retain) UITextView *chatInput;
@property (nonatomic, assign) CGFloat previousContentHeight;
@property (nonatomic, retain) UIButton *sendButton;

@property (nonatomic, copy) NSMutableArray *cellMap;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, retain) UIImage       *clearballoon;
@property (nonatomic, retain) UIImage       *greenballoon;

@property (nonatomic, assign) BOOL          keyboardIsShowing;

- (void)enableSendButton;
- (void)disableSendButton;
- (void)resetSendButton;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)slideFrame:(BOOL)up curve:(UIViewAnimationCurve)curve duration:(NSTimeInterval)duration;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)sendMessage;
- (void)clearChatInput;
- (NSUInteger)addMessage:(Message *)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

- (void)fetchMessages;

@end
