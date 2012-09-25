#import <AudioToolbox/AudioToolbox.h>
#import <SocketRocket/SRWebSocket.h>
#import "AcaniDefines.h"
#import "ACAppDelegate.h"
#import "ACConversationsViewController.h"
#import "ACUsersViewController.h"
#import "ACMessagesViewController.h"
#import "ACConversation.h"
#import "ACMessage.h"
#import "ACUser.h"

// messageType
#define USERS_NEAREST_GET                            0
#define MESSAGES_NEWEST_GET                          1
#define DEVICE_TOKEN_CONNECT                         2
#define DEVICE_TOKEN_SAVE                            3
#define DEVICE_TOKEN_UPDATE                          4
#define MESSAGE_TEXT_SEND                            5
#define MESSAGE_TEXT_RECEIVE                         6

// TODO: Find a better way to insert these strings into message compile-time.
#define USERS_NEAREST_GET_STRING                            @"[0"
#define MESSAGES_NEWEST_GET_STRING                          @"[1"
#define DEVICE_TOKEN_CONNECT_STRING                         @"[2"
#define DEVICE_TOKEN_SAVE_STRING                            @"[3"
#define DEVICE_TOKEN_UPDATE_STRING                          @"[4"
#define MESSAGE_TEXT_SEND_STRING                            @"[5"
#define MESSAGE_TEXT_RECEIVE_STRING                         @"[6"

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)

#define ACAppDelegateCreateSystemSoundIDs() \
ACMessageCreateSystemSoundIDs(&_messageReceivedSystemSoundID, &_messageSentSystemSoundID)

static NSString *const ACDeviceTokenKey = @"ACDeviceTokenKey";

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

NS_INLINE NSString *ACHexadecimalStringWithData(NSData *data) {
    NSUInteger dataLength = [data length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [data bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    return string;
}

@interface ACAppDelegate () <SRWebSocketDelegate> {
    NSData                 *_deviceToken;
    NSManagedObjectContext *_managedObjectContext;
    ACConversation         *_conversation; // temporary mock
    NSMutableDictionary    *_messagesSendingDictionary;
    NSNumber               *_messagesSendingDictionaryPrimaryKey;
    SystemSoundID           _messageReceivedSystemSoundID;
    SystemSoundID           _messageSentSystemSoundID;
}
@end

@implementation ACAppDelegate

#pragma mark - State Transitions

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Acani" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Acani.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
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
        _conversation.title = user.name = @"Acani";
        [_conversation addUsersObject:user];
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

    _messagesSendingDictionary = [NSMutableDictionary dictionary];
    _messagesSendingDictionaryPrimaryKey = @(0);
    ACAppDelegateCreateSystemSoundIDs();

    // Set up _window > UINavigationController > UsersViewController.
    UICollectionViewFlowLayout *usersLayout = [[UICollectionViewFlowLayout alloc] init];
    usersLayout.minimumLineSpacing = 4;
    usersLayout.minimumInteritemSpacing = 4;
    usersLayout.itemSize = CGSizeMake(75, 75);
    usersLayout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    ACUsersViewController *usersViewController = [[ACUsersViewController alloc] initWithCollectionViewLayout:usersLayout];
    usersViewController.title = NSLocalizedString(@"Users", nil);
    usersViewController.managedObjectContext = _managedObjectContext;
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:usersViewController];
    [_window makeKeyAndVisible];

    [self _reconnect];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    AudioServicesDisposeSystemSoundID(_messageReceivedSystemSoundID);
    AudioServicesDisposeSystemSoundID(_messageSentSystemSoundID);
    [_webSocket close];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    _messagesSendingDictionary = [NSMutableDictionary dictionary];
    ACAppDelegateCreateSystemSoundIDs();
    [self _reconnect];
}

