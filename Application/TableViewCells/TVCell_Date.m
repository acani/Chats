//
//  TVCell_Date.m
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TVCell_Date.h"

#import "ChatBar.h"
#import "Defines.h"

#define SENT_DATE_TAG 101

@implementation TVCell_Date

@synthesize date = _date;
@synthesize dateFormatter = _dateFormatter;

- (void) setDate:(NSDate *)date {
    _date = date;
    
    msgSentDate.text = [[self dateFormatter] stringFromDate: _date];
}

- (NSDateFormatter*) dateFormatter {
//    static NSDateFormatter *dateFormatter = nil;
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle]; // Jan 1, 2010
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];  // 1:43 PM
        
        // TODO: Get locale from iPhone system prefs. Then, move this to viewDidAppear.
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [_dateFormatter setLocale:usLocale];
    }
    
    return _dateFormatter;
}

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [self initWithStyle: UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Create message sentDate lable
        msgSentDate = [[UILabel alloc] initWithFrame:
                       CGRectMake(-2.0f, 0.0f,
                                  self.frame.size.width, kSentDateFontSize+5.0f)];
        msgSentDate.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        msgSentDate.clearsContextBeforeDrawing = NO;
        msgSentDate.tag = SENT_DATE_TAG;
        msgSentDate.font = [UIFont boldSystemFontOfSize:kSentDateFontSize];
        msgSentDate.lineBreakMode = UILineBreakModeTailTruncation;
        msgSentDate.textAlignment = UITextAlignmentCenter;
        msgSentDate.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
        msgSentDate.textColor = [UIColor grayColor];
        [self addSubview:msgSentDate];
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
}

@end
