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
#define NEWEST_MESSAGES_GET                          0
#define DEVICE_TOKEN_CONNECT                         1
#define DEVICE_TOKEN_SAVE                            2
#define DEVICE_TOKEN_UPDATE                          3
#define NEWEST_MESSAGES_GET_AND_DEVICE_TOKEN_CONNECT 4
#define MESSAGE_TEXT_SEND                            5
#define MESSAGE_TEXT_RECEIVE                         6

// TODO: Find a better way to insert these strings into message compile-time.
#define NEWEST_MESSAGES_GET_STRING                          @"0"
#define DEVICE_TOKEN_CONNECT_STRING                         @"1"
#define DEVICE_TOKEN_SAVE_STRING                            @"2"
#define DEVICE_TOKEN_UPDATE_STRING                          @"3"
#define NEWEST_MESSAGES_GET_AND_DEVICE_TOKEN_CONNECT_STRING @"4"
#define MESSAGE_TEXT_SEND_STRING                            @"5"
#define MESSAGE_TEXT_RECEIVE_STRING                         @"6"

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
        user.name = @"Acani";
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
        // messageType|newDeviceToken, e.g., DEVICE_TOKEN_SAVE|c9a632...
        [_webSocket send:[NSString stringWithFormat:DEVICE_TOKEN_SAVE_STRING"|%@", ACHexadecimalStringWithData(newDeviceToken)]];
    } else {
        // DEVICE_TOKEN_UPDATE:
        // messageType|deviceToken|newDeviceToken, e.g., DEVICE_TOKEN_UPDATE|c9a632...|473aba...
        [_webSocket send:[NSString stringWithFormat:DEVICE_TOKEN_UPDATE_STRING"|%@|%@", ACHexadecimalStringWithData(deviceToken), ACHexadecimalStringWithData(newDeviceToken)]];
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

// messagePipedString: "messageSentTimeIntervalSince1970|messageText", e.g., @"978307200.0|Hi"
- (void)addMessageWithPipedString:(NSString *)messagePipedString {
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:_managedObjectContext];
    NSUInteger indexOfNextPipe = [messagePipedString rangeOfString:@"|" options:NSLiteralSearch].location;
    _conversation.lastMessageSentDate = message.sentDate = [NSDate dateWithTimeIntervalSince1970:[[messagePipedString substringToIndex:indexOfNextPipe] doubleValue]];
    _conversation.lastMessageText = message.text = [messagePipedString substringFromIndex:indexOfNextPipe+1];
    [_conversation addMessagesObject:message];
}

- (void)sendMessage:(ACMessage *)message {
    // MESSAGE_TEXT_SEND:
    // messageType|messagesSendingKey|messageText, e.g., MESSAGE_TEXT_SEND|0|Hi
    [_webSocket send:[NSString stringWithFormat:MESSAGE_TEXT_SEND_STRING"|%u|%@", [_messagesSendingDictionaryPrimaryKey unsignedIntegerValue], message.text]];
    [_messagesSendingDictionary setObject:message forKey:_messagesSendingDictionaryPrimaryKey];
    _messagesSendingDictionaryPrimaryKey = @([_messagesSendingDictionaryPrimaryKey unsignedIntegerValue]+1);
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
//    NSLog(@"webSocketDidOpen: %@", webSocket);

    NSData *deviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:ACDeviceTokenKey];
    if (deviceToken) {
        // NEWEST_MESSAGES_GET_AND_DEVICE_TOKEN_CONNECT:
        // messageType|messagesLength|deviceToken, e.g., NEWEST_MESSAGES_GET_AND_DEVICE_TOKEN_CONNECT|5|c9a632...
        [_webSocket send:[NSString stringWithFormat:NEWEST_MESSAGES_GET_AND_DEVICE_TOKEN_CONNECT_STRING"|%u|%@", [_conversation.messagesLength unsignedIntegerValue], ACHexadecimalStringWithData(deviceToken)]];
    } else {
        // NEWEST_MESSAGES_GET:
        // messageType|messagesLength,             e.g., NEWEST_MESSAGES_GET|5
        [_webSocket send:[NSString stringWithFormat:NEWEST_MESSAGES_GET_STRING"|%u", [_conversation.messagesLength unsignedIntegerValue]]];
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

    // Parse out messageType & messageContent from message.
    NSUInteger indexOfNextPipe = [message rangeOfString:@"|" options:NSLiteralSearch].location;
    NSInteger  messageType;
    NSString  *messageContent;
    if (indexOfNextPipe == NSNotFound) {
        messageType    = [message integerValue];
        messageContent = nil;
    } else {
        messageType    = [[message substringToIndex:indexOfNextPipe] integerValue];
        messageContent = [message substringFromIndex:indexOfNextPipe+1];
    }

    NSUInteger messagesCount;
    switch (messageType) {
        case NEWEST_MESSAGES_GET:
            // messageType|messagesLength|newestMessagesPipedStrings, e.g., NEWEST_MESSAGES_GET|7|["978307200.0|Hi", "978307201.0|Hey"]
            // messageType,                                     i.e., NEWEST_MESSAGES_GET (empty)
            AppSetNetworkActivityIndicatorVisible(NO);
            if (messageContent) {
                indexOfNextPipe = [messageContent rangeOfString:@"|" options:NSLiteralSearch].location;
                _conversation.messagesLength = @((NSUInteger)[[messageContent substringToIndex:indexOfNextPipe] integerValue]);
                NSArray *newestMessagesPipedStrings = [NSJSONSerialization JSONObjectWithData:[[messageContent substringFromIndex:indexOfNextPipe+1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
                messagesCount = [newestMessagesPipedStrings count];
                for (NSString *messagePipedString in newestMessagesPipedStrings) {
                    [self addMessageWithPipedString:messagePipedString];
                }
            } else {
                return;
            }
            break;

        case MESSAGE_TEXT_SEND:
            // messageType|messagesSendingKey|messageSentTimeIntervalSince1970, e.g., MESSAGE_TEXT_SEND|0|978307200.0
            AudioServicesPlaySystemSound(_messageSentSystemSoundID);
            _conversation.messagesLength = @([_conversation.messagesLength unsignedIntegerValue]+((NSUInteger)1));
            indexOfNextPipe = [messageContent rangeOfString:@"|" options:NSLiteralSearch].location;
        {
            NSNumber *messagesSendingKey = @((NSUInteger)[[messageContent substringToIndex:indexOfNextPipe] integerValue]);
            ((ACMessage *)_messagesSendingDictionary[messagesSendingKey]).sentDate = [NSDate dateWithTimeIntervalSince1970:[[messageContent substringFromIndex:indexOfNextPipe+1] doubleValue]];
            [_messagesSendingDictionary removeObjectForKey:messagesSendingKey];
        }
            if (![_messagesSendingDictionary count]) {
                _messagesSendingDictionaryPrimaryKey = @(0);
            }
            MOCSave(_managedObjectContext);
            return;

        case MESSAGE_TEXT_RECEIVE:
            // messageType|messageSentTimeIntervalSince1970|messageText, e.g., MESSAGE_TEXT_RECEIVE|978307200.0|Hi
            messagesCount = 1;
            [self addMessageWithPipedString:messageContent];
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
