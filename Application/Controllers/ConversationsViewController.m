#import "ConversationsViewController.h"
#import "ChatViewController.h"
#import "Conversation.h"

@interface ConversationsViewController ()
- (void)fetchResults;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ConversationsViewController

@synthesize fetchedResultsController;
@synthesize managedObjectContext;

#pragma mark NSObject

- (void)dealloc {
    [fetchedResultsController release];
    [managedObjectContext release];
    [super dealloc];
}

#pragma mark UIViewController

- (void)viewDidUnload {
    [super viewDidUnload];
    self.fetchedResultsController = nil;
    // Leave managedObjectContext since it's not recreated in viewDidLoad.
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create edit button in upper left & compose button in upper right.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                      target:self action:@selector(pushComposeViewController)];
    self.navigationItem.rightBarButtonItem = composeButton;
    [composeButton release];

    [self fetchResults];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark UITableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        self.title = NSLocalizedString(@"Messages", nil);
    }
    return self;
}

#pragma mark ConversationsViewController

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
//    // TODO: Add transient attributes (title & lastMessage) to Conversation.
//    Conversation *conversation = [fetchedResultsController objectAtIndexPath:indexPath]; 
//    cell.textLabel.text = conversation.title;
//    cell.detailTextLabel.text = conversation.lastMessage.text;
    cell.textLabel.text = @"Joe Blogs";
    cell.detailTextLabel.text = @"Hey how's it going dude?";
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }   
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    chatViewController.managedObjectContext = managedObjectContext;
    [self.navigationController pushViewController:chatViewController animated:YES];
    [chatViewController release];
}

#pragma mark NSFetchedResultsController

- (void)fetchResults {
    if (fetchedResultsController) return;
    
    // Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Conversation"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
//    // TODO: Sort by sentDate of last message. Add lastMessage as transient attribute.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastMessage.sentDate"
//                                                                   ascending:NO];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastMessage.sentDate"
                                                                   ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [sortDescriptor release];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [sortDescriptors release];

    // Create and initialize the fetchedResultsController.
    fetchedResultsController = [[NSFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                managedObjectContext:managedObjectContext
                                sectionNameKeyPath:nil /* one section */ cacheName:@"Conversation"];
    [fetchRequest release];

    fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![fetchedResultsController performFetch:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"fetchMessages error %@, %@", error, [error userInfo]);
    }
}    

@end
