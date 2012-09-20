#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ACUsersViewController : UICollectionViewController

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
