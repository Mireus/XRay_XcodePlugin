//
//  XRScrollView.m
//  XRay Editor Plugin
//
//  Created by Greg Kucsan on 12/31/12.
//  Copyright (c) 2012 Greg Kucsan. All rights reserved.
//

#import "XRScrollView.h"
#import "XROutlineView.h"

#import "XRLogElement.h"
#import "XRFeedbackData.h"

#import "XRCellView.h"

@implementation XRScrollView

@synthesize logData,plugin,maxWidth;

-(BOOL)isFlipped
{
    return YES;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        //Drop shadow
        NSShadow *dropShadow = [[NSShadow alloc] init];
        [dropShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.423 alpha:1.000]];
        [dropShadow setShadowOffset:NSMakeSize(0, 5.0)];
        [dropShadow setShadowBlurRadius:10.0];
        
        [self setWantsLayer:YES];
        [self setShadow:dropShadow];
        
		[dropShadow release];
        
        self.scrollerStyle = NSScrollerStyleOverlay;
        self.scrollerKnobStyle = NSScrollerKnobStyleDefault;
        
        outlineView = [[XROutlineView alloc] initWithFrame:NSMakeRect(20, 0, NSWidth(self.frame)-20, NSHeight(self.frame))];
        
        outlineView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [outlineView setHeaderView:nil];
        
        [self addSubview:outlineView];
        
        // create columns for our table
        NSTableColumn * outlineColumn = [[NSTableColumn alloc] initWithIdentifier:@"Column"];
        
        [outlineView setDoubleAction:@selector(doubleClickReceived:)];
        [outlineView setTarget:self];
        
        [outlineColumn setWidth:180];
        [outlineColumn setEditable:NO];
        [outlineView addTableColumn:outlineColumn];
        [outlineView setDelegate:self];
        [outlineView setDataSource:self];
        
		[outlineColumn.dataCell setControlSize:NSMiniControlSize];
		[outlineColumn.dataCell setFont:[NSFont systemFontOfSize:11]];
		
        [outlineView setOutlineTableColumn:outlineColumn];
        
        [self setDocumentView:outlineView];
        [self setHasVerticalScroller:YES];
        
        [outlineView release];
        [outlineColumn release];
        
		[outlineView reloadData];
        
        floatformatter = [[NSNumberFormatter alloc] init];
        floatformatter.maximumFractionDigits = 3;
        floatformatter.minimumFractionDigits = 1;
        floatformatter.minimumIntegerDigits = 1;
        
    }
    
    return self;
}

-(void)dealloc
{
    [plugin release];
    
    [logData release];
    [lastSelected release];
    
    [floatformatter release];
    
    [super dealloc];
}


-(void)setLogData:(NSMutableArray *)_logData
{
    [_logData retain];
    [logData release];
    logData = _logData;
    
    if (logData.count) {
        XRLogElement *zero = [logData objectAtIndex:0];
        [lastSelected release];
        lastSelected = [zero retain];
        zero.selected = YES;
    }
    
    [outlineView reloadData];
    
    [outlineView expandItem:nil expandChildren:YES];
    
    if (logData.count) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    
    //Calculate the width
    maxWidth = 100;
    
    for (XRLogElement *thisElement in logData) {

        //calculate max width
        NSString *superClass = [NSString stringWithFormat:@"UI%@",thisElement.superClassString];
        
        NSString *text = nil;
        
        if (![thisElement.classString isEqualToString:superClass] && thisElement.superClassString) {
            text = [NSString stringWithFormat:@"%@ (%@)",thisElement.classString,superClass];
        } else {
            text = thisElement.classString;
        }
        
        NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
        [string addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11] range:NSMakeRange(0,text.length)];
        [string addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:11] range:NSMakeRange(0,thisElement.classString.length)];
        
        NSSize size = [string size];
        
        maxWidth = MAX(maxWidth, size.width + 40);
                
        for (FeedbackElement *thatElement in thisElement.changesArray) {
            
            NSMutableAttributedString *string2 = [[[NSMutableAttributedString alloc] initWithString:[self createLabelFromFeedback:thatElement]] autorelease];
            [string2 addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Menlo-Regular" size:11] range:NSMakeRange(0,string2.length)];
            
            NSSize size2 = [string2 size];
            
            CGFloat colorWidth = 0;
            
            if ([self colorFromFeedbackElement:thatElement]) {
                colorWidth = 35;
            }
            
            maxWidth = MAX(maxWidth, size2.width + colorWidth + 60);
        }
    }    
}

-(void)setTheFrameTo:(NSRect)theRect
{
    ///Height
    CGFloat height = 0;
    
    
    for (XRLogElement *thisElement in logData) {
        height += 17;
    
        for (FeedbackElement *thatElement in thisElement.changesArray) {
            height += 17;
        }
    }
    
    CGFloat newHeight = MIN(theRect.size.height, height);
    
    CGFloat oldMaxY = NSMaxY(theRect);
    
    self.frame = NSMakeRect(NSMinX(theRect), oldMaxY - newHeight, maxWidth, newHeight);
}

#pragma mark - NSOutlineViewDelegate

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) {
        return YES;
    } else if ([item isKindOfClass:[XRLogElement class]]) {
        return YES;
    } else {
		return NO;
	}
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return logData.count;
    } else if ([item isKindOfClass:[XRLogElement class]]) {
        return ((XRLogElement *)item).changesArray.count;
    } else {
		return 0;
	}
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    [cell setControlSize:NSMiniControlSize];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    [cell setControlSize:NSMiniControlSize];
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 15;
}

