#import <SocketRocket/SRWebSocket.h>
#import "AcaniChatDefines.h"
#import "AppDelegate.h"
#import "ConversationsTableViewController.h"
#import "MessagesViewController.h"
#import "Conversation.h"
#import "Message.h"
#import "User.h"

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)

@interface AppDelegate () <SRWebSocketDelegate> {
    NSManagedObjectContext *_managedObjectContext;
    Conversation *_conversation; // temporary mock
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AcaniChat" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"AcaniChat.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

    // For now, start fresh; delete all conversations, messages, and users.
    MOCDeleteAll(_managedObjectContext, @"Conversation", @[@"messages"]);
    MOCDeleteAll(_managedObjectContext, @"User", nil);

    // Insert a mock conversation with a mock user.
    _conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_managedObjectContext];
    _conversation.updatedDate = [NSDate date];
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    user.name = @"Acani";
    [_conversation addUsersObject:user];

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

    // Set up _window > UINavigationController > MessagesViewController.
    ConversationsTableViewController *conversationsTableViewController = [[ConversationsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    conversationsTableViewController.title = NSLocalizedString(@"Messages", nil);
    conversationsTableViewController.managedObjectContext = _managedObjectContext;
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:conversationsTableViewController];
    [_window makeKeyAndVisible];

    [self _reconnect];

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

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self _reconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _webSocket.delegate = nil;
    [_webSocket close];
    _webSocket = nil;
}

#pragma mark - Connect & Save/Send Messages

- (void)_reconnect {
    _webSocket.delegate = nil;
    [_webSocket close];

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOST]]];
    _webSocket.delegate = self;

    [_webSocket open];
}

- (void)saveMessageWithText:(NSString *)text {
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:_managedObjectContext];
    message.read = [NSNumber numberWithBool:YES];
    message.sentDate = [NSDate date];
    message.text = text;
    [_conversation addMessagesObject:message];
    MOCSave(_managedObjectContext);
}

- (void)sendText:(NSString *)text {
    [_webSocket send:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[text] options:0 error:NULL] encoding:NSUTF8StringEncoding]];
}

#pragma mark - SRWebSocketDelegate

//- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
//    // TODO: Tell server we're connected.
//}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Connect", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    _webSocket.delegate = nil;
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Received \"%@\"", message);
    NSArray *texts = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    for (NSString *text in texts) {
        [self saveMessageWithText:text];
    }

    MessagesViewController *messagesViewController = (MessagesViewController *)NAVIGATION_CONTROLLER().topViewController;
    if ([messagesViewController respondsToSelector:@selector(scrollToBottomAnimated:)]) {
        [messagesViewController scrollToBottomAnimated:YES];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _webSocket.delegate = nil;
    _webSocket = nil;
}

@end
