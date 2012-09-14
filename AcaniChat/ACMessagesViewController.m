#import <MessageUI/MessageUI.h>
#import "AcaniChatDefines.h"
#import "ACAppDelegate.h"
#import "ACMessagesViewController.h"
#import "ACPlaceholderTextView.h"
#import "ACConversation.h"
#import "ACMessage.h"
#import "UIView+CocoaPlant.h"

// TODO: Rename to CHAT_BAR_HEIGHT_1, etc.
#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define SentDateFontSize                     13
#define MESSAGE_SENT_DATE_LABEL_HEIGHT       (SentDateFontSize+7)
#define MessageFontSize                      16
#define MESSAGE_TEXT_WIDTH_MAX               180
#define MESSAGE_MARGIN_TOP                   7
#define MESSAGE_MARGIN_BOTTOM                10
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define ContentHeightMax                     80
#define MESSAGE_COUNT_LIMIT                  50
#define MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL 13*60 // 13 minutes
#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG    101
#define MESSAGE_TEXT_LABEL_TAG               102

#define MESSAGE_TEXT_SIZE_WITH_FONT(message, font) \
[message.text sizeWithFont:font constrainedToSize:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap]

#define UIKeyboardNotificationsObserve() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil]
//[notificationCenter addObserver:self selector:@selector(keyboardDidShow:)  name:UIKeyboardDidShowNotification  object:nil]; \
//[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil]; \
//[notificationCenter addObserver:self selector:@selector(keyboardDidHide:)  name:UIKeyboardDidHideNotification  object:nil]

#define UIKeyboardNotificationsUnobserve() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

@interface ACMessagesViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, NSFetchedResultsControllerDelegate> {
    NSMutableArray *_heightForRow;
    UIImage *_messageBubbleGray;
    UIImage *_messageBubbleBlue;
    CGFloat _previousTextViewContentHeight;
    NSDate *_previousShownSentDate;
}
@end

@implementation ACMessagesViewController

#pragma mark - NSObject

- (void)dealloc {
    UIKeyboardNotificationsUnobserve();
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _heightForRow = [NSMutableArray arrayWithCapacity:MESSAGE_COUNT_LIMIT+3]; // +3 in case I send/receive more messages

    _messageBubbleGray = [[UIImage imageNamed:@"MessageBubbleGray"] stretchableImageWithLeftCapWidth:23 topCapHeight:15];
    _messageBubbleBlue = [[UIImage imageNamed:@"MessageBubbleBlue"] stretchableImageWithLeftCapWidth:15 topCapHeight:13];

    // Create _tableView to display messages.
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-kChatBarHeight1)];
    _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor colorWithRed:0.859 green:0.886 blue:0.929 alpha:1];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];

    // Create messageInputBar to contain _textView, messageInputBarBackgroundImageView, & _sendButton.
    UIImageView *messageInputBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kChatBarHeight1, self.view.frame.size.width, kChatBarHeight1)];
    messageInputBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    messageInputBar.opaque = YES;
    messageInputBar.userInteractionEnabled = YES; // makes subviews tappable
    messageInputBar.image = [[UIImage imageNamed:@"MessageInputBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(19, 3, 19, 3)]; // 8 x 40

    // Create _textView to compose messages.
    // TODO: Shrink cursor height by 1 px on top & 1 px on bottom.
    _textView = [[ACPlaceholderTextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_X, TEXT_VIEW_Y, TEXT_VIEW_WIDTH, TEXT_VIEW_HEIGHT_MIN)];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor colorWithWhite:245/255.0f alpha:1];
    _textView.scrollIndicatorInsets = UIEdgeInsetsMake(13, 0, 8, 6);
    _textView.scrollsToTop = NO;
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
    [messageInputBar addSubview:_sendButton];

    [self.view addSubview:messageInputBar];

    if (_conversation.draft) {
        _textView.text = _conversation.draft;
        UIKeyboardNotificationsObserve();
        [_textView becomeFirstResponder];
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIKeyboardNotificationsObserve();
    [_tableView flashScrollIndicators];
    _conversation.unreadMessagesCount = @((NSUInteger)0);
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    MOCSave(_managedObjectContext);
}

- (void)viewWillDisappear:(BOOL)animated {
    UIKeyboardNotificationsUnobserve(); // as soon as possible
    _conversation.draft = ([_textView.text length] ? _textView.text: nil);
    MOCSave(_managedObjectContext);
    [super viewWillDisappear:animated];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
#endif

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect frameEnd;
    NSDictionary *userInfo = [notification userInfo];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&frameEnd];

//    NSLog(@"animationDuration: %f", animationDuration); // TODO: Why 0.35 on viewDidLoad?
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
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - Save/Send/Receive Messages

- (void)sendMessage {
    // Autocomplete text before sending. @hack
    [_textView resignFirstResponder];
    [_textView becomeFirstResponder];

    // Send message.
    // TODO: Prevent this message from getting saved to Core Data if I hit back.
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:_managedObjectContext];
    _conversation.lastMessageSentDate = message.sentDate = [NSDate date];
    _conversation.lastMessageText = message.text = _textView.text;
    [_conversation addMessagesObject:message];

    [AC_APP_DELEGATE() sendMessage:message];

    _textView.text = nil;
    [self textViewDidChange:_textView];
}

