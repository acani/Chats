#import "ACUserViewController.h"
#import "ACUser.h"

@implementation ACUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _user.name;
}

@end
