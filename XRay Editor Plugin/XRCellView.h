//
//  CellView.h
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 1/5/13.
//  Copyright (c) 2013 Greg Kucsan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "XRColorBackgroundView.h"

@interface XRCellView : NSView{    
    NSTextField *textField;
    
    XRColorBackgroundView *colorView;
}

@property (nonatomic, retain) NSAttributedString *cellText;

@property (nonatomic, retain) NSColor *cellColor;


@property (nonatomic, assign) BOOL code;
@property (nonatomic, assign) BOOL selected;


@end