#pragma mark - Remote Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
//    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", newDeviceToken);

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSData *deviceToken = [standardUserDefaults dataForKey:ACDeviceTokenKey];
    if ([newDeviceToken isEqualToData:deviceToken]) return;
    [standardUserDefaults setObject:newDeviceToken forKey:ACDeviceTokenKey];

    if (!deviceToken) {
        // DEVICE_TOKEN_SAVE:
        // messageType,newDeviceToken, e.g., DEVICE_TOKEN_SAVE,"c9a632..."]
        [_webSocket send:[NSString stringWithFormat:DEVICE_TOKEN_SAVE_STRING",\"%@\"]", ACHexadecimalStringWithData(newDeviceToken)]];
    } else {
        // DEVICE_TOKEN_UPDATE:
        // messageType,deviceToken,newDeviceToken, e.g., DEVICE_TOKEN_UPDATE,c9a632...,473aba...
        [_webSocket send:[NSString stringWithFormat:DEVICE_TOKEN_UPDATE_STRING",\"%@\",\"%@\"]", ACHexadecimalStringWithData(deviceToken), ACHexadecimalStringWithData(newDeviceToken)]];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
//    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Register for Pushes", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
}

//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    NSLog(@"didReceiveRemoteNotification: %@", userInfo);
//    NSLog(@"application.applicationState: %i", application.applicationState);
//    if (application.applicationState == UIApplicationStateActive) {
//    } else { // UIApplicationStateInactive (tapped action button)
//    }
//}

#pragma mark - Connect & Save/Send Messages

- (void)_reconnect {
    _webSocket.delegate = nil;
    [_webSocket close];

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOST]]];
    _webSocket.delegate = self;

    [_webSocket open];
    AppSetNetworkActivityIndicatorVisible(YES);
}

// messageArray: @[sent_timestamp,messageText], e.g., @[978307200.0,@"Hi"]
- (void)addMessageWithArray:(NSArray *)messageArray {
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:_managedObjectContext];
    _conversation.lastMessageSentDate = message.sentDate = [NSDate dateWithTimeIntervalSince1970:[messageArray[0] /* sent_timestamp */ doubleValue]];
    _conversation.lastMessageText = message.text = messageArray[1] /* messageText */;
    [_conversation addMessagesObject:message];
}

