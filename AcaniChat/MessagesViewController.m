#import "AcaniChatDefines.h"
#import "AppDelegate.h"
#import "MessagesViewController.h"
#import "PlaceholderTextView.h"
#import "Conversation.h"
#import "Message.h"
#import "UIView+CocoaPlant.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1              40
#define kChatBarHeight4              94
#define SentDateFontSize             13
#define MESSAGE_SENT_DATE_LABEL_HEIGHT  (SentDateFontSize+7)
#define MessageFontSize              16
#define MESSAGE_TEXT_WIDTH_MAX       180
#define TEXT_VIEW_X                  7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                  2
#define TEXT_VIEW_WIDTH              249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN         90
#define ContentHeightMax             80

#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG 101
#define MESSAGE_TEXT_LABEL_TAG            102

#define ObserveKeyboardWillShowOrHide() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil]
//[notificationCenter addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil]

#define UnobserveKeyboardWillShowOrHide() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, NSFetchedResultsControllerDelegate> {
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
    BOOL _rotating;
}
@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _messageBubbleGray = [[UIImage imageNamed:@"MessageBubbleGray"] stretchableImageWithLeftCapWidth:23 topCapHeight:15];
    _messageBubbleBlue = [[UIImage imageNamed:@"MessageBubbleBlue"] stretchableImageWithLeftCapWidth:15 topCapHeight:13];

    // Create _tableView to display messages.
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor colorWithRed:0.859 green:0.886 blue:0.929 alpha:1];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:_tableView];

    // Create messageInputBar to contain _textView, messageInputBarBackgroundImageView, & _sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.opaque = YES;
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)]; // 8 x 40

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
    UIImageView *messageInputBarBackgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"MessageInputFieldBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 12, 18, 18)]]; // 32 x 40
    messageInputBarBackgroundImageView.frame = CGRectMake(TEXT_VIEW_X-2, 0, TEXT_VIEW_WIDTH+2, kChatBarHeight1);
    messageInputBarBackgroundImageView.autoresizingMask = _tableView.autoresizingMask;
    [messageInputBar addSubview:messageInputBarBackgroundImageView];

    // Create sendButton.
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(messageInputBar.frame.size.width-65, 8, 59, 26);
    _sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin /* multiline input */ | UIViewAutoresizingFlexibleLeftMargin /* landscape */);
    UIEdgeInsets sendButtonEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13); // 27 x 27
    UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:@"SendButton"] resizableImageWithCapInsets:sendButtonEdgeInsets];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackgroundImage forState:UIControlStateDisabled];
    [_sendButton setBackgroundImage:[[UIImage imageNamed:@"SendButtonHighlighted"] resizableImageWithCapInsets:sendButtonEdgeInsets] forState:UIControlStateHighlighted];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleShadowColor:[UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1] forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    _sendButton.enabled = NO;
    _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    [messageInputBar addSubview:_sendButton];

    [self.view addSubview:messageInputBar];
}

