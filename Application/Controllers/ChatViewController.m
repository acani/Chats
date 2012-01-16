// Old
#import "ChatViewController.h"
#import "Message.h"
#import "NSString+Additions.h"


#import "TVCell_Date.h"
#import "TVCell_Message.h"

#define ClearConversationButtonIndex 0



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


// 15 mins between messages before we show the date
#define SECONDS_BETWEEN_MESSAGES        (60*15)


@implementation ChatViewController

@synthesize receiveMessageSound;

@synthesize chatContent;

@synthesize chatBar;

@synthesize cellMap;

@synthesize fetchedResultsController;
@synthesize managedObjectContext;

#pragma mark NSObject

- (void)dealloc {
    if (receiveMessageSound) AudioServicesDisposeSystemSoundID(receiveMessageSound);
    
    [chatContent release];
    
    [chatBar release];

    
    [cellMap release];
    
    [fetchedResultsController release];
    [managedObjectContext release];
    
    [super dealloc];
}

#pragma mark UIViewController

- (void)viewDidUnload {
    self.chatContent = nil;
    
    self.chatBar = nil;

    self.cellMap = nil;
    
    self.fetchedResultsController = nil;

    // Leave managedObjectContext since it's not recreated in viewDidLoad
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");

    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    // Listen for keyboard.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

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

    chatBar.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:chatBar];
    [self.view sendSubviewToBack:chatBar];
    
//    // Test with lots of messages.
//    NSDate *before = [NSDate date];
//    for (NSUInteger i = 0; i < 500; i++) {
//        Message *msg = (Message *)[NSEntityDescription
//                                   insertNewObjectForEntityForName:@"Message"
//                                   inManagedObjectContext:managedObjectContext];
//    msg.text = [NSString stringWithFormat:@"This is message number %d", i];
//    NSDate *now = [[NSDate alloc] init]; msg.sentDate = now; [now release];
//    }
////    sleep(2);
//    NSLog(@"Creating messages in memory takes %f seconds", [before timeIntervalSinceNow]);
//    NSError *error;
//    if (![managedObjectContext save:&error]) {
//        // TODO: Handle the error appropriately.
//        NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
//    }
//    NSLog(@"Saving messages to disc takes %f seconds", [before timeIntervalSinceNow]);
    
    [self fetchResults];
    
    // Construct cellMap from fetchedObjects.
    cellMap = [[NSMutableArray alloc]
               initWithCapacity:[[fetchedResultsController fetchedObjects] count]*2];
    
   
    for (Message *message in [fetchedResultsController fetchedObjects]) {
        [self addMessage:message];
    }
    
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
        [clearAllButton release];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
//    if ([chatInput isFirstResponder]) {
//        NSLog(@"resign first responder");
//        [chatInput resignFirstResponder];
//    }
}

#pragma mark ChatViewController



# pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)resizeViewWithOptions:(NSDictionary *)options {    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    [[options objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[options objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[options objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    CGRect viewFrame = self.view.frame;
    NSLog(@"viewFrame y: %@", NSStringFromCGRect(viewFrame));

//    // For testing.
//    NSLog(@"keyboardEnd: %@", NSStringFromCGRect(keyboardEndFrame));
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
//                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//                             target:chatInput action:@selector(resignFirstResponder)];
//    self.navigationItem.leftBarButtonItem = doneButton;
//    [doneButton release];

    CGRect keyboardFrameEndRelative = [self.view convertRect:keyboardEndFrame fromView:nil];
    NSLog(@"self.view: %@", self.view);
    NSLog(@"keyboardFrameEndRelative: %@", NSStringFromCGRect(keyboardFrameEndRelative));

    viewFrame.size.height =  keyboardFrameEndRelative.origin.y;
    self.view.frame = viewFrame;
    [UIView commitAnimations];
    
    [self scrollToBottomAnimated:YES];
    
    [chatBar resetCharInput];
    /*
    chatBar.chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    chatBar.chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
     */
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger bottomRow = [cellMap count] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [chatContent scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
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
        [self clearChatInput];
        return;
    }
    
    // Create new message and save to Core Data.
    Message *newMessage = (Message *)[NSEntityDescription
                                      insertNewObjectForEntityForName:@"Message"
                                      inManagedObjectContext:managedObjectContext];
    newMessage.text = rightTrimmedMessage;
    NSDate *now = [[NSDate alloc] init]; newMessage.sentDate = now; [now release];

    NSError *error;
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"sendMessage error %@, %@", error, [error userInfo]);
    }
    
    [self.chatBar  clearChatInput];
    
    [self scrollToBottomAnimated:YES]; // must come after RESET_CHAT_BAR_HEIGHT above
    
    // Play sound or buzz, depending on user settings.
    NSString *sendPath = [[NSBundle mainBundle] pathForResource:@"basicsound" ofType:@"wav"];
    CFURLRef baseURL = (CFURLRef)[NSURL fileURLWithPath:sendPath];
    AudioServicesCreateSystemSoundID(baseURL, &receiveMessageSound);
    AudioServicesPlaySystemSound(receiveMessageSound);
