#import "ACUserCell.h"
#import "ACUser.h"

@implementation ACUserCell {
    UILabel *_nameLabel;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 2, 75-3, 16)];
        _nameLabel.backgroundColor = [UIColor blueColor];
        _nameLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_nameLabel];
    }
    return self;
}

- (void)setUser:(ACUser *)user {
    _user = user;
    _nameLabel.text = _user.name;
}

@end
