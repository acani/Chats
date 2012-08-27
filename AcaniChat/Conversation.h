#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSSet *messages;

@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
