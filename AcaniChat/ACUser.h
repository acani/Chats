#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACConversation;

@interface ACUser : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *conversations;

@end

@interface ACUser (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(ACConversation *)value;
- (void)removeConversationsObject:(ACConversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

@end
