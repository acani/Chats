//
//  ChatViewController+Mutability.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController (Mutability)

- (NSUInteger)addMessage:(id)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

- (void) clearAllMessage; 


- (void) removeMessage: (id) message; 

+ (NSDate *) sendDateInMessage: (id) message; 

+ (void) setIsMine: (BOOL) isMine inMessage: (id) message; 
@end
