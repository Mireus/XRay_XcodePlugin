//
//  FeedbackData.m
//  Interface Designer
//
//  Created by Greg Kucsan on 10/13/12.
//
//

#import "XRFeedbackData.h"

@implementation XRFeedbackData

@synthesize viewAddress;
@synthesize viewClassString;
@synthesize changesArray;

- (id)init
{
    self = [super init];
    if (self) {
        viewAddress = [[NSString alloc] init];
        viewClassString = [[NSString alloc] init];
        changesArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [viewAddress release];
    [viewClassString release];
    [changesArray release];
    
    [super dealloc];
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.viewAddress forKey:@"viewAddress"];
    [encoder encodeObject:self.viewClassString forKey:@"viewClassString"];
    [encoder encodeObject:self.changesArray forKey:@"changesArray"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.viewAddress = [decoder decodeObjectForKey:@"viewAddress"];
        self.viewClassString = [decoder decodeObjectForKey:@"viewClassString"];
        self.changesArray = [decoder decodeObjectForKey:@"changesArray"];
    }
    return self;
}

- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
                       @"viewAddress",
                       @"viewClassString",
                       @"changesArray",
                       nil];
    
    return result;
}

- (NSString *)descriptionForKeyPaths
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n\n"];
    [desc appendFormat:@"Class name: %@\n", NSStringFromClass([self class])];
    
    NSArray *keyPathsArray = [self keyPaths];
    for (NSString *keyPath in keyPathsArray) {
        [desc appendFormat: @"%@: %@\n", keyPath, [self valueForKey:keyPath]];
    }
    
    return [NSString stringWithString:desc];
}


-(NSString *)description
{
    return [self descriptionForKeyPaths];
}


@end


@implementation FeedbackElement

@synthesize elementType;
@synthesize setterMethodString;
@synthesize wrappedValue;
@synthesize selected;

- (id)init
{
    self = [super init];
    if (self) {
        elementType = FeedbackElementNone;
        setterMethodString = [[NSString alloc] init];
        wrappedValue = [[NSString alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [setterMethodString release];
    [wrappedValue release];
    
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithInt:self.elementType] forKey:@"elementType"];
    [encoder encodeObject:self.setterMethodString forKey:@"setterMethodString"];
    [encoder encodeObject:self.wrappedValue forKey:@"wrappedValue"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.elementType = [[decoder decodeObjectForKey:@"elementType"] integerValue];
        self.setterMethodString = [decoder decodeObjectForKey:@"setterMethodString"];
        self.wrappedValue = [decoder decodeObjectForKey:@"wrappedValue"];
    }
    return self;
}

- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
                       @"elementType",
                       @"setterMethodString",
                       @"wrappedValue",
                       nil];
    
    return result;
}

- (NSString *)descriptionForKeyPaths
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n\n"];
    [desc appendFormat:@"Class name: %@\n", NSStringFromClass([self class])];
    
    NSArray *keyPathsArray = [self keyPaths];
    for (NSString *keyPath in keyPathsArray) {
        [desc appendFormat: @"%@: %@\n", keyPath, [self valueForKey:keyPath]];
    }
    
    return [NSString stringWithString:desc];
}


-(NSString *)description
{
    return [self descriptionForKeyPaths];
}


@end