#import <AudioToolbox/AudioToolbox.h>
#import <SocketRocket/SRWebSocket.h>
#import "AcaniChatDefines.h"
#import "ACAppDelegate.h"
#import "ACConversationsTableViewController.h"
#import "ACMessagesViewController.h"
#import "ACConversation.h"
#import "ACMessage.h"
#import "ACUser.h"

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)

#define ACAppDelegateCreateSystemSoundIDs() \
ACMessageCreateSystemSoundIDs(&_messageReceivedSystemSoundID, &_messageSentSystemSoundID)

CF_INLINE void ACMessageCreateSystemSoundIDs(SystemSoundID *_messageReceivedSystemSoundID, SystemSoundID *_messageSentSystemSoundID) {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFStringRef resourceType = CFSTR("aiff");

    CFURLRef messageReceivedURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("MessageReceived"), resourceType, NULL);
    AudioServicesCreateSystemSoundID(messageReceivedURLRef, _messageReceivedSystemSoundID);
    CFRelease(messageReceivedURLRef);

    CFURLRef messageSentURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("MessageSent"), resourceType, NULL);
    AudioServicesCreateSystemSoundID(messageSentURLRef, _messageSentSystemSoundID);
    CFRelease(messageSentURLRef);
}

@interface ACAppDelegate () <SRWebSocketDelegate> {
    NSManagedObjectContext *_managedObjectContext;
    ACConversation *_conversation; // temporary mock
    SystemSoundID _messageReceivedSystemSoundID;
    SystemSoundID _messageSentSystemSoundID;
}
@end

@implementation ACAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AcaniChat" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"AcaniChat.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

//    // For now, start fresh; delete all conversations, messages, and users.
//    MOCDeleteAll(_managedObjectContext, @"ACConversation", @[@"messages"]);
//    MOCDeleteAll(_managedObjectContext, @"ACUser", nil);

//    // Delete mock conversations with mock users.
//    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ACUser"];
//    fetchRequest.includesPropertyValues = NO;
//    fetchRequest.includesPendingChanges = NO;
//    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name != 'Acani'"];
//    fetchRequest.relationshipKeyPathsForPrefetching = @[@"conversations"];
//    NSArray *fetchedUsers = MOCFetch(_managedObjectContext, fetchRequest);
//    for (ACUser *user in fetchedUsers) {
//        [_managedObjectContext deleteObject:user];
//        [_managedObjectContext deleteObject:[user.conversations anyObject]];
//    }
//    MOCSave(_managedObjectContext);

    // Fetch or insert the conversation.
    NSArray *fetchedConversations = MOCFetchAll(_managedObjectContext, @"ACConversation");
    if ([fetchedConversations count]) {
        _conversation = fetchedConversations[0];
    } else {
        _conversation = [NSEntityDescription insertNewObjectForEntityForName:@"ACConversation" inManagedObjectContext:_managedObjectContext];
        _conversation.lastMessageSentDate = [NSDate date];
        ACUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"ACUser" inManagedObjectContext:_managedObjectContext];
        user.name = @"Acani";
        [_conversation addUsersObject:user];
        MOCSave(_managedObjectContext);
    }

//    // Insert mock conversations with mock users.
//    for (NSUInteger idx = 1; idx < 20; ++idx) {
//        ACConversation *conversation = [NSEntityDescription insertNewObjectForEntityForName:@"ACConversation" inManagedObjectContext:_managedObjectContext];
//        conversation.lastMessageSentDate = [NSDate date];
//        ACUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"ACUser" inManagedObjectContext:_managedObjectContext];
//        user.name = [NSString stringWithFormat:@"Acani %u", idx];
//        [conversation addUsersObject:user];
//    }
//    MOCSave(_managedObjectContext);

    ACAppDelegateCreateSystemSoundIDs();

    // Set up _window > UINavigationController > MessagesViewController.
    ACConversationsTableViewController *conversationsTableViewController = [[ACConversationsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    conversationsTableViewController.title = NSLocalizedString(@"Messages", nil);
    conversationsTableViewController.managedObjectContext = _managedObjectContext;
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:conversationsTableViewController];
    [_window makeKeyAndVisible];

    [self _reconnect];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MOCSave(_managedObjectContext);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    ACAppDelegateCreateSystemSoundIDs();
    [self _reconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    AudioServicesDisposeSystemSoundID(_messageReceivedSystemSoundID);
    AudioServicesDisposeSystemSoundID(_messageSentSystemSoundID);
    [_webSocket close];
}

#pragma mark - Connect & Save/Send Messages

- (void)_reconnect {
    _webSocket.delegate = nil;
    [_webSocket close];

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOST]]];
    _webSocket.delegate = self;

    [_webSocket open];
    AppSetNetworkActivityIndicatorVisible(YES);
}

