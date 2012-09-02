#import "AppDelegate.h"
#import "ConversationsTableViewController.h"
#import "Conversation.h"
#import "User.h"

@implementation AppDelegate {
    NSManagedObjectContext *_managedObjectContext;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AcaniChat" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"AcaniChat.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

    // For now, start fresh; delete all conversations.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:_managedObjectContext]];
    fetchRequest.includesPropertyValues = NO;
    fetchRequest.includesPendingChanges = NO;
    fetchRequest.relationshipKeyPathsForPrefetching = @[@"messages"];
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (NSManagedObject *fetchedObject in fetchedObjects) {
        [_managedObjectContext deleteObject:fetchedObject];
    }

    // Insert a mock conversation with a mock user.
    Conversation *conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_managedObjectContext];
    conversation.updatedDate = [NSDate date];
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    user.name = @"Acani";
    [conversation addUsersObject:user];

    // Set up _window > UINavigationController > MessagesViewController.
    ConversationsTableViewController *conversationsTableViewController = [[ConversationsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    conversationsTableViewController.managedObjectContext = _managedObjectContext;
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:conversationsTableViewController];

//    // Fetch or insert the conversation.
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Conversation"
//                                        inManagedObjectContext:_managedObjectContext]];
//    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
//    if ([fetchedObjects count]) {
//        messagesViewController.conversation = fetchedObjects[0];
//    } else {
//        messagesViewController.conversation = [NSEntityDescription
//                                               insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_managedObjectContext];
//    }

    [_window makeKeyAndVisible];
    return YES;
}

//- (void)applicationWillTerminate:(UIApplication *)application {
//    [self saveContext];
//}
//
//- (void)saveContext {
//    NSError *error = nil;
//    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
//    if (managedObjectContext != nil) {
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//             // Replace this implementation with code to handle the error appropriately.
//             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        } 
//    }
//}

@end
