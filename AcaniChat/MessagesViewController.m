#import <SocketRocket/SRWebSocket.h>
#import "MessagesViewController.h"
#import "PlaceholderTextView.h"
#import "Conversation.h"
#import "Message.h"
#import "UIView+CocoaPlant.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1   40
#define kChatBarHeight4   94
#define MessageFontSize   16
#define MESSAGE_TEXT_WIDTH_MAX 180

#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG 101
#define MESSAGE_TEXT_LABEL_TAG 102

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource,
UITextViewDelegate, NSFetchedResultsControllerDelegate, SRWebSocketDelegate> {
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat previousContentHeight; // TODO: Rename to _previousTextViewContentHeight
}
@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _messageBubbleGray = [[UIImage imageNamed:@"MessageBubbleGray"] stretchableImageWithLeftCapWidth:23 topCapHeight:15];
    _messageBubbleBlue = [[UIImage imageNamed:@"MessageBubbleBlue"] stretchableImageWithLeftCapWidth:15 topCapHeight:13];

    // Create _tableView to display messages.
    _tableView = [[UITableView alloc] initWithFrame:
                   CGRectMake(0, 0, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor colorWithRed:0.859 green:0.886 blue:0.929 alpha:1];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];

    // Create messageInputBar to contain _textView & _sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:
                                    CGRectMake(0, self.view.frame.size.height-kChatBarHeight1,
                                               self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    // TODO: Use resizableImageWithCapInsets: instead.
//    messageInputBar.image = [[UIImage imageNamed:@"ChatBar"]
//                             stretchableImageWithLeftCapWidth:18 topCapHeight:20];
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] // 8 x 40
                             resizableImageWithCapInsets:UIEdgeInsetsMake(19, 0, 20, 0)];

    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView =
    [[UIImageView alloc] initWithImage:
     [[UIImage imageNamed:@"MessageInputFieldBackground"] // 32 x 40
      resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 19, 16)]];
    messageInputBarBackgroundImageView.frame = CGRectMake(10, 0, 234, kChatBarHeight1);
    [messageInputBar addSubview:messageInputBarBackgroundImageView];

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
    [messageInputBar addSubview:_textView];

    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.clearsContextBeforeDrawing = NO;
    _sendButton.frame = CGRectMake(messageInputBar.frame.size.width - 70, 8, 64, 26);
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | // multi-line input
    UIViewAutoresizingFlexibleLeftMargin;                       // landscape
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13);
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] // 27 x 27
                                          resizableImageWithCapInsets:sendButtonEdgeInsets];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [_sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"]
                                     resizableImageWithCapInsets:sendButtonEdgeInsets]
                           forState:UIControlStateHighlighted];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1]
                            forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage)
         forControlEvents:UIControlEventTouchUpInside];
    _sendButton.enabled = NO;
    _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    [messageInputBar addSubview:_sendButton];

    [self.view addSubview:messageInputBar];
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

    _webSocket.delegate = nil;
    [_webSocket close];

    [super viewWillDisappear:animated];
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

#pragma mark - Save & Send Message

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
}

- (void)sendMessage {
    NSString *text = _textView.text;
    [self saveMessageWithText:text];
    [self scrollToBottomAnimated:YES];
    [_webSocket send:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[text] options:0 error:NULL] encoding:NSUTF8StringEncoding]];
    _textView.text = nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [((Message *)[self.fetchedResultsController objectAtIndexPath:indexPath]).text sizeWithFont:[UIFont systemFontOfSize:MessageFontSize] constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height + 17;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIImageView *messageBackgroundImageView;
    UILabel *messageTextLabel;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        // Create messageBackgroundImageView.
        messageBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        messageBackgroundImageView.clearsContextBeforeDrawing = NO;
        messageBackgroundImageView.tag = MESSAGE_BACKGROUND_IMAGE_VIEW_TAG;
        messageBackgroundImageView.backgroundColor = tableView.backgroundColor; // speeds scrolling
        [cell.contentView addSubview:messageBackgroundImageView];

        // Create messageTextLabel.
        messageTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        messageTextLabel.clearsContextBeforeDrawing = NO;
        messageTextLabel.tag = MESSAGE_TEXT_LABEL_TAG;
        messageTextLabel.backgroundColor = [UIColor clearColor];
        messageTextLabel.numberOfLines = 0;
        messageTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        messageTextLabel.font = [UIFont systemFontOfSize:MessageFontSize];
        [cell.contentView addSubview:messageTextLabel];
    } else {
        messageBackgroundImageView = (UIImageView *)[cell.contentView viewWithTag:MESSAGE_BACKGROUND_IMAGE_VIEW_TAG];
        messageTextLabel = (UILabel *)[cell.contentView viewWithTag:MESSAGE_TEXT_LABEL_TAG];
    }

    // Configure cell with message.
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    messageTextLabel.text = message.text;
    CGSize messageTextSize = [message.text sizeWithFont:messageTextLabel.font constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    if (indexPath.row % 3) { // right message
        messageBackgroundImageView.frame = CGRectMake(_tableView.frame.size.width-messageTextSize.width-34, MessageFontSize-13, messageTextSize.width+34, messageTextSize.height+12);
        messageBackgroundImageView.image = _messageBubbleBlue;
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        messageTextLabel.frame = CGRectMake(_tableView.frame.size.width-messageTextSize.width-22, MessageFontSize-9, messageTextSize.width+5, messageTextSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    } else {
        messageBackgroundImageView.frame = CGRectMake(0, MessageFontSize-13, messageTextSize.width+34, messageTextSize.height+12);
        messageBackgroundImageView.image = _messageBubbleGray;
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

        messageTextLabel.frame = CGRectMake(22, MessageFontSize-9, messageTextSize.width+5, messageTextSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }

    return cell;
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat contentHeight = textView.contentSize.height - MessageFontSize + 2;
    NSString *messageText = textView.text;

    //    NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
    //    NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right,
    //          textView.contentInset.bottom, textView.contentInset.left);
    //    NSLog(@"contentSize.height: %f", contentHeight);

//    if ([textView hasText]) {
//        rightTrimmedText = [textView.text stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
//
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
//    }

    // Enable/disable sendButton if messageText has/lacks length.
    if ([messageText length]) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
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

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
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
    NSArray *messages = [NSJSONSerialization JSONObjectWithData:
                         [message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    for (NSString *text in messages) {
        [self saveMessageWithText:text];
    }
    [self scrollToBottomAnimated:YES];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket closed");
    self.title = @"Connection Closed! (see logs)";
    self.webSocket = nil;
}

@end
