#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *conversations;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(Conversation *)value;
- (void)removeConversationsObject:(Conversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

@end
