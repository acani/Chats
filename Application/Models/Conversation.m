#import "Conversation.h"
#import "Message.h"

@implementation Conversation

@dynamic lastMessage;
@dynamic messages;

- (void)addMessagesObject:(Message *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"messages"] addObject:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeMessagesObject:(Message *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"messages"] removeObject:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addMessages:(NSSet *)value {    
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"messages"] unionSet:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeMessages:(NSSet *)value {
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"messages"] minusSet:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
