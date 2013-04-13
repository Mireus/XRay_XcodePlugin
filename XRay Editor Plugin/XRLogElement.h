//
//  LogElement.h
//  XRay Editor
//
//  Created by Greg Kucsan on 1/2/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#define XRPLog(t); [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"XRayEditorSendLogNotification" object:nil userInfo:[NSDictionary dictionaryWithObject:( t ) forKey:@"data"] deliverImmediately:YES];


#import <Foundation/Foundation.h>

@interface XRLogElement : NSObject

@property (nonatomic, retain) NSString *classString;
@property (nonatomic, retain) NSString *superClassString;

@property (nonatomic, retain) NSMutableArray *changesArray;

@property (nonatomic, assign) BOOL selected;

@end
