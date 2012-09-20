#import <UIKit/UIKit.h>

#define AC_APP_DELEGATE() ((ACAppDelegate *)[[UIApplication sharedApplication] delegate])

@class ACMessage, SRWebSocket;

@interface ACAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SRWebSocket *webSocket;

- (void)sendMessage:(ACMessage *)message;

@end
