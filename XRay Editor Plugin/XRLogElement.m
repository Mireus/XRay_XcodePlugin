//
//  LogElement.m
//  XRay Editor
//
//  Created by Greg Kucsan on 1/2/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#import "XRLogElement.h"

@implementation XRLogElement
@synthesize classString,superClassString;
@synthesize changesArray;
@synthesize selected;

- (id)init
{
    self = [super init];
    if (self) {
        changesArray = [[NSMutableArray alloc] init];
    }
    return self;
}


- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
                       @"classString",
                       @"superClassString",
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

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.classString forKey:@"classString"];
    [encoder encodeObject:self.superClassString forKey:@"superClassString"];
    [encoder encodeObject:self.changesArray forKey:@"changesArray"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.classString = [decoder decodeObjectForKey:@"classString"];
        self.superClassString = [decoder decodeObjectForKey:@"superClassString"];
        self.changesArray = [decoder decodeObjectForKey:@"changesArray"];
    }
    return self;
}

- (void)dealloc
{
    [classString release];
    [superClassString release];
    [changesArray release];
    
    [super dealloc];
}


@end
