#import <SocketRocket/SRWebSocket.h>
#import "MessagesViewController.h"
#import "PlaceholderTextView.h"
#import "Conversation.h"
#import "Message.h"
#import "NSString+CocoaPlant.h"
#import "UIView+CocoaPlant.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1  40
#define kChatBarHeight4  94
#define MessageFontSize 16

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource,
UITextViewDelegate, NSFetchedResultsControllerDelegate, SRWebSocketDelegate> {
    CGFloat previousContentHeight; // TODO: Rename to _previousTextViewContentHeight
}
@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Create _tableView to display messages.
    _tableView = [[UITableView alloc] initWithFrame:
                   CGRectMake(0, 0, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor colorWithRed:0.859 green:0.886 blue:0.929 alpha:1];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.view addSubview:_tableView];

    // Create chatBar to contain _textView & _sendButton.
    UIImageView *chatBar = [[UIImageView alloc] initWithFrame:
                            CGRectMake(0, self.view.frame.size.height-kChatBarHeight1,
                                       self.view.frame.size.width, kChatBarHeight1)];
    chatBar.userInteractionEnabled = YES; // makes subviews tappable
    chatBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    // TODO: Use resizableImageWithCapInsets: instead.
    chatBar.image = [[UIImage imageNamed:@"ChatBar.png"]
                     stretchableImageWithLeftCapWidth:18 topCapHeight:20];

    // Create _textView to compose messages.
    _textView = [[PlaceholderTextView alloc] initWithFrame:CGRectMake(10, 9, 234, 22)];
    _textView.delegate = self;
    _textView.contentSize = CGSizeMake(234, 22);
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.scrollEnabled = NO; // not initially
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 4, -2);
    _textView.clearsContextBeforeDrawing = NO;
    _textView.font = [UIFont systemFontOfSize:MessageFontSize];
    _textView.dataDetectorTypes = UIDataDetectorTypeAll;
    _textView.backgroundColor = [UIColor clearColor];
    previousContentHeight = _textView.contentSize.height;
    [chatBar addSubview:_textView];

    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.clearsContextBeforeDrawing = NO;
    _sendButton.frame = CGRectMake(chatBar.frame.size.width - 70, 8, 64, 26);
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | // multi-line input
    UIViewAutoresizingFlexibleLeftMargin;                       // landscape
    UIImage *sendButtonBackground = [UIImage imageNamed:@"SendButton.png"];
    [_sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateDisabled];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1]
                            forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage)
         forControlEvents:UIControlEventTouchUpInside];
    //    // The following three lines aren't necessary now that we'are using background image.
    //    _sendButton.backgroundColor = [UIColor clearColor];
    //    _sendButton.layer.cornerRadius = 13;
    //    _sendButton.clipsToBounds = YES;
    [self resetSendButton]; // disable initially
    [chatBar addSubview:_sendButton];

    [self.view addSubview:chatBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Observe UIKeyboard with keyboardWillShowOrHide:.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:)
                               name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:)
                               name:UIKeyboardWillHideNotification object:nil];

    [self _reconnect];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Unobserve UIKeyboard as soon as possible.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [_tableView setEditing:editing animated:YES];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];

    [UIView
     animateWithDuration:animationDuration delay:0.0
     options:UIViewAnimationOptionsFromCurve(animationCurve) animations:^{
         CGFloat viewHeight = [self.view convertRect:frameEnd fromView:nil].origin.y;
         UIView *chatBar = _textView.superview;
         UIViewSetFrameY(chatBar, viewHeight-chatBar.frame.size.height);
         _tableView.contentInset =
         _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-
                                                             viewHeight, 0);
         [self scrollToBottomAnimated:NO];
     } completion:nil];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = [_tableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - Enable, Disable, Reset sendButton

- (void)enableSendButton {
    if (!_sendButton.enabled) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    }
}

- (void)disableSendButton {
    if (_sendButton.enabled) {
        [self resetSendButton];
    }
}

- (void)resetSendButton {
    _sendButton.enabled = NO;
    _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
}

- (void)saveMessageWithText:(NSString *)text {
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                     inManagedObjectContext:_managedObjectContext];
    message.read = [NSNumber numberWithBool:YES];
    message.sentDate = [NSDate date];
    message.text = text;
    [_conversation addMessagesObject:message];

    // Save the context.
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [self scrollToBottomAnimated:YES];
}

- (void)sendMessage {
    NSString *text = _textView.text;
    [self saveMessageWithText:text];
    [_webSocket send:text];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = message.text;
    cell.detailTextLabel.text = [message.sentDate description];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat contentHeight = textView.contentSize.height - MessageFontSize + 2;
    NSString *rightTrimmedText = @"";

    //    NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
    //    NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right,
    //          textView.contentInset.bottom, textView.contentInset.left);
    //    NSLog(@"contentSize.height: %f", contentHeight);

    if ([textView hasText]) {
        rightTrimmedText = [textView.text stringByTrimmingTrailingWhitespaceAndNewlineCharacters];

        //        if (textView.text.length > 1024) { // truncate text to 1024 chars
        //            textView.text = [textView.text substringToIndex:1024];
        //        }

//        // Resize textView to contentHeight
//        if (contentHeight != previousContentHeight) {
//            if (contentHeight <= ContentHeightMax) { // limit chatInputHeight <= 4 lines
//                CGFloat commentBarHeight = contentHeight + 18;
//                [self setCommentBarHeight:commentBarHeight];
//                if (previousContentHeight > ContentHeightMax) {
//                    textView.scrollEnabled = NO;
//                }
//                TextViewFixQuirk(); // fix quirk
//                //                textView.contentInset = UIEdgeInsetsMake(3, 0, 0, 0);
//            } else if (previousContentHeight <= ContentHeightMax) { // grow
//                textView.scrollEnabled = YES;
//                textView.contentOffset = CGPointMake(0, contentHeight-70); // shift to bottom
//                if (previousContentHeight < ContentHeightMax) {
//                    [self expandCommentBarHeight];
//                }
//            } else {
//                textView.contentInset = UIEdgeInsetsMake(0, 0, -5, 0);
//                textView.contentOffset = CGPointMake(0, contentHeight-70);
//            }
//        }
//    } else { // textView is empty
//        [self resetText];
    }

    // Enable sendButton if chatInput has non-blank text, disable otherwise.
    if (rightTrimmedText.length > 0) {
        [self enableSendButton];
    } else {
        [self disableSendButton];
    }

    previousContentHeight = contentHeight;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Message"
                                        inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES]]];

    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    _fetchedResultsController.delegate = self;

	NSError *error = nil;
	if (![_fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - SRWebSocketDelegate

- (void)_reconnect {
    _webSocket.delegate = nil;
    [_webSocket close];

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOST]]];
    _webSocket.delegate = self;

    self.title = @"Opening Connection...";
    [_webSocket open];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Websocket Connected");
    self.title = @"Connected!";
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@":( Websocket Failed With Error %@", error);

    self.title = @"Connection Failed! (see logs)";
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Received \"%@\"", message);
    [self saveMessageWithText:message];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket closed");
    self.title = @"Connection Closed! (see logs)";
    self.webSocket = nil;
}

@end
