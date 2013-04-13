//
//  CellView.m
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 1/5/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#import "XRCellView.h"

#import "XRLogElement.h"//just for the log

@implementation XRCellView

@synthesize cellText,code,selected,cellColor;

-(BOOL)isFlipped
{
    return YES;
}
 
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        textField = [[NSTextField alloc] initWithFrame:self.bounds];
        [textField setBezeled:NO];
        [textField setDrawsBackground:NO];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        
        [textField setFont:[NSFont fontWithName:@"Menlo-Regular" size:11]];
//        [textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        textField.textColor = [NSColor blackColor];

        [self addSubview: textField];
        
        [textField release];
        
        colorView = [[[XRColorBackgroundView alloc] initWithFrame:NSZeroRect] autorelease];
        [self addSubview:colorView];
    }
    
    return self;
}

-(void)setCode:(BOOL)_code
{
    code = _code;
    
    if (code) {
        textField.frame = NSMakeRect(0, -3, NSWidth(self.frame), NSHeight(self.frame) + 3);
    } else {
		textField.frame = self.bounds;
	}
}

-(void)setCellText:(NSAttributedString *)_cellText
{
    [_cellText retain];
    [cellText release];
    
    cellText = _cellText;
    
    textField.attributedStringValue = cellText;
    
}

-(void)setCellColor:(NSColor *)_cellColor
{
    [_cellColor retain];
    [cellColor release];
    
    cellColor = _cellColor;
    
    if (cellColor == nil) {
        colorView.frame = NSZeroRect;
    } else {
        NSSize textSize = [cellText size];
        colorView.frame = NSMakeRect(textSize.width + 10, 0, 25, NSHeight(self.bounds));
        colorView.bgColor = cellColor;
	}
    
}

-(void)setSelected:(BOOL)_selected
{
    selected = _selected;
    
    //text color
    if (selected) {
        textField.textColor = [NSColor whiteColor];
    } else {
        textField.textColor = [NSColor blackColor];
	}
}

- (void)dealloc
{
    [cellText release];
    [cellColor release];
    
    [super dealloc];
}

@end
