//
//  XrayEditorPlugin.m
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 12/29/12.
//  Copyright (c) 2012 Greg Kucsan. All rights reserved.
//


#define kHintViewMaxHeight 150

#import "XRayEditorPlugin.h"

#import "XRLogElement.h"
#import "XRFeedbackData.h"

@interface XRayEditorPlugin ()

@end

@implementation XRayEditorPlugin

@synthesize textView;
@synthesize selectedTextRange;

+ (void)pluginDidLoad:(NSBundle *)bundle
{
	static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPlugin = [[self alloc] init];
	});
}

- (id)init
{
	if (self = [super init]) {
                
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
        
        ///Start listening for changes notification
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedXRayChanges:) name:XRayEditorChangesSentNotification object:nil];

        
        ///Create the hint view
        hintScrollView = [[XRScrollView alloc] initWithFrame:NSZeroRect];
        hintScrollView.plugin = self;
        
        self.selectedTextRange = NSMakeRange(NSNotFound, 0);
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    ///Add menu item
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
	if (editMenuItem) {
		[[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *xraychangesHintListShow = [[[NSMenuItem alloc] initWithTitle:@"Show Xray Editor Changes" action:@selector(shortcutCallInitiated) keyEquivalent:@""] autorelease];
        [xraychangesHintListShow setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask];
        [xraychangesHintListShow setKeyEquivalent:@"x"];
        
		[xraychangesHintListShow setTarget:self];
		[[editMenuItem submenu] addItem:xraychangesHintListShow];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(shortcutCallInitiated)) {
		return hintScrollView.logData.count != 0;
	} else {
		return YES;
	}
}

-(void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    ///Ask for the changes list from XRay Editor
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:XRayEditorPluginRequestsChangesNotification object:nil userInfo:nil deliverImmediately:YES];
}

#pragma mark Changes from XRay Editor

-(void)receivedXRayChanges:(NSNotification *)notification
{
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    
    NSDictionary *logDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
    
    NSMutableArray *logElementsArray = [NSMutableArray array];
    
    for (NSString *thisKey in logDictionary) {
        [logElementsArray addObject:[logDictionary objectForKey:thisKey]];
    }
    
    hintScrollView.logData = logElementsArray;
}

#pragma mark - Shortcut call

-(void)shortcutCallInitiated
{
    if (self.textView == nil){
        NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
		if ([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [firstResponder isKindOfClass:[NSTextView class]]) {
			self.textView = (NSTextView *)firstResponder;
            [self.textView setWantsLayer:YES];
		} else {
			NSBeep();
			return;
		}
    }
        
    NSArray *selectedRanges = [self.textView selectedRanges];
    
    if (selectedRanges.count >= 1) {
        NSRange selectedRange = [[selectedRanges objectAtIndex:0] rangeValue];
        NSString *text = self.textView.textStorage.string;
        NSRange lineRange = [text lineRangeForRange:selectedRange];
        NSRange selectedRangeInLine = NSMakeRange(selectedRange.location - lineRange.location, selectedRange.length);
        NSString *line = [text substringWithRange:lineRange];
        
        [highlightedObjectName release];
        highlightedObjectName = [[NSString alloc] initWithString:[line substringWithRange:selectedRangeInLine]];
        
        self.selectedTextRange = selectedRange;
		
        [self showHintScrollView];
    } else {
        selectedTextRange = NSMakeRange(NSNotFound, 0);
        [self hideHintScrollView];
    }
}


#pragma mark - Text Selection Handling

- (void)selectionDidChange:(NSNotification *)notification
{
		
	if ([[notification object] isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [[notification object] isKindOfClass:[NSTextView class]]) {
	
        if (self.textView != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:self.textView.superview];
        }

        self.textView = (NSTextView *)[notification object];
        [self.textView setWantsLayer:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:self.textView.superview];

        selectedTextRange = NSMakeRange(NSNotFound, 0);
        [self hideHintScrollView];
		
    }
}

-(NSRect)calculateHintScrollViewRect
{
    CGFloat width = hintScrollView.maxWidth;
    
    NSRect selectionRectOnScreen = [self.textView firstRectForCharacterRange:self.selectedTextRange];
    NSRect selectionRectInWindow = [self.textView.window convertRectFromScreen:selectionRectOnScreen];
    NSRect selectionRectInTabView = [self.textView convertRect:selectionRectInWindow fromView:nil];
    NSRect selectionRectInScrollView = [textView.superview.superview convertRect:selectionRectInWindow fromView:nil];
    
    //Width
    CGFloat selectionStart = NSMinX(selectionRectInScrollView);// - 30;
    CGFloat scrollViewWidth = NSWidth(textView.superview.superview.frame);
    CGFloat startPosition = MIN(selectionStart, scrollViewWidth - width - 30) ;
    CGFloat xCorrection = startPosition - selectionStart;
    
    //Height
    CGFloat selectionTop = NSMinY(selectionRectInScrollView);// + 15;
    CGFloat height = MIN(selectionTop, kHintViewMaxHeight);
    NSRect hintScrollViewRect = NSZeroRect;
    
    if (height > 13) {
        hintScrollViewRect = NSMakeRect(NSMinX(selectionRectInTabView)/*-30*/ + xCorrection, NSMinY(selectionRectInTabView) - height, width, height);
    }

    return NSIntegralRect(hintScrollViewRect);
}
	
///When scrolling the DVTSourceTextScrollView
-(void)boundsDidChange:(NSNotification *)notification
{
    [self hideHintScrollView];
    
    [hiddenTimer invalidate];
    [hiddenTimer release];
    hiddenTimer = nil;

    hiddenTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showHintScrollView) userInfo:nil repeats:NO] retain];
}

-(void)hideHintScrollView
{
    if (hintScrollView.superview == nil) {
        return;
    }

    [hintScrollView removeFromSuperview];
}

-(void)showHintScrollView
{
    if (hiddenTimer) {
        [hiddenTimer release];
        hiddenTimer = nil;
    }
    
    if (selectedTextRange.location == NSNotFound) {
        return;
    }

    [hintScrollView setTheFrameTo:[self calculateHintScrollViewRect]];

	[self.textView addSubview:hintScrollView];
    
    [hintScrollView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01];
}

-(NSString *)getHighlightedObjectName
{
    if (highlightedObjectName.length != 0) {
        return highlightedObjectName;
    } else {
		return @"<#Your View#>";
	}

}

-(void)insertTextAtCurrentPosition:(NSString *)textToInsert
{
    [self.textView.undoManager beginUndoGrouping];
    [self.textView insertText:textToInsert replacementRange:self.textView.selectedRange];
	[self.textView.undoManager endUndoGrouping];
    
    [[NSApp keyWindow] makeFirstResponder:self.textView];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
 
    [textView release];
    
    [highlightedObjectName release];
    [hintScrollView release];
    
    [super dealloc];
}

@end