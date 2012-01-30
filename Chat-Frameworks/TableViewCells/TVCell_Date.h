//
//  TVCell_Date.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVCell_Date : UITableViewCell
{
    UILabel *msgSentDate;
}

@property (nonatomic, strong) NSDate * date;



@property (nonatomic, strong) NSDateFormatter * dateFormatter;

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
