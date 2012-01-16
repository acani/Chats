//
//  ChatBar.m
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatBar.h"

#import "NSString+Additions.h"

CGFloat const kSentDateFontSize = 13.0f;
CGFloat const kMessageFontSize   = 16.0f;   // 15.0f, 14.0f
CGFloat const kMessageTextWidth  = 180.0f;
CGFloat const kContentHeightMax  = 84.0f;  // 80.0f, 76.0f
CGFloat const kChatBarHeight1    = 40.0f;
CGFloat const kChatBarHeight4    = 94.0f;


@implementation ChatBar

@synthesize delegate = _delegate;
/*
@synthesize chatInput;
@synthesize previousContentHeight;
@synthesize sendButton;
*/

- (id) initWithFrame:(CGRect)frame {
    self =  [super initWithFrame: frame];

    if (self) {
        
        self.clearsContextBeforeDrawing = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleWidth;
        self.image = [[UIImage imageNamed:@"ChatBar.png"]
                         stretchableImageWithLeftCapWidth:18 topCapHeight:20];
        self.userInteractionEnabled = YES;
        
        // Create chatInput.
        chatInput = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 9.0f, 234.0f, 22.0f)];
        chatInput.contentSize = CGSizeMake(234.0f, 22.0f);
        chatInput.delegate = self;
        chatInput.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        chatInput.scrollEnabled = NO; // not initially
        chatInput.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 4.0f, -2.0f);
        chatInput.clearsContextBeforeDrawing = NO;
        chatInput.font = [UIFont systemFontOfSize:kMessageFontSize];
        chatInput.dataDetectorTypes = UIDataDetectorTypeAll;
        chatInput.backgroundColor = [UIColor clearColor];
        previousContentHeight = chatInput.contentSize.height;
        [self addSubview:chatInput];
        
        // Create sendButton.
        sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sendButton.clearsContextBeforeDrawing = NO;
        sendButton.frame = CGRectMake(self.frame.size.width - 70.0f, 8.0f, 64.0f, 26.0f);
        sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | // multi-line input
        UIViewAutoresizingFlexibleLeftMargin;                       // landscape
        UIImage *sendButtonBackground = [UIImage imageNamed:@"SendButton.png"];
        [sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateNormal];
        [sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateDisabled];
        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        UIColor *shadowColor = [[UIColor alloc] initWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
        [sendButton setTitleShadowColor:shadowColor forState:UIControlStateNormal];
        [sendButton addTarget:self action:@selector(sendItemAction:)
             forControlEvents:UIControlEventTouchUpInside];
        //    // The following three lines aren't necessary now that we'are using background image.
        //    sendButton.backgroundColor = [UIColor clearColor];
        //    sendButton.layer.cornerRadius = 13; 
        //    sendButton.clipsToBounds = YES;
        [self resetSendButton]; // disable initially
        [self addSubview:sendButton];
        
        CGRect labelFrame = CGRectMake(self.frame.size.width - 70.0f, 2.0f, 64.0f, 26.0f);
        countLabel = [[UILabel alloc] initWithFrame: labelFrame];
        countLabel.backgroundColor = [UIColor clearColor];
        countLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleLeftMargin;
        countLabel.text = @"asokalsklas";
        [countLabel setHidden: YES];
        [self addSubview: countLabel];
        
    }
    return self;
}
- (void) updateHeight: (CGFloat) height{
    if ([self.delegate respondsToSelector: @selector(chatBar:didChangeHeight:)]) {
        [self.delegate chatBar: self didChangeHeight: height];
    }
}

- (void) sendItemAction: (id) sender {
    
    if ([_delegate respondsToSelector:@selector(chatBar:didSendText:)]) {
        [self.delegate chatBar: self didSendText: chatInput.text];
    }
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat contentHeight = textView.contentSize.height - kMessageFontSize + 2.0f;
    NSString *rightTrimmedText = @"";
    
    //    NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
    //    NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right,
    //          textView.contentInset.bottom, textView.contentInset.left);
    //    NSLog(@"contentSize.height: %f", contentHeight);
    
    if ([textView hasText]) {
        rightTrimmedText = [textView.text
                            stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
        
        countLabel.text = [NSString stringWithFormat: @"%i", [rightTrimmedText length]];
        
        //        if (textView.text.length > 1024) { // truncate text to 1024 chars
        //            textView.text = [textView.text substringToIndex:1024];
        //        }
        
        // Resize textView to contentHeight
        if (contentHeight != previousContentHeight) {
            NSLog(@"prev: %f", previousContentHeight);
            NSLog(@"heig: %f", contentHeight);
            if (contentHeight <= kContentHeightMax) { // limit chatInputHeight <= 4 lines
                NSLog(@"<<");
                CGFloat chatBarHeight = contentHeight + 18.0f;
                
                [self updateHeight:chatBarHeight]; 
                //SET_CHAT_BAR_HEIGHT(chatBarHeight);
                
                if (contentHeight > 22.0f) {
                    [countLabel setHidden: NO];
                }else {
                    [countLabel setHidden: YES];
                }
                
                
                if (previousContentHeight > kContentHeightMax) {
                    textView.scrollEnabled = NO;
                }
                textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
            //    [self scrollToBottomAnimated:YES];
            } else if (previousContentHeight <= kContentHeightMax) { // grow
                NSLog( @"grow");
                textView.scrollEnabled = YES;
                textView.contentOffset = CGPointMake(0.0f, contentHeight-68.0f); // shift to bottom
                if (previousContentHeight < kContentHeightMax) {
                    
                    
                    [self updateHeight: kChatBarHeight4];
                    
                //    EXPAND_CHAT_BAR_HEIGHT;
                //    [self scrollToBottomAnimated:YES];
                }
            }else {
           //     [countLabel setHidden: YES];
            }
        }
    } else { // textView is empty
        if (previousContentHeight > 22.0f) {
            [self updateHeight: kChatBarHeight1];
            
            //RESET_CHAT_BAR_HEIGHT;
            if (previousContentHeight > kContentHeightMax) {
                textView.scrollEnabled = NO;
            }
        }
        textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
    }
    
    // Enable sendButton if chatInput has non-blank text, disable otherwise.
    if (rightTrimmedText.length > 0) {
        [self enableSendButton];
    } else {
        [self disableSendButton];
    }
    
    previousContentHeight = contentHeight;
}

// Fix a scrolling quirk.
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    textView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    return YES;
}

- (void)enableSendButton {
    if (sendButton.enabled == NO) {
        sendButton.enabled = YES;
        sendButton.titleLabel.alpha = 1.0f;
    }
}

- (void)disableSendButton {
    if (sendButton.enabled == YES) {
        [self resetSendButton];
    }
}

- (void)resetSendButton {
    sendButton.enabled = NO;
    sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
}


- (void)clearChatInput {
    chatInput.text = @"";
    if (previousContentHeight > 22.0f) {
        [self updateHeight: kChatBarHeight1];
        
        //RESET_CHAT_BAR_HEIGHT;
        chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
        chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
    //    [self scrollToBottomAnimated:YES];       
    }
    
    [countLabel setHidden: YES];
}

- (void) resetCharInput {
    chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
    
}

@end
