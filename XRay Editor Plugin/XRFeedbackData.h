//
//  FeedbackData.h
//  Interface Designer
//
//  Created by Greg Kucsan on 10/13/12.
//
//


typedef enum FeedbackElementType{
    FeedbackElementNone,
    FeedbackElementBool,
    FeedbackElementInteger,
    FeedbackElementUnsignedInteger,
    FeedbackElementFloat,
    FeedbackElementRect,
    FeedbackElementSize,
    FeedbackElementOffset,
    FeedbackElementInset,
    FeedbackElementColor,
    FeedbackElementText,
    FeedbackElementFont,
    FeedbackElementImageSource,
    FeedbackElementControlStateTitle,
    FeedbackElementControlStateColor,
    FeedbackElementControlStateImageName,
    FeedbackElementBackgroundImageForBarMetrics,
    FeedbackElementTitleVerticalAdjustmentForBarMetrics,
    FeedbackElementPerformSelector,
    FeedbackElementAutoresizingMask,
    FeedbackElementContentMode,
    FeedbackElementIndicatorStyle,
    FeedbackElementDecelerationRate,
    FeedbackElementTextalignment,
    FeedbackElementLineBreak,
	FeedbackElementBaselineAdjustment,
    FeedbackElementControlContentVerticalAlignment,
    FeedbackElementControlContentHorizontalAlignment,
    FeedbackElementProgressViewStyle,
    FeedbackElementBarStyle,
    FeedbackElementAutocapitalizationType,
    FeedbackElementAutocorrectionType,
    FeedbackElementKeyboardType,
    FeedbackElementSpellCheckingType,
    FeedbackElementCellAccessoryType,
    FeedbackElementCellSelectionStyle,
    FeedbackElementCellSeparatorStyle,
    FeedbackElementTextBorderStyle,
    FeedbackElementTextFieldViewMode,
    FeedbackElementDataDetectorType
}FeedbackElementType;

#define XRayEditorPluginRequestsChangesNotification @"XRayEditorPluginRequestsChanges"
#define XRayEditorChangesSentNotification @"XRayEditorChangesSent"

#import <Foundation/Foundation.h>

@interface XRFeedbackData : NSObject

@property (nonatomic, retain) NSString *viewAddress;
@property (nonatomic, retain) NSString *viewClassString;
@property (nonatomic, retain) NSMutableArray *changesArray;

@end


@interface FeedbackElement : NSObject

@property (nonatomic, assign) FeedbackElementType elementType;
@property (nonatomic, retain) NSString *setterMethodString;
@property (nonatomic, retain) NSString *wrappedValue;
@property (nonatomic, assign) BOOL selected;

@end
