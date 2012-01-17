// Old
#import "ChatViewController.h"

#import "NSString+Additions.h"


#import "TVCell_Date.h"
#import "TVCell_Message.h"


#import "ChatViewController+Mutability.h"
#import "ChatViewController+Keyboard.h"



#define VIEW_WIDTH    self.view.frame.size.width
#define VIEW_HEIGHT    self.view.frame.size.height

#define RESET_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight1)
#define EXPAND_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight4)
#define    SET_CHAT_BAR_HEIGHT(HEIGHT)\
CGRect chatContentFrame = chatContent.frame;\
chatContentFrame.size.height = VIEW_HEIGHT - HEIGHT;\
[UIView beginAnimations:nil context:NULL];\
[UIView setAnimationDuration:0.1f];\
chatContent.frame = chatContentFrame;\
chatBar.frame = CGRectMake(chatBar.frame.origin.x, chatContentFrame.size.height,\
VIEW_WIDTH, HEIGHT);\
[UIView commitAnimations]



@implementation ChatViewController
/*
@synthesize receiveMessageSound;

@synthesize chatContent;

@synthesize chatBar;

@synthesize cellMap;
*/


@synthesize  array = _array;

- (void) setArray:(NSArray *)array {
    _array = array;
    
    [_array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addMessage: obj];
    }];
    [chatContent reloadData];
}

#pragma mark NSObject

- (void)dealloc {
    if (receiveMessageSound) AudioServicesDisposeSystemSoundID(receiveMessageSound);
}

#pragma mark UIViewController

- (void)viewDidUnload {
/*    self.chatContent = nil;
    self.chatBar = nil;

//    self.cellMap = nil;
    
  */  

    // Leave managedObjectContext since it's not recreated in viewDidLoad
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");

    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    // Listen for keyboard.
    [self registerKeyboard];

    self.view.backgroundColor = CHAT_BACKGROUND_COLOR; // shown during rotation    
    
    // Create chatContent.
    chatContent = [[UITableView alloc] initWithFrame:
                   CGRectMake(0.0f, 0.0f, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1)];
    chatContent.clearsContextBeforeDrawing = NO;
    chatContent.delegate = self;
    chatContent.dataSource = self;
    chatContent.contentInset = UIEdgeInsetsMake(7.0f, 0.0f, 0.0f, 0.0f);
    chatContent.backgroundColor = CHAT_BACKGROUND_COLOR;
    chatContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    chatContent.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:chatContent];
    
    // Create chatBar.
    chatBar = [[ChatBar alloc] initWithFrame:
               CGRectMake(0.0f, self.view.frame.size.height-kChatBarHeight1,
                          self.view.frame.size.width, kChatBarHeight1)];

    chatBar.delegate= self;
    
    [self.view addSubview:chatBar];
    [self.view sendSubviewToBack:chatBar];
    

    cellMap = [[NSMutableArray alloc] initWithCapacity:20];
    
    // TODO: Implement check-box edit mode like iPhone Messages does. (Icebox)
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; // below: work around for [chatContent flashScrollIndicators]
    NSLog(@"viewWillAppear");
    [chatContent performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
   // [chatBar.chatInput resignFirstResponder];
    [chatBar resignFirstResponder];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:(BOOL)editing animated:(BOOL)animated];
    [chatContent setEditing:(BOOL)editing animated:(BOOL)animated]; // forward method call
//    chatContent.separatorStyle = editing ?
//            UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    
    if (editing) {
        UIBarButtonItem *clearAllButton =
        [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Clear All", nil) style:(UIBarButtonItemStylePlain) target: self action: @selector(clearAll)];
        
        //BAR_BUTTON(NSLocalizedString(@"Clear All", nil),
          //                                           @selector(clearAll));
        self.navigationItem.leftBarButtonItem = clearAllButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
//    if ([chatInput isFirstResponder]) {
//        NSLog(@"resign first responder");
//        [chatInput resignFirstResponder];
//    }
}

- (id) createNewMessageWithText: (NSString*) text{
    // must be mutable, if need to be edited later......
    NSDictionary * dict = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     text, @"text", [NSDate date], @"sentDate"
     , nil];
    
    return dict;
}

#pragma mark Message
- (void) chatBar:(ChatBar *)chatBar didSendText:(NSString *)text {
    
//    // TODO: Show progress indicator like iPhone Message app does. (Icebox)
//    [activityIndicator startAnimating];
    
    NSString *rightTrimmedMessage =
       // [chatBar.chatInput.text 
    [text stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
    
    // Don't send blank messages.
    if (rightTrimmedMessage.length == 0) {
        [chatBar clearChatInput];
        return;
    }
    
    id object = [self createNewMessageWithText: text];

    if (YES) {
        [self addMessage: object];
        [chatContent reloadData];
    }else {
        // if CoreData.. no need, because FRC Delegate will do. 
    }
   
    
    [chatBar  clearChatInput]; // ????????
    
    [self scrollToBottomAnimated:YES]; // must come after RESET_CHAT_BAR_HEIGHT above
    
    // Play sound or buzz, depending on user settings.
    NSString *sendPath = [[NSBundle mainBundle] pathForResource:@"basicsound" ofType:@"wav"];
    CFURLRef baseURL = (__bridge CFURLRef)[NSURL fileURLWithPath:sendPath];
    AudioServicesCreateSystemSoundID(baseURL, &receiveMessageSound);
    AudioServicesPlaySystemSound(receiveMessageSound);
//    AudioServicesPlayAlertSound(receiveMessageSound); // use for receiveMessage (sound & vibrate)
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // explicit vibrate
}


#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"number of rows: %d", [cellMap count]);
    return [cellMap count];
}

static NSString *kMessageCell = @"MessageCell";

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSLog(@"cell for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    
    // Handle sentDate (NSDate).
    if ([object isKindOfClass:[NSDate class]]) {
        static NSString *kSentDateCellId = @"SentDateCell";
        TVCell_Date * cell_date = nil;
        cell_date = [tableView dequeueReusableCellWithIdentifier:kSentDateCellId];
        if (cell_date == nil) {
            
            cell_date = [[TVCell_Date alloc] initWithReuseIdentifier: kSentDateCellId];
        }
        
        cell_date.date = (NSDate *)object;
        
        return cell_date;
    }
    
    
    // Handle Message object.
    TVCell_Message * cell_message;
    cell_message = [tableView dequeueReusableCellWithIdentifier:kMessageCell];
    if (cell_message == nil) {
        cell_message = [[TVCell_Message alloc] initWithReuseIdentifier: kMessageCell];
    }
    //[cell_message setMessage: (Message *)object rightward: !([indexPath row] % 3)];
    
    cell_message.message =  object;
       
    
    
    return cell_message;
}


#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"height for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    
    // Set SentDateCell height.
    if ([object isKindOfClass:[NSDate class]]) {
        return kSentDateFontSize + 7.0f;
    }
    
    // Set MessageCell height.
    NSString * text = [object valueForKey: @"text"];
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 17.0f;
}

// // beginUpdates & endUpdates cause the cells to get mixed up when scrolling aggressively.
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [chatContent endUpdates];
//}

- (void) chatBarTextCleared:(ChatBar *)chatBar {
    
}

- (void) chatBar:(ChatBar *)chatBar didChangeHeight:(CGFloat)height {
    SET_CHAT_BAR_HEIGHT(height);
    [self scrollToBottomAnimated: YES];
}

@end
