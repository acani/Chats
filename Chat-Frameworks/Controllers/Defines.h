//
//  Defines.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BAR_BUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE\
style:UIBarButtonItemStylePlain target:self action:SELECTOR]

// Exact same color as native iPhone Messages app.
// Achieved by taking a screen shot of the iPhone by pressing Home & Sleep buttons together.
// Then, emailed the image to myself and used Mac's native DigitalColor Meter app.
// Same => [UIColor colorWithRed:219.0/255.0 green:226.0/255.0 blue:237.0/255.0 alpha:1.0];
#define CHAT_BACKGROUND_COLOR [UIColor colorWithRed:0.859f green:0.886f blue:0.929f alpha:1.0f]



// 15 mins between messages before we show the date
#define SECONDS_BETWEEN_MESSAGES        (60*15)


@interface Defines : NSObject

@end
