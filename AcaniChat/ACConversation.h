#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACMessage, ACUser;

@interface ACConversation : NSManagedObject

@property (nonatomic, retain) NSString * draft;
@property (nonatomic, retain) NSDate * lastMessageSentDate;
@property (nonatomic, retain) NSString * lastMessageText;
@property (nonatomic, retain) NSNumber * unreadMessagesCount;
@property (nonatomic, retain) NSNumber * messagesLength;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *users;

@end

@interface ACConversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(ACMessage *)value;
- (void)removeMessagesObject:(ACMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addUsersObject:(ACUser *)value;
- (void)removeUsersObject:(ACUser *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