- (void)viewWillAppear:(BOOL)animated {
    UIView *messageInputBar = _textView.superview;
    messageInputBar.frame = CGRectMake(0, self.view.frame.size.height-messageInputBar.frame.size.height, messageInputBar.frame.size.width, messageInputBar.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ObserveKeyboardWillShowOrHide();
}

- (void)viewWillDisappear:(BOOL)animated {
    UnobserveKeyboardWillShowOrHide(); // as soon as possible
    [super viewWillDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"willRotateToInterfaceOrientation");
    _rotating = YES;
}

//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    UIView *messageInputBar = _textView.superview;
//    messageInputBar.frame = CGRectMake(0, 112-messageInputBar.frame.size.height, messageInputBar.frame.size.width, messageInputBar.frame.size.height);
//}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"didRotateFromInterfaceOrientation");
    _rotating = NO;
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    NSLog(@"rotating: %d notification: %@", _rotating, notification);

    if (_rotating) return;

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];

    [UIView animateWithDuration:animationDuration delay:0.0 options:(UIViewAnimationOptionsFromCurve(animationCurve) | UIViewAnimationOptionBeginFromCurrentState) animations:^{
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

#pragma mark - Save/Send/Receive Messages

- (void)sendMessage {
    NSString *text = _textView.text;
    AppDelegate *appDelegate = APP_DELEGATE();
    [appDelegate saveMessageWithText:text];
    [self scrollToBottomAnimated:YES];
    [appDelegate sendText:text];
    _textView.text = nil;
    [self textViewDidChange:_textView];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [((Message *)[self.fetchedResultsController objectAtIndexPath:indexPath]).text sizeWithFont:[UIFont systemFontOfSize:MessageFontSize] constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height + 17 + MESSAGE_SENT_DATE_LABEL_HEIGHT;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *messageSentDateLabel;
    UIImageView *messageBackgroundImageView;
    UILabel *messageTextLabel;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        // Create messageSentDateLabel.
        messageSentDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(-2, 0, tableView.frame.size.width, SentDateFontSize+5)];
        messageSentDateLabel.tag = MESSAGE_SENT_DATE_LABEL_TAG;
        messageSentDateLabel.backgroundColor = tableView.backgroundColor;          // speeds scrolling
        messageSentDateLabel.textColor = [UIColor grayColor];
        messageSentDateLabel.textAlignment = UITextAlignmentCenter;
        messageSentDateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        messageSentDateLabel.font = [UIFont boldSystemFontOfSize:SentDateFontSize];
        [cell.contentView addSubview:messageSentDateLabel];

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
        messageSentDateLabel = (UILabel *)[cell.contentView viewWithTag:MESSAGE_SENT_DATE_LABEL_TAG];
        messageBackgroundImageView = (UIImageView *)[cell.contentView viewWithTag:MESSAGE_BACKGROUND_IMAGE_VIEW_TAG];
        messageTextLabel = (UILabel *)[cell.contentView viewWithTag:MESSAGE_TEXT_LABEL_TAG];
    }

    // Configure cell with message.
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Configure messageSentDateLabel.
//    // TODO: Support other language date formats. (Native iPhone Messages.app doesn't.)
//    static NSDateFormatter *dateFormatter = nil;
//    if (dateFormatter == nil) {
//        dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; // Jan 1, 2010
//        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];  // 1:43 PM
//    }
//    messageSentDateLabel.text = [dateFormatter stringFromDate:message.sentDate];
    char buffer[22]; // Sep 22, 2012 12:15 PM -- 21 chars + 1 for NUL terminator \0
    time_t time = [message.sentDate timeIntervalSince1970] - [[NSTimeZone localTimeZone] secondsFromGMT];
    strftime(buffer, 22, "%b %e, %Y %l:%M %p", localtime(&time));
    messageSentDateLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    // Don't proceed %e with blank for single-digit days. @hack
    // http://stackoverflow.com/questions/12254862/strftime-no-blank-before-e-single-digit-days
    NSMutableString *sentDateLabelText = [NSMutableString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    if ([sentDateLabelText characterAtIndex:4] == ' ') {
        [sentDateLabelText deleteCharactersInRange:NSMakeRange(4, 1)];
    }
    messageSentDateLabel.text = sentDateLabelText;

    // Configure messageBackgroundImageView & messageTextLabel.
    messageTextLabel.text = message.text;
    CGSize messageTextSize = [message.text sizeWithFont:messageTextLabel.font constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    if (indexPath.row % 3) { // right message
        messageBackgroundImageView.frame = CGRectMake(_tableView.frame.size.width-messageTextSize.width-34, MESSAGE_SENT_DATE_LABEL_HEIGHT+MessageFontSize-13, messageTextSize.width+34, messageTextSize.height+12);
        messageBackgroundImageView.image = _messageBubbleBlue;
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        messageTextLabel.frame = CGRectMake(_tableView.frame.size.width-messageTextSize.width-22, MESSAGE_SENT_DATE_LABEL_HEIGHT+MessageFontSize-9, messageTextSize.width+5, messageTextSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    } else {
        messageBackgroundImageView.frame = CGRectMake(0, MESSAGE_SENT_DATE_LABEL_HEIGHT+MessageFontSize-13, messageTextSize.width+34, messageTextSize.height+12);
        messageBackgroundImageView.image = _messageBubbleGray;
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

        messageTextLabel.frame = CGRectMake(22, MESSAGE_SENT_DATE_LABEL_HEIGHT+MessageFontSize-9, messageTextSize.width+5, messageTextSize.height);
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
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Message" inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES]]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"Message"];
    _fetchedResultsController.delegate = self;
    FRCPerformFetch(_fetchedResultsController);
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

@end
