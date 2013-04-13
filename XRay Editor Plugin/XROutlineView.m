//
//  XROutlineView.m
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 1/6/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#import "XROutlineView.h"
#import "XRLogElement.h"

@implementation XROutlineView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//-(NSRect)frameOfOutlineCellAtRow:(NSInteger)row
//{
//    return NSZeroRect;
//}
//
//-(NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
//{
//    NSRect defaultRect = [super frameOfCellAtColumn:column row:row];
//    return NSOffsetRect(defaultRect, -12, 0);
//}

- (void)keyDown:(NSEvent *) theEvent
{
    NSString *chars = [theEvent charactersIgnoringModifiers];

    if ([theEvent type] == NSKeyDown && [chars length] == 1) {
        
        int val = [chars characterAtIndex:0];
    
        if (val == 13 /*return*/ || val == 32 /*space bar*/) {
            if ([self.delegate respondsToSelector:@selector(enterKeyPressed:)]) {
                [self.delegate performSelector:@selector(enterKeyPressed:) withObject:self];
            }
            return;
        }
    }
    
    [super keyDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{    
   if ([theEvent clickCount] == 2){
        if ([self.delegate respondsToSelector:@selector(enterKeyPressed:)]) {
            [self.delegate performSelector:@selector(enterKeyPressed:) withObject:self];
        }
        return;
    }
    
    [super mouseUp:theEvent];

}

@end
