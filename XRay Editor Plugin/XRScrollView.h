//
//  XRScrollView.h
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 12/31/12.
//  Copyright (c) 2012 Greg Kucsan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XROutlineView;

@protocol XRSCrollViewDelegate <NSObject>
-(NSString *)getHighlightedObjectName;
-(void)insertTextAtCurrentPosition:(NSString *)textToInsert;
@end

@interface XRScrollView : NSScrollView<NSOutlineViewDataSource,NSOutlineViewDelegate>{
    XROutlineView *outlineView;
    id lastSelected;
    NSNumberFormatter *floatformatter;
}

@property (nonatomic, retain) id<XRSCrollViewDelegate> plugin;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, retain) NSMutableArray *logData;

-(void)setTheFrameTo:(NSRect)theRect;
-(void)enterKeyPressed:(XROutlineView *)_outlineView;

@end
