//
//  ColorBackgroundView.m
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 2/6/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#import "XRColorBackgroundView.h"

@implementation XRColorBackgroundView

@synthesize bgColor;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        bgColor = [NSColor clearColor];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect fullRect = NSMakeRect(0, 1, NSWidth(dirtyRect),NSHeight(dirtyRect)-1);

    // Drawing code here.
    [bgColor setFill];
    NSRectFill(fullRect);

    [[NSColor whiteColor] set];
    

    NSBezierPath *fullPath = [NSBezierPath bezierPathWithRect:NSInsetRect(fullRect, 1, 1)];
    [fullPath setLineWidth:2];
    [fullPath setLineCapStyle:NSButtLineCapStyle];
    [fullPath stroke];
}

- (void)dealloc
{
    [bgColor release];
    
    [super dealloc];
}

@end
