#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define HOST @"wss://acani-chat.jit.su/"
//#define HOST @"ws://localhost:5000/"

#define MOCSave(managedObjectContext) { \
NSError __autoreleasing *error = nil; \
NSAssert([managedObjectContext save:&error], @"-[NSManagedObjectContext save] error:\n\n%@", error); }

#define MOCFetch(managedObjectContext, fetchRequest) \
NSManagedObjectContextFetch(self, _cmd, managedObjectContext, fetchRequest)

#define MOCDeleteAll(managedObjectContext, entityName, cascadeRelationships) \
NSManagedObjectContextDeleteAll(self, _cmd, managedObjectContext, entityName, cascadeRelationships)

#define FRCPerformFetch(fetchedResultsController) { \
NSError __autoreleasing *error = nil; \
NSAssert([fetchedResultsController performFetch:&error], @"-[NSFetchedResultsController performFetch:] error:\n\n%@", error); }

NS_INLINE NSArray *NSManagedObjectContextFetch(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSFetchRequest *fetchRequest) {
    NSError __autoreleasing *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(fetchedObjects, @"-[NSManagedObjectContext executeFetchRequest:error:] error:\n\n%@", error);
    return fetchedObjects;
}

NS_INLINE void NSManagedObjectContextDeleteAll(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSString *entityName, NSArray *cascadeRelationships) {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.includesPropertyValues = NO;
    fetchRequest.includesPendingChanges = NO;
    fetchRequest.relationshipKeyPathsForPrefetching = cascadeRelationships;
    NSArray *fetchedObjects = MOCFetch(managedObjectContext, fetchRequest);
    for (NSManagedObject *fetchedObject in fetchedObjects) {
        [managedObjectContext deleteObject:fetchedObject];
    }
}