//    AudioServicesPlayAlertSound(receiveMessageSound); // use for receiveMessage (sound & vibrate)
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // explicit vibrate
}


// Returns number of objects added to cellMap (1 or 2).
- (NSUInteger)addMessage:(Message *)message 
{
    // Show sentDates at most every 15 minutes.
    NSDate *currentSentDate = message.sentDate;
    NSUInteger numberOfObjectsAdded = 1;
    NSUInteger prevIndex = [cellMap count] - 1;
    
    // Show sentDates at most every 15 minutes.

    if([cellMap count])
    {
        BOOL prevIsMessage = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[Message class]];
        if(prevIsMessage)
        {
            Message * temp = [cellMap objectAtIndex:prevIndex];
            NSDate * previousSentDate = temp.sentDate;
            // if there has been more than a 15 min gap between this and the previous message!
            if([currentSentDate timeIntervalSinceDate:previousSentDate] > SECONDS_BETWEEN_MESSAGES) 
            { 
                [cellMap addObject:currentSentDate];
                numberOfObjectsAdded = 2;
            }
        }
    }
    else
    {
        // there are NO messages, definitely add a timestamp!
        [cellMap addObject:currentSentDate];
        numberOfObjectsAdded = 2;
    }
    
    [cellMap addObject:message];
    
    message.isMine = [NSNumber numberWithBool: (([cellMap count] %3) == 0)];
    
//    [message.managedObjectContext save: nil];
    
    return numberOfObjectsAdded;

}

// Returns number of objects removed from cellMap (1 or 2).
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index {
//    NSLog(@"Delete message from cellMap");
    
    // Remove message from cellMap.
    [cellMap removeObjectAtIndex:index];
    NSUInteger numberOfObjectsRemoved = 1;
    NSUInteger prevIndex = index - 1;
    NSUInteger cellMapCount = [cellMap count];
    
    BOOL isLastObject = index == cellMapCount;
    BOOL prevIsDate = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[NSDate class]];
    
    if (isLastObject && prevIsDate ||
        prevIsDate && [[cellMap objectAtIndex:index] isKindOfClass:[NSDate class]]) {
        [cellMap removeObjectAtIndex:prevIndex];
        numberOfObjectsRemoved = 2;
    }
    return numberOfObjectsRemoved;
}

- (void)clearAll {
    UIActionSheet *confirm = [[UIActionSheet alloc]
                              initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:NSLocalizedString(@"Clear Conversation", nil)
                              otherButtonTitles:nil];
	
	// use the same style as the nav bar
	confirm.actionSheetStyle = self.navigationController.navigationBar.barStyle;
    
    [confirm showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
//    [confirm showInView:self.view];
	[confirm release];
    
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case ClearConversationButtonIndex: {
            NSError *error;
            fetchedResultsController.delegate = nil;               // turn off delegate callbacks
            for (Message *message in [fetchedResultsController fetchedObjects]) {
                [managedObjectContext deleteObject:message];
            }
            if (![managedObjectContext save:&error]) {
                // TODO: Handle the error appropriately.
                NSLog(@"Delete message error %@, %@", error, [error userInfo]);
            }
            fetchedResultsController.delegate = self;              // reconnect after mass delete
            if (![fetchedResultsController performFetch:&error]) { // resync controller
                // TODO: Handle the error appropriately.
                NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
            }
            
            [cellMap removeAllObjects];
            [chatContent reloadData];
            
            [self setEditing:NO animated:NO];
            break;
		}
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"number of rows: %d", [cellMap count]);
    return [cellMap count];
}

