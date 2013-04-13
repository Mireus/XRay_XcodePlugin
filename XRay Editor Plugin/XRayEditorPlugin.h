//
//  XrayEditorPlugin.h
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 12/29/12.
//  Copyright (c) 2012 Greg Kucsan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "XRScrollView.h"

@interface XRayEditorPlugin : NSObject<XRSCrollViewDelegate>{
                
    NSString *highlightedObjectName;
    XRScrollView *hintScrollView;
    
    NSTimer *hiddenTimer;
    
    NSTabView *tabView;
}

@property (nonatomic, retain) NSTextView *textView;

@property (nonatomic, assign) NSRange selectedTextRange;

+ (void)pluginDidLoad:(NSBundle *)bundle;

-(NSString *)getHighlightedObjectName;

-(void)insertTextAtCurrentPosition:(NSString *)textToInsert;

@end
