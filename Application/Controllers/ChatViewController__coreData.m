//
//  ChatViewController__coreData.m
//  AcaniChat
//
//  Created by Juguang Xiao on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController__coreData.h"

#import "ChatViewController+Mutability.h"
#import "ChatViewController+Keyboard.h"


#import "Message.h"

@implementation ChatViewController__coreData

@synthesize fetchedResultsController;
@synthesize managedObjectContext;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    //    // Test with lots of messages.
    //    NSDate *before = [NSDate date];
    //    for (NSUInteger i = 0; i < 500; i++) {
    //        Message *msg = (Message *)[NSEntityDescription
    //                                   insertNewObjectForEntityForName:@"Message"
    //                                   inManagedObjectContext:managedObjectContext];
    //    msg.text = [NSString stringWithFormat:@"This is message number %d", i];
    //    NSDate *now = [[NSDate alloc] init]; msg.sentDate = now; [now release];
    //    }z
    ////    sleep(2);
    //    NSLog(@"Creating messages in memory takes %f seconds", [before timeIntervalSinceNow]);
    //    NSError *error;
    //    if (![managedObjectContext save:&error]) {
    //        // TODO: Handle the error appropriately.
    //        NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
    //    }
    //    NSLog(@"Saving messages to disc takes %f seconds", [before timeIntervalSinceNow]);
    
    [self fetchResults];
    
    // Construct cellMap from fetchedObjects.
    cellMap = [[NSMutableArray alloc]
               initWithCapacity:[[fetchedResultsController fetchedObjects] count]*2];
    
    
    for (Message *message in [fetchedResultsController fetchedObjects]) {
        [self addMessage:message];
    }
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.fetchedResultsController = nil;
}
#import "Message.h"

- (id) createNewMessageWithText:(NSString *)text {
    // Create new message and save to Core Data.
    Message *newMessage = (Message *)[NSEntityDescription
                                      insertNewObjectForEntityForName:@"Message"
                                      inManagedObjectContext:managedObjectContext];
    newMessage.text = text;
    NSDate *now = [[NSDate alloc] init]; 
    newMessage.sentDate = now; 
    
    NSError *error;
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"sendMessage error %@, %@", error, [error userInfo]);
    }
    
    return newMessage;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSObject * object = [cellMap objectAtIndex: indexPath.row];
    
    if ([object isKindOfClass:[Message class]]) {
        // Mark message as read.
        // Let's instead do this (asynchronously) from loadView and iterate over all messages
        if (![(Message *)object read]) { // not read, so save as read
            [(Message *)object setRead:[NSNumber numberWithBool:YES]];
            NSError *error;
            if (![managedObjectContext save:&error]) {
                // TODO: Handle the error appropriately.
                NSLog(@"Save message as read error %@, %@", error, [error userInfo]);
            }
        }
    }
    
    return [super tableView: tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark NSFetchedResultsController

- (void)fetchResults {
    if (fetchedResultsController) return;
    
    // Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    // Create the sort descriptors array.
    NSSortDescriptor *tsDesc = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:tsDesc, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Create and initialize the fetchedResultsController.
    fetchedResultsController = [[NSFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                managedObjectContext:managedObjectContext
                                sectionNameKeyPath:nil /* one section */ cacheName:@"Message"];
    
    fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![fetchedResultsController performFetch:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
    }
}    

#pragma mark NSFetchedResultsControllerDelegate

// // beginUpdates & endUpdates cause the cells to get mixed up when scrolling aggressively.
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [chatContent beginUpdates];
//}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSArray *indexPaths;
    
    switch(type) {
        case NSFetchedResultsChangeInsert: {
            NSUInteger cellCount = [cellMap count];
            
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:cellCount inSection:0];
            
            if ([self addMessage:anObject] == 1) {
                //                NSLog(@"insert 1 row at index: %d", cellCount);
                indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath, nil];
            } else { // 2
                //                NSLog(@"insert 2 rows at index: %d", cellCount);
                indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath,
                              [NSIndexPath indexPathForRow:cellCount+1 inSection:0], nil];
            }
            
            [chatContent insertRowsAtIndexPaths:indexPaths
                               withRowAnimation:UITableViewRowAnimationNone];
            [self scrollToBottomAnimated:YES];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            NSUInteger objectIndex = [cellMap indexOfObjectIdenticalTo:anObject];
            NSIndexPath *objectIndexPath = [NSIndexPath indexPathForRow:objectIndex inSection:0];
            
            if ([self removeMessageAtIndex:objectIndex] == 1) {
                //                NSLog(@"delete 1 row");
                indexPaths = [[NSArray alloc] initWithObjects:objectIndexPath, nil];
            } else { // 2
                //                NSLog(@"delete 2 rows");
                indexPaths = [[NSArray alloc] initWithObjects:objectIndexPath,
                              [NSIndexPath indexPathForRow:objectIndex-1 inSection:0], nil];
            }
            
            [chatContent deleteRowsAtIndexPaths:indexPaths
                               withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
    }
}



@end


@implementation ChatViewController__coreData (Mutability)

- (void) clearAllMessage {
    NSError *error;
    fetchedResultsController.delegate = nil;               // turn off delegate callbacks
    for (Message *message in [fetchedResultsController fetchedObjects]) {
        [managedObjectContext deleteObject:message];
    }
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"Delete message error %@, %@", error, [error userInfo]);
    }
    fetchedResultsController.delegate = self;              // reconnect after mass delete
    if (![fetchedResultsController performFetch:&error]) { // resync controller
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
    }

}


- (void) removeMessage:(id)message {
    // Remove message from managed object context by index path.
    [managedObjectContext deleteObject:(Message *)message];
    NSError *error;
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"Delete message error %@, %@", error, [error userInfo]);
    }
}

@end
