#import "ACUsersViewController.h"
#import "ACConversationsViewController.h"
#import "ACUserCell.h"

static NSString *CellIdentifier = @"UICollectionViewCell";

@implementation ACUsersViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[ACUserCell class] forCellWithReuseIdentifier:CellIdentifier];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(messagesViewAction)];
}

- (void)messagesViewAction {
    ACConversationsViewController *conversationsViewController = [[ACConversationsViewController alloc] initWithStyle:UITableViewStylePlain];
    conversationsViewController.title = NSLocalizedString(@"Messages", nil);
    conversationsViewController.managedObjectContext = _managedObjectContext;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:conversationsViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 50;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor orangeColor];
    return cell;
}

@end
