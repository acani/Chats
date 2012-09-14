#import <MessageUI/MessageUI.h>
#import "AcaniChatDefines.h"
#import "ACConversationsTableViewController.h"
#import "ACMessagesViewController.h"
#import "ACConversation.h"
#import "ACUser.h"

#define UNREAD_DOT_IMAGE_VIEW_TAG              100
#define LAST_MESSAGE_TEXT_LABEL_TAG            101
#define LAST_MESSAGE_SENT_DATE_LABEL_TAG       102
#define USERS_NAMES_LABEL_TAG                  103

#define LAST_MESSAGE_TEXT_FONT_SIZE            14
#define LAST_MESSAGE_SENT_DATE_FONT_SIZE       14
#define LAST_MESSAGE_SENT_DATE_AM_PM_FONT_SIZE 12
#define USERS_NAMES_FONT_SIZE                  16

@interface ACConversationsTableViewController () <NSFetchedResultsControllerDelegate> // , MFMessageComposeViewControllerDelegate>
@end

@implementation ACConversationsTableViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 61;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
#endif

//#pragma mark - Actions
//
//- (void)composeAction {
//    if ([MFMessageComposeViewController canSendText]) {
//        MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
//        messageComposeViewController.messageComposeDelegate = self;
//        messageComposeViewController.body = NSLocalizedString(@"Send this text for fun.", nil);
//        messageComposeViewController.recipients = @[@"16178940859"];
//        [self presentViewController:messageComposeViewController animated:YES completion:nil];
//    } else {
//        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Send Text", nil) message:NSLocalizedString(@"Please use a device that can send text messages.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
//    }
//}
//
//#pragma mark - MFMessageComposeViewControllerDelegate
//
//- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
////    switch (result) {
////        case MessageComposeResultCancelled:
////            break;
////        case MessageComposeResultSent:
////            break;
////        case MessageComposeResultFailed:
////            break;
////    }
//    dumpViews([[UIApplication sharedApplication].windows objectAtIndex:1], @"", @"");
////    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//void dumpViews(UIView *view, NSString *text, NSString *indent) {
//    if (![text length])
//        NSLog(@"%@", view);
//    else
//        NSLog(@"%@ %@", text, view);
//
//    for (NSUInteger i = 0; i < [view.subviews count]; i++) {
//        UIView *subView = [view.subviews objectAtIndex:i];
//        NSString *newIndent = [[NSString alloc] initWithFormat:@"  %@", indent];
//        NSString *msg = [[NSString alloc] initWithFormat:@"%@%d:", newIndent, i];
//        dumpViews(subView, msg, newIndent);
//    }
//}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.title = NSLocalizedString(@"Messages", nil);
    ACMessagesViewController *messagesViewController = [[ACMessagesViewController alloc] initWithNibName:nil bundle:nil];
    ACConversation *conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    messagesViewController.title = ((ACUser *)[conversation.users anyObject]).name;
    messagesViewController.conversation = conversation;
    messagesViewController.managedObjectContext = _managedObjectContext;
    [self.navigationController pushViewController:messagesViewController animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // Create unreadDotImageView.
        UIImageView *unreadDotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UnreadBullet"] highlightedImage:[UIImage imageNamed:@"UnreadBulletHighlighted"]];
        unreadDotImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        unreadDotImageView.tag = UNREAD_DOT_IMAGE_VIEW_TAG;
        unreadDotImageView.backgroundColor = tableView.backgroundColor;       // speeds scrolling
        unreadDotImageView.center = CGPointMake(16, 31);
        [cell.contentView addSubview:unreadDotImageView];

        // Create lastMessageTextLabel.
        UILabel *lastMessageTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        lastMessageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lastMessageTextLabel.tag = LAST_MESSAGE_TEXT_LABEL_TAG;
        lastMessageTextLabel.backgroundColor = tableView.backgroundColor;     // speeds scrolling
        lastMessageTextLabel.textColor = [UIColor grayColor];
        lastMessageTextLabel.highlightedTextColor = [UIColor whiteColor];
        lastMessageTextLabel.font = [UIFont systemFontOfSize:LAST_MESSAGE_TEXT_FONT_SIZE];
        lastMessageTextLabel.numberOfLines = 2;
        [cell.contentView addSubview:lastMessageTextLabel];

        // Create lastMessageSentDateLabel.
        UILabel *lastMessageSentDateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        lastMessageSentDateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        lastMessageSentDateLabel.tag = LAST_MESSAGE_SENT_DATE_LABEL_TAG;
        lastMessageSentDateLabel.backgroundColor = tableView.backgroundColor; // speeds scrolling
        lastMessageSentDateLabel.textColor = [UIColor colorWithRed:52/255.0f green:111/255.0f blue:212/255.0f alpha:1];
        lastMessageSentDateLabel.highlightedTextColor = [UIColor whiteColor];
        lastMessageSentDateLabel.textAlignment = UITextAlignmentRight;
        [cell.contentView addSubview:lastMessageSentDateLabel];

        // Create usersNamesLabel.
        UILabel *usersNamesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        usersNamesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        usersNamesLabel.tag = USERS_NAMES_LABEL_TAG;
        usersNamesLabel.backgroundColor = tableView.backgroundColor;          // speeds scrolling
        usersNamesLabel.highlightedTextColor = [UIColor whiteColor];
        usersNamesLabel.font = [UIFont boldSystemFontOfSize:USERS_NAMES_FONT_SIZE];
        [cell.contentView addSubview:usersNamesLabel];
    }
    [self tableView:tableView configureCell:cell withConversation:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    return cell;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell withConversation:(ACConversation *)conversation {
    // Configure unreadDotImageView.
    [cell.contentView viewWithTag:UNREAD_DOT_IMAGE_VIEW_TAG].hidden = ![conversation.unreadMessagesCount boolValue];

    // Configure lastMessageTextLabel.
    UILabel *lastMessageTextLabel = (UILabel *)[cell.contentView viewWithTag:LAST_MESSAGE_TEXT_LABEL_TAG];
    CGFloat lastMessageTextLabelWidth = cell.contentView.frame.size.width-31-7;
    lastMessageTextLabel.frame = CGRectMake(31, 22, lastMessageTextLabelWidth, (([conversation.lastMessageText sizeWithFont:lastMessageTextLabel.font].width > lastMessageTextLabelWidth) ? 36 : 18));
    lastMessageTextLabel.text = conversation.lastMessageText;

    // Configure lastMessageSentDateLabel.
    UILabel *lastMessageSentDateLabel = (UILabel *)[cell.contentView viewWithTag:LAST_MESSAGE_SENT_DATE_LABEL_TAG];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
    [dateComponents setDay:dateComponents.day-1];
    NSDate *yesterday = [calendar dateFromComponents:dateComponents];
    [dateComponents setDay:dateComponents.day-1];
    NSDate *twoDaysAgo = [calendar dateFromComponents:dateComponents];
    [dateComponents setDay:dateComponents.day-5];
    NSDate *lastWeek = [calendar dateFromComponents:dateComponents];

    NSDate *lastMessageSentDate = conversation.lastMessageSentDate;
    if ([lastMessageSentDate compare:yesterday] == NSOrderedDescending) {
        char buffer[9]; // 12:15 PM -- 8 chars + 1 for NUL terminator \0
        time_t time = [lastMessageSentDate timeIntervalSince1970];
        strftime(buffer, 9, "%-l:%M %p", localtime(&time));

        lastMessageSentDateLabel.font = [UIFont boldSystemFontOfSize:LAST_MESSAGE_SENT_DATE_FONT_SIZE];
        NSString *lastMessageSentDateLabelText = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        if ([lastMessageTextLabel respondsToSelector:@selector(attributedText)]) {
            NSMutableAttributedString *lastMessageSentDateLabelAttributedText = [[NSMutableAttributedString alloc] initWithString:lastMessageSentDateLabelText];
            [lastMessageSentDateLabelAttributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:LAST_MESSAGE_SENT_DATE_AM_PM_FONT_SIZE] range:NSMakeRange([lastMessageSentDateLabelText length]-3, 3)];
            lastMessageSentDateLabel.attributedText = lastMessageSentDateLabelAttributedText;
        } else {
            lastMessageSentDateLabel.text = lastMessageSentDateLabelText;
        }
    } else {
        lastMessageSentDateLabel.font = [UIFont systemFontOfSize:LAST_MESSAGE_SENT_DATE_FONT_SIZE];
        if ([lastMessageSentDate compare:twoDaysAgo] == NSOrderedDescending) {
            lastMessageSentDateLabel.text = NSLocalizedString(@"Yesterday", nil);
        } else {
            char buffer[11];
            time_t time = [lastMessageSentDate timeIntervalSince1970];
            if ([lastMessageSentDate compare:lastWeek] == NSOrderedDescending) {
                // Wednesday -- 9 chars + 1 for NUL terminator \0
                strftime(buffer, 11, "%A", localtime(&time));
                lastMessageSentDateLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            } else {
                // 12/24/2012 -- 10 chars + 1 for NUL terminator \0
                strftime(buffer, 11, "%-m/%-e/%Y", localtime(&time));
                lastMessageSentDateLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            }
        }
    }

    CGFloat lastMessageSentDateLabelWidth = [lastMessageSentDateLabel.text sizeWithFont:lastMessageSentDateLabel.font].width;
    lastMessageSentDateLabel.frame = CGRectMake(31+lastMessageTextLabelWidth-lastMessageSentDateLabelWidth, (conversation.lastMessageText ? 5 : 19), lastMessageSentDateLabelWidth, LAST_MESSAGE_SENT_DATE_FONT_SIZE+4);

    // Configure usersNamesLabel.
    UILabel *usersNamesLabel = (UILabel *)[cell.contentView viewWithTag:USERS_NAMES_LABEL_TAG];
    usersNamesLabel.frame = CGRectMake(31, (conversation.lastMessageText ? 2 : 18), lastMessageTextLabelWidth-4-lastMessageSentDateLabelWidth, 20);
    usersNamesLabel.text = ((ACUser *)[conversation.users anyObject]).name;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: nil out _conversation on ACAppDelegate, etc. to prevent crash if I receive message after deleting.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        MOCSave(_managedObjectContext);
        self.title = NSLocalizedString(@"Messages", nil);
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"ACConversation" inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"lastMessageSentDate" ascending:YES]]];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[@"recipients"]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"ACConversation"];
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
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self tableView:tableView configureCell:[tableView cellForRowAtIndexPath:indexPath] withConversation:anObject];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
