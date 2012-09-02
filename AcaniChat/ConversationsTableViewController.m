#import "AcaniChatDefines.h"
#import "ConversationsTableViewController.h"
#import "MessagesViewController.h"
#import "Conversation.h"
#import "User.h"

@interface ConversationsTableViewController () <NSFetchedResultsControllerDelegate>
@end

@implementation ConversationsTableViewController

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MessagesViewController *messagesViewController = [[MessagesViewController alloc] initWithNibName:nil bundle:nil];
    messagesViewController.managedObjectContext = _managedObjectContext;
    messagesViewController.conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
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
    Conversation *conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = ((User *)[conversation.users anyObject]).name;
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:conversation.updatedDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"updatedDate" ascending:YES]]];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[@"recipients"]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"Conversation"];
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
//        // TODO: Set cell.detailTextLabel.text to last sent message.text. Then, update here.
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