-(NSView *)outlineView:(NSOutlineView *)_outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    XRCellView *result = [_outlineView makeViewWithIdentifier:@"MyView" owner:self];
    
    if (result == nil) {
        
        result = [[[XRCellView alloc] initWithFrame:CGRectMake(0, 0, NSWidth(self.frame)-21, 15)] autorelease];
        
        result.identifier = @"MyView";
    }
    
    NSMutableAttributedString *string = nil;
    
    if ([item isKindOfClass:[XRLogElement class]]) {
        
        XRLogElement *thisLogItem = (XRLogElement *)item;
        
        result.code = NO;
        
        NSString *text = nil;
        
        NSString *superClass = [NSString stringWithFormat:@"UI%@",thisLogItem.superClassString];
        
        if (![thisLogItem.classString isEqualToString:superClass] && thisLogItem.superClassString) {
            text = [NSString stringWithFormat:@"%@ (%@)",thisLogItem.classString,superClass];
        } else {
            text = thisLogItem.classString;
        }
        
        string = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
        [string addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11] range:NSMakeRange(0,text.length)];
        [string addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:11] range:NSMakeRange(0,thisLogItem.classString.length)];
        
        
        result.cellText = string;
        result.cellColor = nil;
        
        result.selected = thisLogItem.selected;
        
    } else {
        
        FeedbackElement *thisFeedbackItem = (FeedbackElement *)item;
        
        result.code = YES;
        
        string = [[[NSMutableAttributedString alloc] initWithString:[self createLabelFromFeedback:thisFeedbackItem]] autorelease];
        [string addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Menlo-Regular" size:11] range:NSMakeRange(0,string.length)];
        
        //order !
        result.cellText = string;
        result.cellColor = [self colorFromFeedbackElement:thisFeedbackItem];
        
        result.selected = thisFeedbackItem.selected;
        
        if (result.selected) {
            [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:item]] byExtendingSelection:NO];
        }
        
	}
    
    return result;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [logData objectAtIndex:index];
    } else if ([item isKindOfClass:[XRLogElement class]]) {
        return [((XRLogElement *)item).changesArray objectAtIndex:index];
    } else {
		return nil;
	}
    
}

#pragma mark - Text creation

