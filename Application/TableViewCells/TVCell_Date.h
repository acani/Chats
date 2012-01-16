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

@property (nonatomic, retain) NSDate * date;



@property (nonatomic, retain) NSDateFormatter * dateFormatter;

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
