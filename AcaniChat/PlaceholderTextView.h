#import <UIKit/UIKit.h>

@interface PlaceholderTextView : UITextView

@property (strong, nonatomic) NSString *placeholder;

- (void)updateShouldDrawPlaceholder;

@end
