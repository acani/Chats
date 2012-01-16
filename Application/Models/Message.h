@interface Message : NSManagedObject {

}

@property (nonatomic, retain) NSDate *sentDate;
@property (nonatomic, retain) NSNumber *read;
@property (nonatomic, retain) NSString *text;

@property (nonatomic, retain) NSNumber * isMine; 

@end