static NSString *kMessageCell = @"MessageCell";

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIImageView *msgBackground;
    UILabel *msgText;
    
//    NSLog(@"cell for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    UITableViewCell *cell;
    
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

    } else {
 
    }
    
    //[cell_message setMessage: (Message *)object rightward: !([indexPath row] % 3)];
    
    cell_message.message = (Message *) object;
       
    // Mark message as read.
    // Let's instead do this (asynchronously) from loadView and iterate over all messages
    if (![(Message *)object read]) { // not read, so save as read
        [(Message *)object setRead:[NSNumber numberWithBool:YES]];
        NSError *error;
        if (![managedObjectContext save:&error]) {
            // TODO: Handle the error appropriately.
            NSLog(@"Save message as read error %@, %@", error, [error userInfo]);
        }
    }
    
    return cell_message;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[cellMap objectAtIndex:[indexPath row]] isKindOfClass:[Message class]];
//    return [[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] == kMessageCell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSObject *object = [cellMap objectAtIndex:[indexPath row]];
        if ([object isKindOfClass:[NSDate class]]) {
            return;
        }
        
//        NSLog(@"Delete %@", object);
        
        // Remove message from managed object context by index path.
        [managedObjectContext deleteObject:(Message *)object];
        NSError *error;
        if (![managedObjectContext save:&error]) {
            // TODO: Handle the error appropriately.
            NSLog(@"Delete message error %@, %@", error, [error userInfo]);
        }
    }
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
    CGSize size = [[(Message *)object text] sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 17.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) { // disable slide to delete
        return UITableViewCellEditingStyleDelete;
//        return 3; // used to work for check boxes
    }
    return UITableViewCellEditingStyleNone;
}

#pragma mark NSFetchedResultsController

- (void)fetchResults {
    if (fetchedResultsController) return;

    // Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    // Create the sort descriptors array.
    NSSortDescriptor *tsDesc = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:tsDesc, nil];
    [tsDesc release];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    
    // Create and initialize the fetchedResultsController.
    fetchedResultsController = [[NSFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                managedObjectContext:managedObjectContext
                                sectionNameKeyPath:nil /* one section */ cacheName:@"Message"];
    [fetchRequest release];
    
    fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![fetchedResultsController performFetch:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
    }
}    

#pragma mark NSFetchedResultsControllerDelegate

// // beginUpdates & endUpdates cause the cells to get mixed up when scrolling aggressively.
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [chatContent beginUpdates];
//}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSArray *indexPaths;
    
    switch(type) {
        case NSFetchedResultsChangeInsert: {
            NSUInteger cellCount = [cellMap count];
            
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:cellCount inSection:0];
            
            if ([self addMessage:anObject] == 1) {
//                NSLog(@"insert 1 row at index: %d", cellCount);
                indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath, nil];
            } else { // 2
//                NSLog(@"insert 2 rows at index: %d", cellCount);
                indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath,
                              [NSIndexPath indexPathForRow:cellCount+1 inSection:0], nil];
            }
            
            [chatContent insertRowsAtIndexPaths:indexPaths
                               withRowAnimation:UITableViewRowAnimationNone];
            [indexPaths release];
            [self scrollToBottomAnimated:YES];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            NSUInteger objectIndex = [cellMap indexOfObjectIdenticalTo:anObject];
            NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:objectIndex inSection:0];
            
            if ([self removeMessageAtIndex:objectIndex] == 1) {
//                NSLog(@"delete 1 row");
                indexPaths = [[NSArray alloc] initWithObjects:objectIndexPath, nil];
            } else { // 2
//                NSLog(@"delete 2 rows");
                indexPaths = [[NSArray alloc] initWithObjects:objectIndexPath,
                              [NSIndexPath indexPathForRow:objectIndex-1 inSection:0], nil];
            }
            
            [chatContent deleteRowsAtIndexPaths:indexPaths
                               withRowAnimation:UITableViewRowAnimationNone];
            [indexPaths release];
            break;
        }
    }
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
