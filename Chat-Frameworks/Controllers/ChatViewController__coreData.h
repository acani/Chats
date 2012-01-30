//
//  ChatViewController__coreData.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"
#import <CoreData/CoreData.h>
@interface ChatViewController__coreData : ChatViewController
<NSFetchedResultsControllerDelegate>

{
    NSManagedObjectContext *managedObjectContext;
    
    NSFetchedResultsController *fetchedResultsController;

}

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;


- (void)fetchResults;


@end
