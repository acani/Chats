@interface ConversationsViewController : UITableViewController
<NSFetchedResultsControllerDelegate> {
    
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
