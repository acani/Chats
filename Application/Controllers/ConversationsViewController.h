@interface ConversationsViewController : UITableViewController
<NSFetchedResultsControllerDelegate> {
    
}

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end
