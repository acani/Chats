#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message, User;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *users;

@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
