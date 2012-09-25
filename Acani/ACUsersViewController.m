#import "AcaniDefines.h"
#import "ACUsersViewController.h"
#import "ACUserViewController.h"
#import "ACConversationsViewController.h"
#import "ACUserCell.h"

static NSString *CellIdentifier = @"ACUserCell";

@interface ACUsersViewController () <NSFetchedResultsControllerDelegate> {
    NSMutableArray *_objectChanges;
}
@end

@implementation ACUsersViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[ACUserCell class] forCellWithReuseIdentifier:CellIdentifier];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(messagesViewAction)];
    _objectChanges = [NSMutableArray array];
}

- (void)messagesViewAction {
    ACConversationsViewController *conversationsViewController = [[ACConversationsViewController alloc] initWithStyle:UITableViewStylePlain];
    conversationsViewController.title = NSLocalizedString(@"Messages", nil);
    conversationsViewController.managedObjectContext = _managedObjectContext;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:conversationsViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ACUserViewController *userViewController = [[ACUserViewController alloc] initWithNibName:nil bundle:nil];
    userViewController.user = [_fetchedResultsController objectAtIndexPath:indexPath];
    [self.navigationController pushViewController:userViewController animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ACUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor blueColor];
    cell.user = [_fetchedResultsController objectAtIndexPath:indexPath];
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"ACUser" inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setFetchBatchSize:7*4]; // 7 rows, 4 colums
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"userID" ascending:YES]]]; // TODO: Change to distance.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"ACUser"];
    _fetchedResultsController.delegate = self;
    FRCPerformFetch(_fetchedResultsController);
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_objectChanges addObject:@[@(type), newIndexPath]];
            break;
        case NSFetchedResultsChangeDelete:
        case NSFetchedResultsChangeUpdate:
            [_objectChanges addObject:@[@(type), indexPath]];
            break;
        case NSFetchedResultsChangeMove:
            [_objectChanges addObject:@[@(type), @[indexPath, newIndexPath]]];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([_objectChanges count]) {
        [self.collectionView performBatchUpdates:^{
            for (NSArray *objectChange in _objectChanges) {
                switch ([objectChange[0] unsignedIntegerValue]) { // type
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertItemsAtIndexPaths:@[objectChange[1]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteItemsAtIndexPaths:@[objectChange[1]]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[objectChange[1]]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:objectChange[1] toIndexPath:objectChange[2]];
                        break;
                }
            }
         } completion:nil];
    }
    [_objectChanges removeAllObjects];
}

@end
