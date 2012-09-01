#import <SocketRocket/SRWebSocket.h>
#import "MessagesViewController.h"
#import "PlaceholderTextView.h"
#import "Conversation.h"
#import "Message.h"
#import "UIView+CocoaPlant.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1        40
#define kChatBarHeight4        94
#define MessageFontSize        16
#define MESSAGE_TEXT_WIDTH_MAX 180
#define TEXT_VIEW_X            7   // 40  (with CameraButton)
#define TEXT_VIEW_Y            2
#define TEXT_VIEW_WIDTH        249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN   90
#define ContentHeightMax       80

#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG 101
#define MESSAGE_TEXT_LABEL_TAG 102

#define ObserveKeyboardWillShowOrHide() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil]
//[notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil]

#define UnobserveKeyboardWillShowOrHide() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource,
UITextViewDelegate, NSFetchedResultsControllerDelegate, SRWebSocketDelegate> {
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
//    BOOL _rotating;
}
@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIViewAutoresizing UIViewAutoresizingFlexibleWidthAndHeight = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

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
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidthAndHeight;
    [self.view addSubview:_tableView];

    // Create messageInputBar to contain _textView, messageInputBarBackgroundImageView, & _sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] // 8 x 40
                             resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)];

    // Create _textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    _textView = [[PlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, TEXT_VIEW_WIDTH, TEXT_VIEW_HEIGHT_MIN)];
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    _textView.font = [UIFont systemFontOfSize:MessageFontSize];
    _textView.placeholder = NSLocalizedString(@" Message", nil);
    [messageInputBar addSubview:_textView];
    _previousTextViewContentHeight = MessageFontSize+20;

    // Create messageInputBarBackgroundImageView as subview of messageInputBar.
    UIImageView *messageInputBarBackgroundImageView =
    [[UIImageView alloc] initWithImage:
     [[UIImage imageNamed:@"MessageInputFieldBackground"] // 32 x 40
      resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]];
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, TEXT_VIEW_WIDTH+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidthAndHeight;
    [messageInputBar addSubview:messageInputBarBackgroundImageView];

    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(messageInputBar.frame.size.width-65, 8, 59, 26);
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

- (void)viewWillAppear:(BOOL)animated {
    UIView *messageInputBar = _textView.superview;
    messageInputBar.frame = CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, messageInputBar.frame.size.width, messageInputBar.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ObserveKeyboardWillShowOrHide();
    [self _reconnect];
}

- (void)viewWillDisappear:(BOOL)animated {
    UnobserveKeyboardWillShowOrHide(); // as soon as possible

    _webSocket.delegate = nil;
    [_webSocket close];

    [super viewWillDisappear:animated];
}

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
////    _rotating = YES;
//}
//
//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
////    _textView.superview.frame =
//}
//
//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
////    _rotating = NO;
//}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
//    if (_rotating) return;

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
         UIView *messageInputBar = _textView.superview;
         UIViewSetFrameY(messageInputBar, viewHeight-messageInputBar.frame.size.height);
         _tableView.contentInset = _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height-viewHeight, 0);
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
        messageBackgroundImageView.tag = MESSAGE_BACKGROUND_IMAGE_VIEW_TAG;
        messageBackgroundImageView.backgroundColor = tableView.backgroundColor; // speeds scrolling
        [cell.contentView addSubview:messageBackgroundImageView];

        // Create messageTextLabel.
        messageTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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
    // Change height of _tableView & messageInputBar to match textView's content height.
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
    //    NSLog(@"textViewContentHeight: %f", textViewContentHeight);

    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }

    if (changeInHeight) {
        [UIView animateWithDuration:0.2 animations:^{
            _tableView.contentInset = _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, _tableView.contentInset.bottom+changeInHeight, 0);
            [self scrollToBottomAnimated:NO];
            UIView *messageInputBar = _textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
        } completion:^(BOOL finished) {
            [_textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
    }

    // Enable/disable sendButton if textView.text has/lacks length.
    if ([textView.text length]) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    }
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