#pragma mark - UITableViewDelegate

// UITableView calls this method in sequence for all the cells.
// Store details in _heightForRow to use with cellForRow.
// TODO: Also try only storing showSentDate NSUInteger enum (0:?, 1:YES, 2:NO) @property on each
// Message object. Clean. Still fast?
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"heightForRowAtIndexPath: %@", indexPath);

    ACMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    NSArray *messageDetails = nil;
    if ([_heightForRow count] > indexPath.row) {
        messageDetails = _heightForRow[indexPath.row];
    }

    CGFloat messageSentDateLabelHeight = 0;
    CGFloat messageTextLabelHeight;
    if (messageDetails) {
        messageSentDateLabelHeight = [messageDetails[0] floatValue];
        messageTextLabelHeight = [messageDetails[1] CGSizeValue].height;
    } else {
        if ((!_previousShownSentDate || [message.sentDate timeIntervalSinceDate:_previousShownSentDate] > MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL)) {
            _previousShownSentDate = message.sentDate;
            messageSentDateLabelHeight = MESSAGE_SENT_DATE_LABEL_HEIGHT;
        }
        CGSize messageTextLabelSize = MESSAGE_TEXT_SIZE_WITH_FONT(message, [UIFont systemFontOfSize:MessageFontSize]);
        messageTextLabelHeight = messageTextLabelSize.height;

        _heightForRow[indexPath.row] = @[@(messageSentDateLabelHeight), [NSValue valueWithCGSize:messageTextLabelSize]];
    }

    return messageSentDateLabelHeight+messageTextLabelHeight+MESSAGE_MARGIN_TOP+MESSAGE_MARGIN_BOTTOM;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"cellForRowAtIndexPath: %@", indexPath);

    NSArray *messageDetails = _heightForRow[indexPath.row];
    CGFloat messageSentDateLabelHeight = [messageDetails[0] floatValue];
    CGSize messageTextLabelSize = [messageDetails[1] CGSizeValue];

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
        messageSentDateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        messageSentDateLabel.tag = MESSAGE_SENT_DATE_LABEL_TAG;
        messageSentDateLabel.backgroundColor = tableView.backgroundColor;          // speeds scrolling
        messageSentDateLabel.textColor = [UIColor grayColor];
        messageSentDateLabel.textAlignment = UITextAlignmentCenter;
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
    ACMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Configure messageSentDateLabel.
    if (messageSentDateLabelHeight) {
        //    // TODO: Support other language date formats. (Native iPhone Messages.app doesn't.)
        //    static NSDateFormatter *dateFormatter = nil;
        //    if (dateFormatter == nil) {
        //        dateFormatter = [[NSDateFormatter alloc] init];
        //        [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; // Jan 1, 2010
        //        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];  // 1:43 PM
        //    }
        //    messageSentDateLabel.text = [dateFormatter stringFromDate:message.sentDate];

        char buffer[22]; // Sep 22, 2012 12:15 PM -- 21 chars + 1 for NUL terminator \0
        time_t time = [message.sentDate timeIntervalSince1970];
        strftime(buffer, 22, "%b %-e, %Y %-l:%M %p", localtime(&time));
        messageSentDateLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    } else {
        messageSentDateLabel.text = nil;
    }

    // Configure messageBackgroundImageView & messageTextLabel.
    messageTextLabel.text = message.text;
    if (indexPath.row % 3) { // right message
        messageBackgroundImageView.frame = CGRectMake(_tableView.frame.size.width-messageTextLabelSize.width-34, messageSentDateLabelHeight+MessageFontSize-13, messageTextLabelSize.width+34, messageTextLabelSize.height+12);
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        messageBackgroundImageView.image = _messageBubbleBlue;

        messageTextLabel.frame = CGRectMake(_tableView.frame.size.width-messageTextLabelSize.width-22, messageSentDateLabelHeight+MessageFontSize-9, messageTextLabelSize.width+5, messageTextLabelSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    } else {
        messageBackgroundImageView.frame = CGRectMake(0, messageSentDateLabelHeight+MessageFontSize-13, messageTextLabelSize.width+34, messageTextLabelSize.height+12);
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        messageBackgroundImageView.image = _messageBubbleGray;

        messageTextLabel.frame = CGRectMake(22, messageSentDateLabelHeight+MessageFontSize-9, messageTextLabelSize.width+5, messageTextLabelSize.height);
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ACMessage"];
    NSError __autoreleasing *error = nil;
    NSUInteger messagesCount = [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSAssert(messagesCount != NSNotFound, @"-[NSManagedObjectContext countForFetchRequest:error:] error:\n\n%@", error);
    if (messagesCount > MESSAGE_COUNT_LIMIT) {
        [fetchRequest setFetchOffset:messagesCount-MESSAGE_COUNT_LIMIT];
    }
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES]]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"ACMessage"];
    _fetchedResultsController.delegate = self;
    NSAssert([_fetchedResultsController performFetch:&error], @"-[NSFetchedResultsController performFetch:] error:\n\n%@", error);
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
    [self scrollToBottomAnimated:YES];
}

@end
