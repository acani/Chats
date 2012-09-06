#import <UIKit/UIKit.h>

#define APP_DELEGATE() ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@class SRWebSocket;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SRWebSocket *webSocket;

- (void)saveMessageWithText:(NSString *)text;
- (void)sendText:(NSString *)text;

@end
