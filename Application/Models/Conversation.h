@class Message;

@interface Conversation : NSManagedObject {

}

@property (nonatomic, retain) id lastMessage;
@property (nonatomic, retain) NSSet *messages;

@end
