#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Conversation *conversation;

@end