- (void)sendMessage:(ACMessage *)message {
    // MESSAGE_TEXT_SEND:
    // [messageType,messagesSendingKey,messageText], e.g., [MESSAGE_TEXT_SEND,0,"Hi"]
    [_webSocket send:[NSString stringWithFormat:MESSAGE_TEXT_SEND_STRING",%u,\"%@\"]", [_messagesSendingDictionaryPrimaryKey unsignedIntegerValue], [message.text stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [message.text length])]]];
    [_messagesSendingDictionary setObject:message forKey:_messagesSendingDictionaryPrimaryKey];
    _messagesSendingDictionaryPrimaryKey = @([_messagesSendingDictionaryPrimaryKey unsignedIntegerValue]+1);
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
//    NSLog(@"webSocketDidOpen: %@", webSocket);

    NSData *deviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:ACDeviceTokenKey];
    UIViewController *topViewController = NAVIGATION_CONTROLLER().topViewController;
    if ([topViewController isMemberOfClass:[ACMessagesViewController class]]) {
        // MESSAGES_NEWEST_GET:
        if (deviceToken) {
            // [messageType,messagesLength,deviceToken], e.g., [MESSAGES_NEWEST_GET,5,"c9a632..."]
            [_webSocket send:[NSString stringWithFormat:MESSAGES_NEWEST_GET_STRING",%u,\"%@\"]", [_conversation.messagesLength unsignedIntegerValue], ACHexadecimalStringWithData(deviceToken)]];
        } else {
            // [messageType,messagesLength],             e.g., [MESSAGES_NEWEST_GET,5]
            [_webSocket send:[NSString stringWithFormat:MESSAGES_NEWEST_GET_STRING",%u]", [_conversation.messagesLength unsignedIntegerValue]]];
        }
    } else {
        // USERS_NEAREST_GET:
        if (deviceToken) {
            // [messageType,deviceToken],                e.g., [USERS_NEAREST_GET,"c9a632..."]
            [_webSocket send:[NSString stringWithFormat:USERS_NEAREST_GET_STRING",\"%@\"]", ACHexadecimalStringWithData(deviceToken)]];
        } else {
            // [messageType],                            e.g., [USERS_NEAREST_GET]
            [_webSocket send:USERS_NEAREST_GET_STRING"]"];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
//    NSLog(@"webSocket:didFailWithError: %@", error);
    AppSetNetworkActivityIndicatorVisible(NO);
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Connect", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    _webSocket.delegate = nil;
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
//    NSLog(@"Received \"%@\"", message);

    NSUInteger messagesCount;
    NSArray *messageArray = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    switch ([message[0] /* messageType */ integerValue]) {
        case USERS_NEAREST_GET:
            // [messageType,usersNearest], e.g., [USERS_NEAREST_GET,["c9a632...","473aba..."]]
            AppSetNetworkActivityIndicatorVisible(NO);

        {
            // TODO: Only add new users (no duplicates).
            for (NSString *userString in messageArray[1] /* usersNearest */) {
                ACUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"ACUser" inManagedObjectContext:_managedObjectContext];
                user.userID = userString;
                user.name = userString;
            }
        }
            MOCSave(_managedObjectContext);
            return;

        case MESSAGES_NEWEST_GET:
            // [messageType,messagesLength,messageArraysNewest], e.g., [MESSAGES_NEWEST_GET,7,[[978307200.0,"Hi"], [978307201.0,"Hey"]]]
            AppSetNetworkActivityIndicatorVisible(NO);
        {
            NSArray *messageArraysNewest = messageArray[2];
            messagesCount = [messageArraysNewest count];
            if (messagesCount) {
                _conversation.messagesLength = @([_conversation.messagesLength unsignedIntegerValue]+messagesCount);
                for (NSArray *messageArray in messageArraysNewest) {
                    [self addMessageWithArray:messageArray];
                }
            } else {
                return;
            }
        } break;

        case MESSAGE_TEXT_SEND:
            // [messageType,messagesSendingKey,sent_timestamp], e.g., [MESSAGE_TEXT_SEND,0,978307200.0]
            AudioServicesPlaySystemSound(_messageSentSystemSoundID);
            _conversation.messagesLength = @([_conversation.messagesLength unsignedIntegerValue]+((NSUInteger)1));
        {
            NSNumber *messagesSendingKey = messageArray[1];
            ((ACMessage *)_messagesSendingDictionary[messagesSendingKey]).sentDate = [NSDate dateWithTimeIntervalSince1970:[messageArray[2] doubleValue]];
            [_messagesSendingDictionary removeObjectForKey:messagesSendingKey];
        }
            if (![_messagesSendingDictionary count]) {
                _messagesSendingDictionaryPrimaryKey = @(0);
            }
            MOCSave(_managedObjectContext);
            return;

        case MESSAGE_TEXT_RECEIVE:
            // [messageType,[sent_timestamp,messageText]], e.g., [MESSAGE_TEXT_RECEIVE,[978307200.0,"Hi"]]
            messagesCount = 1;
            [self addMessageWithArray:messageArray[1]];
            break;
    }

    ACMessagesViewController *messagesViewController = (ACMessagesViewController *)NAVIGATION_CONTROLLER().topViewController;
    if ([messagesViewController respondsToSelector:@selector(scrollToBottomAnimated:)]) {
        [messagesViewController scrollToBottomAnimated:YES];
    } else {
        NSUInteger unreadMessagesCount = [_conversation.unreadMessagesCount unsignedIntegerValue] + messagesCount;
        [UIApplication sharedApplication].applicationIconBadgeNumber = unreadMessagesCount;
        _conversation.unreadMessagesCount = @(unreadMessagesCount);
        if ([messagesViewController isMemberOfClass:[ACConversationsViewController class]]) {
            messagesViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Messages (%u)", nil), unreadMessagesCount];
        }
    }

    AudioServicesPlayAlertSound(_messageReceivedSystemSoundID);
    MOCSave(_managedObjectContext);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _webSocket.delegate = nil;
    _webSocket = nil;
    _messagesSendingDictionary = nil;
}

@end
