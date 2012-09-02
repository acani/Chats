#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define FRCPerformFetch(fetchedResultsController) { \
NSError __autoreleasing *error = nil; \
NSAssert([fetchedResultsController performFetch:&error], @"-[NSFetchedResultsController performFetch:] error:\n\n%@", error); }
