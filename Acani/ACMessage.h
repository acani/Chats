#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACConversation;

@interface ACMessage : NSManagedObject

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) ACConversation *conversation;

@end