-(NSString *)createLabelFromFeedback:(FeedbackElement *)item
{
    NSMutableString *returnString = [NSMutableString stringWithString:item.setterMethodString];
    
    [returnString replaceOccurrencesOfString:@"set" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, 3)];
    
    NSString *firstChar = [returnString substringToIndex:1];
    
    [returnString replaceOccurrencesOfString:firstChar withString:[firstChar lowercaseString] options:NSCaseInsensitiveSearch range:NSMakeRange(0, 1)];
    
    switch (item.elementType) {
        case FeedbackElementBool:{
            [returnString appendFormat:@"%@",([item.wrappedValue boolValue])?@"YES":@"NO"];
            break;
        }
        case FeedbackElementInteger:{
            [returnString appendString:item.wrappedValue];
            break;
        }
        case FeedbackElementUnsignedInteger:{
            [returnString appendString:item.wrappedValue];
            break;
        }
        case FeedbackElementFloat:{
            [returnString appendFormat:@"%@f",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[item.wrappedValue floatValue]]]];
            break;
        }
        case FeedbackElementRect:{
            
            NSRect newFrame = NSRectFromString(item.wrappedValue);
            
            [returnString appendFormat:@"(%1.1ff, %1.1ff, %1.1ff, %1.1ff)",newFrame.origin.x,newFrame.origin.y,newFrame.size.width,newFrame.size.height];
            break;
        }
        case FeedbackElementSize:{
            
            NSSize newSize = NSSizeFromString(item.wrappedValue);
            
            [returnString appendFormat:@"(%1.1ff, %1.1ff)",newSize.width,newSize.height];
            break;
        }
        case FeedbackElementOffset:{
            
            NSArray *components = [item.wrappedValue componentsSeparatedByString:@"|"];
            
            [returnString appendFormat:@"(%@f, %@f)",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[0] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[1] floatValue]]]];
            
            break;
        }
        case FeedbackElementInset:{
            NSArray *components = [item.wrappedValue componentsSeparatedByString:@"|"];
            
            [returnString appendFormat:@"(%@f, %@f, %@f, %@f)];\n\t",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[0] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[1] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[2] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[3] floatValue]]]];
            break;
        }
        case FeedbackElementColor:{
            [returnString appendString:[self colorFromWrappedItemString:item.wrappedValue liveCodeSyntax:NO]];
            break;
        }
        case FeedbackElementText:{
            [returnString appendFormat:@"\"%@\"",item.wrappedValue];
            break;
        }
        case FeedbackElementFont:{
            
            [returnString appendFormat:@"%@",[self fontDisplayStringFromWrapeditemString:item.wrappedValue]];
            
            break;
        }
        case FeedbackElementImageSource:{
            
            [returnString appendFormat:@"%@",item.wrappedValue];
            
            break;
        }
        case FeedbackElementControlStateTitle:{
            
            NSArray *messageComponents = [item.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [returnString componentsSeparatedByString:@":"];
            
            returnString = [NSMutableString stringWithFormat:@"%@:@\"%@\" %@:%@",[methodParts objectAtIndex:0],[messageComponents objectAtIndex:1],[methodParts objectAtIndex:1],[[self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"UIControlState" withString:@""]];
            
            break;
        }
        case FeedbackElementControlStateColor:{
            
            
            NSArray *messageComponents = [item.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [returnString componentsSeparatedByString:@":"];
            
            NSString *colorString = [self colorFromWrappedItemString:[messageComponents objectAtIndex:1] liveCodeSyntax:NO];
            NSString *controlString = [[self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"UIControlState" withString:@""];
            
            
            returnString = [NSMutableString stringWithFormat:@"%@:(%@) %@:%@",[methodParts objectAtIndex:0],colorString,[methodParts objectAtIndex:1],controlString];
            
            break;
        }
        case FeedbackElementControlStateImageName:{
            NSArray *messageComponents = [item.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [returnString componentsSeparatedByString:@":"];
            
            NSString *imageNameString = [messageComponents objectAtIndex:1];
            NSString *controlString = [[self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"UIControlState" withString:@""];
            
            returnString = [NSMutableString stringWithFormat:@"%@:%@ %@:%@",[methodParts objectAtIndex:0],imageNameString,[methodParts objectAtIndex:1],controlString];
            
            break;
        }
        case FeedbackElementBackgroundImageForBarMetrics:{
            NSArray *messageComponents = [item.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [returnString componentsSeparatedByString:@":"];
            
            NSString *imageNameString = [messageComponents objectAtIndex:1];
            NSString *controlString = [[self barMetricsFromWrappeditemString:[messageComponents objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"UIBarMetrics" withString:@""];
            
            returnString = [NSMutableString stringWithFormat:@"%@:%@ %@:%@",[methodParts objectAtIndex:0],imageNameString,[methodParts objectAtIndex:1],controlString];
            
            break;
        }
        case FeedbackElementTitleVerticalAdjustmentForBarMetrics:{
            NSArray *messageComponents = [item.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [returnString componentsSeparatedByString:@":"];
            
            NSString *controlString = [[self barMetricsFromWrappeditemString:[messageComponents objectAtIndex:0]] stringByReplacingOccurrencesOfString:@"UIBarMetrics" withString:@""];
            
            returnString = [NSMutableString stringWithFormat:@"%@:%@ %@:%@",[methodParts objectAtIndex:0],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[[messageComponents objectAtIndex:1] floatValue]]],[methodParts objectAtIndex:1],controlString];
            
            break;
        }
        case FeedbackElementPerformSelector:{
            
            break;
        }
        case FeedbackElementAutoresizingMask:{
            [returnString appendString:[[self autoresizeFromWrappedItemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIViewAutoresizingFlexible" withString:@""]];
            break;
        }
        case FeedbackElementContentMode:{
            [returnString appendString:[[self contentModeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIViewContentMode" withString:@""]];
            break;
        }
        case FeedbackElementIndicatorStyle:{
            [returnString appendString:[[self indicatorStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIScrollViewIndicatorStyle" withString:@""]];
            break;
        }
        case FeedbackElementTextalignment:{
            [returnString appendString:[[self textAlignmentFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"NSTextAlignment" withString:@""]];
            break;
        }
        case FeedbackElementLineBreak:{
            [returnString appendString:[[self lineBreakFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"NSLineBreakBy" withString:@""]];
            break;
        }
		case FeedbackElementBaselineAdjustment:{
            [returnString appendString:[[self baselineAdjustmentFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIBaselineAdjustment" withString:@""]];
			break;
		}
        case FeedbackElementControlContentHorizontalAlignment:{
            [returnString appendString:[[self contentHorizontalAlignmentFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIControlContentHorizontalAlignment" withString:@""]];
            break;
        }
        case FeedbackElementControlContentVerticalAlignment:{
            [returnString appendString:[[self contentVerticalAlignmentFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIControlContentVerticalAlignment" withString:@""]];
            break;
        }
        case FeedbackElementProgressViewStyle:{
            [returnString appendString:[[self progressViewStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIProgressViewStyle" withString:@""]];
            break;
        }
        case FeedbackElementBarStyle:{
            [returnString appendString:[[self barStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIBarStyle" withString:@""]];
            break;
        }
        case FeedbackElementAutocapitalizationType:{
            [returnString appendString:[[self autocapitalizationTypeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITextAutocapitalizationType" withString:@""]];
            break;
        }
        case FeedbackElementAutocorrectionType:{
            [returnString appendString:[[self textAutocorrectionTypeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITextAutocorrectionType" withString:@""]];
            break;
        }
        case FeedbackElementKeyboardType:{
            [returnString appendString:[[self keyboardTypeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIKeyboardType" withString:@""]];
            break;
        }
        case FeedbackElementSpellCheckingType:{
            [returnString appendString:[[self textSpellCheckingTypeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITextSpellCheckingType" withString:@""]];
            break;
        }
        case FeedbackElementCellAccessoryType:{
            [returnString appendString:[[self cellAccessoryTypeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITableViewCellAccessoryType" withString:@""]];
            break;
        }
        case FeedbackElementCellSelectionStyle:{
            [returnString appendString:[[self cellSelectionStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITableViewCellSelectionStyle" withString:@""]];
            break;
        }
        case FeedbackElementCellSeparatorStyle:{
            [returnString appendString:[[self cellSeparatorStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITableViewCellSeparatorStyle" withString:@""]];
            break;
        }
        case FeedbackElementTextBorderStyle:{
            [returnString appendString:[[self textBorderStyleFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITextBorderStyle" withString:@""]];
            break;
        }
        case FeedbackElementTextFieldViewMode:{
            [returnString appendString:[[self textFieldViewModeFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UITextFieldViewMode" withString:@""]];
            break;
        }
        case FeedbackElementDataDetectorType:{
            [returnString appendString:[[self dataDetectorTypeFromWrappedItemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIDataDetectorType" withString:@""]];
            break;
        }
        case FeedbackElementDecelerationRate:{
            [returnString appendString:[[self decelerationRateFromWrappeditemString:item.wrappedValue] stringByReplacingOccurrencesOfString:@"UIScrollViewDecelerationRate" withString:@""]];
            break;
        }
            
        default:
            break;
    }
    
    
    return returnString;
}

-(NSColor *)colorFromFeedbackElement:(FeedbackElement *)item
{
    switch (item.elementType) {
        case FeedbackElementColor:
            return [self NSColorFromWrappedItemString:item.wrappedValue];
        case FeedbackElementControlStateColor:{
            return [self NSColorFromWrappedItemString:[[item.wrappedValue componentsSeparatedByString:@"|-|"] objectAtIndex:1]];
        }
        default:
            return nil;
    }
}

-(NSString *)createInsertTextForCurrentSelection
{
    NSMutableString *stringToInsert = [NSMutableString string];
    
    NSString *currentObjectVariable = [plugin getHighlightedObjectName];
    
    if ([lastSelected isKindOfClass:[XRLogElement class]]) {
        
        XRLogElement *selectedLog = (XRLogElement *)lastSelected;
        
        for (FeedbackElement *thisFeedback in selectedLog.changesArray) {
            [stringToInsert appendString:[self createLineFromFeedback:thisFeedback forObjectName:currentObjectVariable]];
        }
        
    } else if([lastSelected isKindOfClass:[FeedbackElement class]]){
        
        FeedbackElement *selectedFeedback = (FeedbackElement *)lastSelected;
        
        [stringToInsert appendString:[self createLineFromFeedback:selectedFeedback forObjectName:currentObjectVariable]];
        
    }
    
    return stringToInsert;
}

-(NSString *)createLineFromFeedback:(FeedbackElement *)thisFeedback forObjectName:(NSString *)objectName
{
    NSMutableString *lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ %@",objectName,thisFeedback.setterMethodString]];
    
    
    switch (thisFeedback.elementType) {
        case FeedbackElementBool:{
            [lineToInsert appendFormat:@"%@];\n\t",([thisFeedback.wrappedValue boolValue])?@"YES":@"NO"];
            break;
        }
        case FeedbackElementInteger:{
            [lineToInsert appendFormat:@"%@];\n\t",thisFeedback.wrappedValue];
            break;
        }
        case FeedbackElementUnsignedInteger:{
            [lineToInsert appendFormat:@"%@];\n\t",thisFeedback.wrappedValue];
            break;
        }
        case FeedbackElementFloat:{
            [lineToInsert appendFormat:@"%@f];\n\t",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[thisFeedback.wrappedValue floatValue]]]];
            
            break;
        }
        case FeedbackElementRect:{
            
            NSRect newFrame = NSRectFromString(thisFeedback.wrappedValue);
            
            [lineToInsert appendFormat:@"CGRectMake(%1.1ff, %1.1ff, %1.1ff, %1.1ff)];\n\t",newFrame.origin.x,newFrame.origin.y,newFrame.size.width,newFrame.size.height];
            break;
        }
        case FeedbackElementSize:{
            NSSize newSize = NSSizeFromString(thisFeedback.wrappedValue);
            
            [lineToInsert appendFormat:@"CGSizeMake(%1.1ff, %1.1ff)];\n\t",newSize.width,newSize.height];
            break;
        }
        case FeedbackElementOffset:{
            NSArray *components = [thisFeedback.wrappedValue componentsSeparatedByString:@"|"];
            
            [lineToInsert appendFormat:@"UIOffsetMake(%@f, %@f)];\n\t",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[0] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[1] floatValue]]]];
            break;
        }
        case FeedbackElementInset:{
            NSArray *components = [thisFeedback.wrappedValue componentsSeparatedByString:@"|"];
            
            [lineToInsert appendFormat:@"UIEdgeInsetsMake(%@f, %@f, %@f, %@f)];\n\t",[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[0] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[1] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[2] floatValue]]],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[components[3] floatValue]]]];
            break;
        }
        case FeedbackElementColor:{
            NSString *colorString = [self colorFromWrappedItemString:thisFeedback.wrappedValue liveCodeSyntax:YES];
            [lineToInsert appendFormat:@"[UIColor %@]];\n\t",colorString];
            break;
        }
        case FeedbackElementText:{
            [lineToInsert appendFormat:@"@\"%@\"];\n\t",thisFeedback.wrappedValue];
            break;
        }
        case FeedbackElementFont:{
            [lineToInsert appendFormat:@"[UIFont %@]];\n\t",[self fontCreationStringFromWrapeditemString:thisFeedback.wrappedValue]];
            
            break;
        }
        case FeedbackElementImageSource:{
            
            if ([thisFeedback.wrappedValue isEqualToString:@"nil"]) {
                [lineToInsert appendString:@"nil"];
            } else {
                [lineToInsert appendFormat:@"[UIImage imageNamed:@\"%@\"]",thisFeedback.wrappedValue];
            }
            
            [lineToInsert appendString:@"];\n\t"];
            
            break;
        }
        case FeedbackElementControlStateTitle:{
            NSArray *messageComponents = [thisFeedback.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [thisFeedback.setterMethodString componentsSeparatedByString:@":"];
            
            lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ ",objectName]];
            
            [lineToInsert appendFormat:@"%@:@\"%@\" %@:%@];\n\t",[methodParts objectAtIndex:0],[messageComponents objectAtIndex:1],[methodParts objectAtIndex:1],[self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]]];
            break;
        }
        case FeedbackElementControlStateColor:{
            
            NSArray *messageComponents = [thisFeedback.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [thisFeedback.setterMethodString componentsSeparatedByString:@":"];
            
            lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ ",objectName]];
            
            NSString *colorString = [self colorFromWrappedItemString:[messageComponents objectAtIndex:1] liveCodeSyntax:YES];
            NSString *controlString = [self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]];
            
            [lineToInsert appendFormat:@"%@:[UIColor %@] %@:%@];\n\t",[methodParts objectAtIndex:0],colorString,[methodParts objectAtIndex:1],controlString];
            break;
        }
        case FeedbackElementControlStateImageName:{
            
            NSArray *messageComponents = [thisFeedback.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [thisFeedback.setterMethodString componentsSeparatedByString:@":"];
            
            lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ ",objectName]];
            
            NSString *imageNameString = [messageComponents objectAtIndex:1];
            
            NSString *imageCreationString = @"nil";
            
            if (![imageNameString isEqualToString:@"nil"]) {
                imageCreationString = [NSString stringWithFormat:@"[UIImage imageNamed:@\"%@\"]",imageNameString];
            }
            
            NSString *controlString = [self controlStateFromWrappeditemString:[messageComponents objectAtIndex:0]];
            
            [lineToInsert appendFormat:@"%@:%@ %@:%@];\n\t",[methodParts objectAtIndex:0],imageCreationString,[methodParts objectAtIndex:1],controlString];
            break;
        }
        case FeedbackElementBackgroundImageForBarMetrics:{
            NSArray *messageComponents = [thisFeedback.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [thisFeedback.setterMethodString componentsSeparatedByString:@":"];
            
            lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ ",objectName]];
            
            NSString *imageNameString = [messageComponents objectAtIndex:1];
            
            NSString *imageCreationString = @"nil";
            
            if (![imageNameString isEqualToString:@"nil"]) {
                imageCreationString = [NSString stringWithFormat:@"[UIImage imageNamed:@\"%@\"]",imageNameString];
            }
            
            NSString *barMetricsString = [self barMetricsFromWrappeditemString:[messageComponents objectAtIndex:0]];
            
            [lineToInsert appendFormat:@"%@:%@ %@:%@];\n\t",[methodParts objectAtIndex:0],imageCreationString,[methodParts objectAtIndex:1],barMetricsString];
            break;
        }
        case FeedbackElementTitleVerticalAdjustmentForBarMetrics:{
            NSArray *messageComponents = [thisFeedback.wrappedValue componentsSeparatedByString:@"|-|"];
            
            NSArray *methodParts = [thisFeedback.setterMethodString componentsSeparatedByString:@":"];
            
            lineToInsert = [NSMutableString stringWithString:[NSString stringWithFormat:@"[%@ ",objectName]];
            
            NSString *barMetricsString = [self barMetricsFromWrappeditemString:[messageComponents objectAtIndex:0]];
            
            [lineToInsert appendFormat:@"%@:%@f %@:%@];\n\t",[methodParts objectAtIndex:0],[floatformatter stringFromNumber:[NSNumber numberWithFloat:[[messageComponents objectAtIndex:1] floatValue]]],[methodParts objectAtIndex:1],barMetricsString];
            break;
        }
        case FeedbackElementPerformSelector:{
            
            break;
        }
        case FeedbackElementAutoresizingMask:{
            [lineToInsert appendFormat:@"%@];\n\t",[self autoresizeFromWrappedItemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementContentMode:{
            [lineToInsert appendFormat:@"%@];\n\t",[self contentModeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementIndicatorStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self indicatorStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementTextalignment:{
            [lineToInsert appendFormat:@"%@];\n\t",[self textAlignmentFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementLineBreak:{
            [lineToInsert appendFormat:@"%@];\n\t",[self lineBreakFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
		case FeedbackElementBaselineAdjustment:{
            [lineToInsert appendFormat:@"%@];\n\t",[self baselineAdjustmentFromWrappeditemString:thisFeedback.wrappedValue]];
			break;
		}
        case FeedbackElementControlContentHorizontalAlignment:{
            [lineToInsert appendFormat:@"%@];\n\t",[self contentHorizontalAlignmentFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementControlContentVerticalAlignment:{
            [lineToInsert appendFormat:@"%@];\n\t",[self contentVerticalAlignmentFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementProgressViewStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self progressViewStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementBarStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self barStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementAutocapitalizationType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self autocapitalizationTypeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementAutocorrectionType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self textAutocorrectionTypeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementKeyboardType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self keyboardTypeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementSpellCheckingType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self textSpellCheckingTypeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementCellAccessoryType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self cellAccessoryTypeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementCellSelectionStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self cellSelectionStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementCellSeparatorStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self cellSeparatorStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementTextBorderStyle:{
            [lineToInsert appendFormat:@"%@];\n\t",[self textBorderStyleFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementTextFieldViewMode:{
            [lineToInsert appendFormat:@"%@];\n\t",[self textFieldViewModeFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementDataDetectorType:{
            [lineToInsert appendFormat:@"%@];\n\t",[self dataDetectorTypeFromWrappedItemString:thisFeedback.wrappedValue]];
            break;
        }
        case FeedbackElementDecelerationRate:{
            [lineToInsert appendFormat:@"%@];\n\t",[self decelerationRateFromWrappeditemString:thisFeedback.wrappedValue]];
            break;
        }
        default:
            break;
    }
    
    return lineToInsert;
}

#pragma mark - Selection

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (lastSelected != nil) {
        [self setElement:lastSelected selected:NO];
    }
    
    [self setElement:item selected:YES];
    
//    @synchronized(lastSelected){
        [item retain];
        [lastSelected release];
        lastSelected = item;
//    }
    
    return YES;
}

-(void)setElement:(id)element selected:(BOOL)selected
{
    if ([outlineView rowForItem:element] >= 0 ) {
        XRCellView *view = (XRCellView *)[outlineView viewAtColumn:0 row:[outlineView rowForItem:element] makeIfNecessary:YES];
        
        view.selected = selected;
    }
    
    if ([element isKindOfClass:[XRLogElement class]]) {
        ((XRLogElement *)element).selected = selected;
    } else if([element isKindOfClass:[FeedbackElement class]]){
        ((FeedbackElement *)element).selected = selected;
	}
}

-(void)enterKeyPressed:(XROutlineView *)_outlineView
{
    [self insertCurrentSelection];
}

-(void)doubleClickReceived:(id)sender
{
    [self insertCurrentSelection];
}

-(void)insertCurrentSelection
{
    NSString *stringToInsert = [self createInsertTextForCurrentSelection];
    
    if ([plugin respondsToSelector:@selector(insertTextAtCurrentPosition:)]) {
        [plugin performSelector:@selector(insertTextAtCurrentPosition:) withObject:stringToInsert];
    }
}


#define float_epsilon 0.001
#define float_equal(a,b) (fabs((a) - (b)) < float_epsilon)

-(NSString *)colorFromWrappedItemString:(NSString *)wrappedString liveCodeSyntax:(BOOL)liveCode
{
    NSArray *inputArray = [wrappedString componentsSeparatedByString:@"|"];
    
    NSDictionary *constantColorsByName = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [[NSColor blackColor] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]], @"blackColor",
                                          [NSColor darkGrayColor], @"darkGrayColor",
                                          [NSColor lightGrayColor], @"lightGrayColor",
                                          [[NSColor whiteColor] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]], @"whiteColor",
                                          [NSColor grayColor], @"grayColor",
                                          [NSColor redColor], @"redColor",
                                          [NSColor greenColor], @"greenColor",
                                          [NSColor blueColor], @"blueColor",
                                          [NSColor cyanColor], @"cyanColor",
                                          [NSColor yellowColor], @"yellowColor",
                                          [NSColor magentaColor], @"magentaColor",
                                          [NSColor orangeColor], @"orangeColor",
                                          [NSColor purpleColor], @"purpleColor",
                                          [NSColor brownColor], @"brownColor",
                                          [[NSColor clearColor] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]], @"clearColor", nil];
    
    NSString *returnString = nil;
    
    for (NSString *key in constantColorsByName) {
        
        NSColor *thisColor = [constantColorsByName objectForKey:key];
        
        CGFloat _red = 0.0, _green = 0.0, _blue = 0.0, _alpha = 0.0, _cyan = 0.0, _magenta = 0.0, _yellow = 0.0, _black = 0.0;
        
        CGFloat components[inputArray.count];
        [thisColor getComponents:(CGFloat *)&components];
        
        _red = components[0];
        _green = components[1];
        _blue = components[2];
        _alpha = components[3];
        
        if (inputArray.count == 5) {///CMYK
            
            _black   = MIN(MIN(1-_red,1-_green),1-_blue);
            _cyan    = (1-_red-_black)/(1-_black);
            _magenta = (1-_green-_black)/(1-_black);
            _yellow  = (1-_blue-_black)/(1-_black);
            
            if (float_equal(_cyan, [[inputArray objectAtIndex:0] floatValue]) && float_equal(_magenta, [[inputArray objectAtIndex:1] floatValue]) && float_equal(_yellow, [[inputArray objectAtIndex:2] floatValue]) && float_equal(_black, [[inputArray objectAtIndex:3] floatValue]) && float_equal(_alpha, [[inputArray objectAtIndex:4] floatValue])) {
                
                returnString = key;
                
                break;
            }
            
        } else if (inputArray.count == 4) {///RGBA
            if (float_equal(_red, [[inputArray objectAtIndex:0] floatValue]) && float_equal(_green, [[inputArray objectAtIndex:1] floatValue]) && float_equal(_blue, [[inputArray objectAtIndex:2] floatValue]) && float_equal(_alpha, [[inputArray objectAtIndex:3] floatValue])) {
                
                returnString = key;
                
                break;
            }
        } else if (inputArray.count == 2) {///RGBA
            if (float_equal(_cyan, [[inputArray objectAtIndex:0] floatValue]) && float_equal(_magenta, [[inputArray objectAtIndex:0] floatValue]) && float_equal(_yellow, [[inputArray objectAtIndex:0] floatValue]) && float_equal(_alpha, [[inputArray objectAtIndex:1] floatValue])) {
                
                returnString = key;
                
                break;
            }
        }
    }
    
    [constantColorsByName release];
    
    if (returnString == nil) {
        switch (inputArray.count) {
            case 2:{
                if (liveCode) {
                    returnString = [NSString stringWithFormat:@"colorWithWhite:%1.3f alpha:%1.3f",[[inputArray objectAtIndex:0] floatValue],[[inputArray objectAtIndex:1] floatValue]];
                } else {
                    returnString = [NSString stringWithFormat:@"white:%1.3f alpha:%1.3f",[[inputArray objectAtIndex:0] floatValue],[[inputArray objectAtIndex:1] floatValue]];
                }
                break;
            }
            case 4:{
                if (liveCode) {
                    returnString = [NSString stringWithFormat:@"colorWithRed:%1.3f green:%1.3f blue:%1.3f alpha:%1.3f",[[inputArray objectAtIndex:0] floatValue],[[inputArray objectAtIndex:1] floatValue],[[inputArray objectAtIndex:2] floatValue],[[inputArray objectAtIndex:3] floatValue]];
                } else {
                    returnString = [NSString stringWithFormat:@" r:%1.3f g:%1.3f b:%1.3f a:%1.3f",[[inputArray objectAtIndex:0] floatValue],[[inputArray objectAtIndex:1] floatValue],[[inputArray objectAtIndex:2] floatValue],[[inputArray objectAtIndex:3] floatValue]];
                }
                break;
            }
            case 5:{
                CGFloat _red = 0.0, _green = 0.0, _blue = 0.0, _alpha = 0.0, _cyan = 0.0, _magenta = 0.0, _yellow = 0.0, _black = 0.0;
                
                _cyan = [[inputArray objectAtIndex:0] floatValue];
                _magenta = [[inputArray objectAtIndex:1] floatValue];
                _yellow = [[inputArray objectAtIndex:2] floatValue];
                _black = [[inputArray objectAtIndex:3] floatValue];
                _alpha = [[inputArray objectAtIndex:4] floatValue];
                
                _red = (1-_black)*(1-_cyan);
                _green = (1-_black)*(1-_magenta);
                _blue = (1-_black)*(1-_yellow);
                
                if (liveCode) {
                    returnString = [NSString stringWithFormat:@"colorWithRed:%1.3f green:%1.3f blue:%1.3f alpha:%1.3f",_red,_green,_blue,_alpha];
                } else {
                    returnString = [NSString stringWithFormat:@" r:%1.3f g:%1.3f b:%1.3f a:%1.3f",_red,_green,_blue,_alpha];
                }
                break;
            }
            default:
                break;
        }
    }
    
    return returnString;
}

-(NSColor *)NSColorFromWrappedItemString:(NSString *)wrappedString
{
    NSArray *inputArray = [wrappedString componentsSeparatedByString:@"|"];
    
    NSColor *returnColor = [NSColor colorWithCalibratedRed:[[inputArray objectAtIndex:0] floatValue] green:[[inputArray objectAtIndex:1] floatValue] blue:[[inputArray objectAtIndex:2] floatValue] alpha:[[inputArray objectAtIndex:3] floatValue]];
    
    return returnColor;
}

-(NSString *)autoresizeFromWrappedItemString:(NSString *)wrappedString
{
    NSMutableArray *returnElements = [NSMutableArray array];
    
    NSInteger resizingMaskValue = [wrappedString integerValue];
    
    if (resizingMaskValue >= 32) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleBottomMargin"];
        resizingMaskValue -= 32;
    }
    if (resizingMaskValue >= 16) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleHeight"];
        resizingMaskValue -= 16;
    }
    if (resizingMaskValue >= 8) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleTopMargin"];
        resizingMaskValue -= 8;
    }
    if (resizingMaskValue >= 4) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleRightMargin"];
        resizingMaskValue -= 4;
    }
    if (resizingMaskValue >= 2) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleWidth"];
        resizingMaskValue -= 2;
    }
    if (resizingMaskValue == 1) {
        [returnElements addObject:@"UIViewAutoresizingFlexibleLeftMargin"];
    }
    
    return [returnElements componentsJoinedByString:@"|"];
}

-(NSString *)contentModeFromWrappeditemString:(NSString *)wrapedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIViewContentModeScaleToFill",
                       @"UIViewContentModeScaleAspectFit",
                       @"UIViewContentModeScaleAspectFill",
                       @"UIViewContentModeRedraw",
                       @"UIViewContentModeCenter",
                       @"UIViewContentModeTop",
                       @"UIViewContentModeBottom",
                       @"UIViewContentModeLeft",
                       @"UIViewContentModeRight",
                       @"UIViewContentModeTopLeft",
                       @"UIViewContentModeTopRight",
                       @"UIViewContentModeBottomLeft",
                       @"UIViewContentModeBottomRight", nil];
    
    return [values objectAtIndex:[wrapedString integerValue]];
}

-(NSString *)indicatorStyleFromWrappeditemString:(NSString *)wrapedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIScrollViewIndicatorStyleDefault",
                       @"UIScrollViewIndicatorStyleBlack",
                       @"UIScrollViewIndicatorStyleWhite", nil];
    
    return [values objectAtIndex:[wrapedString integerValue]];
}

-(NSString *)controlStateFromWrappeditemString:(NSString *)wrapedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIControlStateNormal",@"UIControlStateHighlighted",@"UIControlStateDisabled",@"Not used",@"UIControlStateSelected", nil];
    return [values objectAtIndex:[wrapedString integerValue]];
}

-(NSString *)barMetricsFromWrappeditemString:(NSString *)wrapedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIBarMetricsDefault",@"UIBarMetricsLandscapePhone", nil];
    return [values objectAtIndex:[wrapedString integerValue]];
}

-(NSString *)textAlignmentFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"NSTextAlignmentLeft",@"NSTextAlignmentCenter",@"NSTextAlignmentRight",@"NSTextAlignmentJustified",@"NSTextAlignmentNatural", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)lineBreakFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"NSLineBreakByWordWrapping",@"NSLineBreakByCharWrapping",@"NSLineBreakByClipping",@"NSLineBreakByTruncatingHead",@"NSLineBreakByTruncatingTail",@"NSLineBreakByTruncatingMiddle", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)fontDisplayStringFromWrapeditemString:(NSString *)wrapedString
{
    NSArray *components = [wrapedString componentsSeparatedByString:@"|"];
    NSString *fontName = [components objectAtIndex:0];
    CGFloat fontSize = [[components objectAtIndex:1] floatValue];
    
    NSString *returnValue = nil;
    
    if ([fontName isEqualToString:@".HelveticaNeueUI"]) {
        //system
        returnValue = [NSString stringWithFormat:@"System - %1.1ff",fontSize];
    } else if([fontName isEqualToString:@".HelveticaNeueUI-Bold"]){
        returnValue = [NSString stringWithFormat:@"System Bold - %1.1ff",fontSize];
	} else if ([fontName isEqualToString:@".HelveticaNeueUI-Oblique"]){
        returnValue = [NSString stringWithFormat:@"System Itallic - %1.1ff",fontSize];
    }  else {
		returnValue = [NSString stringWithFormat:@"%@ - %1.1ff",fontName,fontSize];
	}
    
    return returnValue;
}

-(NSString *)fontCreationStringFromWrapeditemString:(NSString *)wrapedString
{
    NSArray *components = [wrapedString componentsSeparatedByString:@"|"];
    NSString *fontName = [components objectAtIndex:0];
    CGFloat fontSize = [[components objectAtIndex:1] floatValue];
    
    NSString *returnValue = nil;
    
    if ([fontName isEqualToString:@".HelveticaNeueUI"]) {
        //system
        returnValue = [NSString stringWithFormat:@"systemFontOfSize:%1.1ff",fontSize];
    } else if([fontName isEqualToString:@".HelveticaNeueUI-Bold"]){
        returnValue = [NSString stringWithFormat:@"boldSystemFontOfSize:%1.1ff",fontSize];
	} else if ([fontName isEqualToString:@".HelveticaNeueUI-Oblique"]){
        returnValue = [NSString stringWithFormat:@"italicSystemFontOfSize:%1.1ff",fontSize];
    }  else {
		returnValue = [NSString stringWithFormat:@"fontWithName:@\"%@\" size:%1.1ff",fontName,fontSize];
	}
    
    return returnValue;
}

-(NSString *)baselineAdjustmentFromWrappeditemString:(NSString *)wrapedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIBaselineAdjustmentAlignBaselines",@"UIBaselineAdjustmentAlignCenters",@"UIBaselineAdjustmentNone", nil];
    return [values objectAtIndex:[wrapedString integerValue]];
}

-(NSString *)contentHorizontalAlignmentFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIControlContentHorizontalAlignmentCenter",@"UIControlContentHorizontalAlignmentLeft",@"UIControlContentHorizontalAlignmentRight",@"UIControlContentHorizontalAlignmentFill", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)contentVerticalAlignmentFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIControlContentVerticalAlignmentCenter",@"UIControlContentVerticalAlignmentTop",@"UIControlContentVerticalAlignmentBottom",@"UIControlContentVerticalAlignmentFill", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)progressViewStyleFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIProgressViewStyleDefault",@"UIProgressViewStyleBar", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)barStyleFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIBarStyleDefault",@"UIBarStyleBlack", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)autocapitalizationTypeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITextAutocapitalizationTypeNone",@"UITextAutocapitalizationTypeWords",@"UITextAutocapitalizationTypeSentences",@"UITextAutocapitalizationTypeAllCharacters", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)textSpellCheckingTypeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITextSpellCheckingTypeDefault",@"UITextSpellCheckingTypeNo",@"UITextSpellCheckingTypeYes", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)textAutocorrectionTypeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITextAutocorrectionTypeDefault",@"UITextAutocorrectionTypeNo",@"UITextAutocorrectionTypeYes", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)keyboardTypeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIKeyboardTypeDefault",@"UIKeyboardTypeASCIICapable",@"UIKeyboardTypeNumbersAndPunctuation",@"UIKeyboardTypeURL",@"UIKeyboardTypeNumberPad",@"UIKeyboardTypePhonePad",@"UIKeyboardTypeNamePhonePad",@"UIKeyboardTypeEmailAddress",@"UIKeyboardTypeDecimalPad",@"UIKeyboardTypeTwitter",@"UIKeyboardTypeAlphabet", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)cellAccessoryTypeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITableViewCellAccessoryNone",@"UITableViewCellAccessoryDisclosureIndicator",@"UITableViewCellAccessoryDetailDisclosureButton",@"UITableViewCellAccessoryCheckmark", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)cellSelectionStyleFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITableViewCellSelectionStyleNone",@"UITableViewCellSelectionStyleBlue",@"UITableViewCellSelectionStyleGray", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)cellSeparatorStyleFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITableViewCellSeparatorStyleNone",@"UITableViewCellSeparatorStyleSingleLine",@"UITableViewCellSeparatorStyleSingleLineEtched", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)textBorderStyleFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITextBorderStyleNone",@"UITextBorderStyleLine",@"UITextBorderStyleBezel",@"UITextBorderStyleRoundedRect", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)textFieldViewModeFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UITextFieldViewModeNever",@"UITextFieldViewModeWhileEditing",@"UITextFieldViewModeUnlessEditing",@"UITextFieldViewModeAlways", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}

-(NSString *)dataDetectorTypeFromWrappedItemString:(NSString *)wrappedString
{
    NSMutableArray *returnElements = [NSMutableArray array];
    
    NSUInteger dataDetectorTypeValue = (NSUInteger)[[NSDecimalNumber decimalNumberWithString:wrappedString] longLongValue];
    
    if (dataDetectorTypeValue == 0) {
        [returnElements addObject:@"UIDataDetectorTypeNone"];
    } else if (dataDetectorTypeValue > 3000){
        [returnElements addObject:@"UIDataDetectorTypeAll"];
    } else {
        
        if (dataDetectorTypeValue >= 8) {
            [returnElements addObject:@"UIDataDetectorTypeCalendarEvent"];
            dataDetectorTypeValue -= 8;
        }
        if (dataDetectorTypeValue >= 4) {
            [returnElements addObject:@"UIDataDetectorTypeAddress"];
            dataDetectorTypeValue -= 4;
        }
        if (dataDetectorTypeValue >= 2) {
            [returnElements addObject:@"UIDataDetectorTypeLink"];
            dataDetectorTypeValue -= 2;
        }
        if (dataDetectorTypeValue == 1) {
            [returnElements addObject:@"UIDataDetectorTypePhoneNumber"];
        }
        
	}
    
    return [returnElements componentsJoinedByString:@"|"];
}

-(NSString *)decelerationRateFromWrappeditemString:(NSString *)wrappedString
{
    NSArray *values = [NSArray arrayWithObjects:@"UIScrollViewDecelerationRateNormal",@"UIScrollViewDecelerationRateFast", nil];
    return [values objectAtIndex:[wrappedString integerValue]];
}


@end
