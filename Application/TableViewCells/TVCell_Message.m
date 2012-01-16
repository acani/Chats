//
//  TVCell_Message.m
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TVCell_Message.h"

#import "ChatBar.h"
#import "Defines.h"

#define TEXT_TAG 102
#define BACKGROUND_TAG 103


@implementation TVCell_Message
@synthesize message = _message;

@synthesize rightward = _rightward;

- (void) setMessage:(Message *)message {
    [self setMessage: message rightward: [message.isMine boolValue]];
}

- (void) setMessage:(Message *)message rightward: (BOOL) rightward{
    // Configure the cell to show the message in a bubble. Layout message cell & its subviews.
    CGSize size = [[message text] sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    UIImage *bubbleImage;
    if (rightward) { // right bubble
        CGFloat editWidth = self.editing ? 32.0f : 0.0f;
        msgBackground.frame = CGRectMake(self.frame.size.width-size.width-34.0f-editWidth,
                                         kMessageFontSize-13.0f, size.width+34.0f,
                                         size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGreen.png"]
                       stretchableImageWithLeftCapWidth:15 topCapHeight:13];
        msgText.frame = CGRectMake(self.frame.size.width-size.width-22.0f-editWidth,
                                   kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //        // Uncomment for view layout debugging.
        //        cell.contentView.backgroundColor = [UIColor blueColor];
    } else { // left bubble
        msgBackground.frame = CGRectMake(0.0f, kMessageFontSize-13.0f,
                                         size.width+34.0f, size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGray.png"]
                       stretchableImageWithLeftCapWidth:23 topCapHeight:15];
        msgText.frame = CGRectMake(22.0f, kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    msgBackground.image = bubbleImage;
    msgText.text = [message text];
    
}

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier{
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier];
    return self;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Create message background image view
        msgBackground = [[UIImageView alloc] init];
        msgBackground.clearsContextBeforeDrawing = NO;
        msgBackground.tag = BACKGROUND_TAG;
        msgBackground.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
        [self.contentView addSubview:msgBackground];
        [msgBackground release];
        
        // Create message text label
        msgText = [[UILabel alloc] init];
        msgText.clearsContextBeforeDrawing = NO;
        msgText.tag = TEXT_TAG;
        msgText.backgroundColor = [UIColor clearColor];
        msgText.numberOfLines = 0;
        msgText.lineBreakMode = UILineBreakModeWordWrap;
        msgText.font = [UIFont systemFontOfSize:kMessageFontSize];
        [self.contentView addSubview:msgText];
        [msgText release];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
