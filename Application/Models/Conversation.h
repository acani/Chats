
#import <CoreData/CoreData.h>
@class Message;

@interface Conversation : NSManagedObject {

}

@property (nonatomic, strong) id lastMessage;
@property (nonatomic, strong) NSSet *messages;

@end
