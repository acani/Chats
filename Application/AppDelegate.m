#import "AppDelegate.h"
#import "ChatViewController.h"

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
    ChatViewController *viewController = [[ChatViewController alloc] init];
    viewController.managedObjectContext = self.managedObjectContext;

	navigationController = [[UINavigationController alloc]
							initWithRootViewController:viewController];
    [viewController release];

    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.navigationController;
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
