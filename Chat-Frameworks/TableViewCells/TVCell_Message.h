//
//  TVCell_Message.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Message.h"
@interface TVCell_Message : UITableViewCell
{
    UIImageView *msgBackground;
    UILabel *msgText;
}
@property (nonatomic, strong) id message;
@property (nonatomic, assign) BOOL rightward; 

- (void) setMessage:(id)message rightward: (BOOL) rightward; 

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier;


@end
