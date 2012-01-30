//
//  ChatBar.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Defines.h"

extern CGFloat const kSentDateFontSize;
extern CGFloat const kMessageFontSize ;   // 15.0f, 14.0f
extern CGFloat const kMessageTextWidth;
extern CGFloat const kContentHeightMax;  // 80.0f, 76.0f
extern CGFloat const kChatBarHeight1;
extern CGFloat const kChatBarHeight4;

@class ChatBar;

@protocol ChatBarDelegate <NSObject>

- (void) chatBarTextCleared: (ChatBar*) chatBar ;

- (void) chatBar: (ChatBar*) chatBar didChangeHeight: (CGFloat) height;

- (void) chatBar:(ChatBar *)chatBar didSendText: (NSString*) text; 

@end

@interface ChatBar : UIImageView
<UITextViewDelegate>
{
    @private
    UITextView *chatInput;
    CGFloat previousContentHeight;
    UIButton *sendButton;
    
    UILabel * countLabel; 
}
@property (nonatomic, unsafe_unretained) id<ChatBarDelegate> delegate; 

- (void)enableSendButton;
- (void)disableSendButton;
- (void)resetSendButton;

- (void) updateHeight: (CGFloat) height;
- (void)clearChatInput;

- (void) resetCharInput; 
@end
