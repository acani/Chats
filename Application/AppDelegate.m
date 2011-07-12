#import "AppDelegate.h"
#import "ConversationsViewController.h"
#import "Conversation.h"

@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

#pragma mark NSObject

- (void)dealloc {
    [window release];
    [navigationController release];
    
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [super dealloc];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ConversationsViewController *viewController = [[ConversationsViewController alloc] init];
    viewController.managedObjectContext = self.managedObjectContext;

//    // Run once: Create a new conversation. Add all messages to it. Store it in Core Data.
//    Conversation *conversation = (Conversation *)[NSEntityDescription
//                                                  insertNewObjectForEntityForName:@"Conversation"
//                                                  inManagedObjectContext:managedObjectContext];
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message"
//                                              inManagedObjectContext:managedObjectContext];
//    [fetchRequest setEntity:entity];
//    
//    //// Fetches the oldest message in conversation. TODO: Optimize & memoize.
//    //// When added as a transformable, indexed, transient attribute, got: 'NSInvalidArgumentException',
//    //// reason: 'keypath lastMessage.sentDate not found in entity <NSSQLEntity Conversation id=1>'
//    // Have the NSManagedObjectContext execute a NSFetchRequest instead.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate"
//                                                                   ascending:NO];
//    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
//    [sortDescriptor release];
//    [fetchRequest setSortDescriptors:sortDescriptors];
//    [sortDescriptors release];
//    
//    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:NULL];    
//    [fetchRequest release];
//    
//    if ([fetchedObjects count] > 0) {
//        [conversation addMessages:[NSSet setWithArray:fetchedObjects]];
//        conversation.lastMessage = [fetchedObjects objectAtIndex:0];
//    }

	navigationController = [[UINavigationController alloc]
							initWithRootViewController:viewController];
    [viewController release];

    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = navigationController;
    [window makeKeyAndVisible];

    return YES;
}

//- (void)applicationWillTerminate:(UIApplication *)application {
//}

#pragma mark AppDelegate

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext != nil && [managedObjectContext hasChanges] &&
        ![managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        managedObjectContext.persistentStoreCoordinator = coordinator;
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AcaniChat" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self.applicationDocumentsDirectory
                       URLByAppendingPathComponent:@"AcaniChat.sqlite"];
    
    NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:self.managedObjectModel];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                            URL:storeURL options:nil
                                                          error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }    
    return persistentStoreCoordinator;
}

@end
