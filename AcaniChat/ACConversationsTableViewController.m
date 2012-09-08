#import <MessageUI/MessageUI.h>
#import "AcaniChatDefines.h"
#import "ACConversationsTableViewController.h"
#import "ACMessagesViewController.h"
#import "ACConversation.h"
#import "ACUser.h"

@interface ACConversationsTableViewController () <NSFetchedResultsControllerDelegate> // , MFMessageComposeViewControllerDelegate>
@end

@implementation ACConversationsTableViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
}

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
    }
    ACConversation *conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = ((ACUser *)[conversation.users anyObject]).name;
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:conversation.updatedDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        MOCSave(_managedObjectContext);
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"ACConversation" inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"updatedDate" ascending:YES]]];
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
            //        case NSFetchedResultsChangeMove:
            //            break;
            //        case NSFetchedResultsChangeUpdate:
            //            // TODO: Set cell.detailTextLabel.text to last sent message.text. Then, update here.
            //            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            //            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