- (void)addMessageWithJSONArray:(NSArray *)messageJSONArray {
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:_managedObjectContext];
    _conversation.lastMessageSentDate = message.sentDate = [NSDate dateWithTimeIntervalSince1970:[messageJSONArray[0] doubleValue]];
    _conversation.lastMessageText = message.text = messageJSONArray[1];
    [_conversation addMessagesObject:message];
}

- (void)sendMessage:(ACMessage *)message {
    [_webSocket send:[NSJSONSerialization dataWithJSONObject:@[@1, @[@([message.sentDate timeIntervalSince1970]), message.text]] options:0 error:NULL]];
    AudioServicesPlaySystemSound(_messageSentSystemSoundID);
    _conversation.messagesLength = [NSNumber numberWithUnsignedInteger:[_conversation.messagesLength unsignedIntegerValue]+1];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [_webSocket send:[NSString stringWithFormat:@"[0,%u]", [_conversation.messagesLength unsignedIntegerValue]]];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    AppSetNetworkActivityIndicatorVisible(NO);
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Connect", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    _webSocket.delegate = nil;
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
//    NSLog(@"Received \"%@\"", message);

    // messageArray: [type, ... ], e.g., [0, ... ]
    NSArray *messageArray = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    NSUInteger messagesCount;
    switch ([messageArray[0] integerValue]) { // type
        // messageJSONArray: [timestamp, "text"], e.g., [978307200.0, "Hi"]
        case 0:
            AppSetNetworkActivityIndicatorVisible(NO);
            if ([messageArray count] == 3) { // [type, messagesLength, newestMessages], e.g., [0, 7, [[978307200.0, "Hi"], [978307201.0, "Hey"]]]
                _conversation.messagesLength = messageArray[1];
                NSArray *messageJSONArrays = messageArray[2];
                messagesCount = [messageJSONArrays count];
                for (NSArray *messageJSONArray in messageJSONArrays) {
                    [self addMessageWithJSONArray:messageJSONArray];
                }
            } else {                         // [type], e.g., [0], no new messages
                return;
            }
            break;

        case 1: // [type, message][1, [978307200.0, "Hi"]]
            messagesCount = 1;
            [self addMessageWithJSONArray:messageArray[1]];
            break;
    }

    ACMessagesViewController *messagesViewController = (ACMessagesViewController *)NAVIGATION_CONTROLLER().topViewController;
    if ([messagesViewController respondsToSelector:@selector(scrollToBottomAnimated:)]) {
        [messagesViewController scrollToBottomAnimated:YES];
    } else { // assume topViewController is ACConversationsTableViewController.
        NSUInteger unreadMessagesCount = [_conversation.unreadMessagesCount unsignedIntegerValue] + messagesCount;
        [UIApplication sharedApplication].applicationIconBadgeNumber = unreadMessagesCount;
        _conversation.unreadMessagesCount = [NSNumber numberWithUnsignedInteger:unreadMessagesCount];
        messagesViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Messages (%u)", nil), unreadMessagesCount];
    }

    AudioServicesPlayAlertSound(_messageReceivedSystemSoundID);
    MOCSave(_managedObjectContext);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _webSocket.delegate = nil;
    _webSocket = nil;
}

@end
