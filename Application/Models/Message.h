@interface Message : NSManagedObject {
@private
}

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * text;

@end
