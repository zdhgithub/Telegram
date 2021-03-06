#import "TGCallMessageViewModel.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGCallDiscardReason.h"

#import "TGModernImageViewModel.h"
#import "TGModernTextViewModel.h"
#import "TGModernButtonViewModel.h"
#import "TGModernButtonView.h"
#import "TGModernFlatteningViewModel.h"

#import <LegacyComponents/TGDoubleTapGestureRecognizer.h>

#import "TGPresentation.h"

@interface TGCallMessageViewModel ()
{
    int32_t _callForMessageId;
    
    TGModernImageViewModel *_iconModel;
    TGModernTextViewModel *_typeModel;
    TGModernTextViewModel *_timeModel;
    TGModernButtonViewModel *_callButtonModel;
}
@end

@implementation TGCallMessageViewModel

- (instancetype)initWithMessage:(TGMessage *)message actionMedia:(TGActionMediaAttachment *)actionMedia authorPeer:(id)__unused authorPeer additionalUsers:(NSArray *)__unused additionalUsers context:(TGModernViewContext *)context
{
    _inhibitChecks = true;
    self = [super initWithMessage:message authorPeer:nil viaUser:nil context:context];
    if (self != nil)
    {
        _callForMessageId = message.mid;

        static UIImage *incomingGreenIcon = nil;
        static UIImage *incomingRedIcon = nil;
        static UIImage *outgoingGreenIcon = nil;
        static UIImage *outgoingRedIcon = nil;
        static int32_t presentationId;
        
        if (presentationId != context.presentation.currentId)
        {
            presentationId = context.presentation.currentId;
            
            incomingGreenIcon = TGTintedWithAlphaImage(TGImageNamed(@"MessageCallIncomingIcon"), context.presentation.pallete.chatIncomingCallSuccessfulColor);
            incomingRedIcon = TGTintedWithAlphaImage(TGImageNamed(@"MessageCallIncomingIcon"), context.presentation.pallete.chatIncomingCallFailedColor);
            
            outgoingGreenIcon = TGTintedWithAlphaImage(TGImageNamed(@"MessageCallOutgoingIcon"), context.presentation.pallete.chatOutgoingCallSuccessfulColor);
            outgoingRedIcon = TGTintedWithAlphaImage(TGImageNamed(@"MessageCallOutgoingIcon"), context.presentation.pallete.chatOutgoingCallFailedColor);
        }
        
        bool outgoing = message.outgoing;
        int reason = [actionMedia.actionData[@"reason"] intValue];
        bool missed = reason == TGCallDiscardReasonMissed || reason == TGCallDiscardReasonBusy;
        
        NSString *type = TGLocalized(missed ? (outgoing ? @"Notification.CallCanceled" : @"Notification.CallMissed") : (outgoing ? @"Notification.CallOutgoing" : @"Notification.CallIncoming"));
        
        int callDuration = [actionMedia.actionData[@"duration"] intValue];
        NSString *duration = missed || callDuration < 1 ? nil : [TGStringUtils stringForCallDurationSeconds:callDuration];
        NSString *time = [TGDateUtils stringForShortTime:(int)message.date daytimeVariant:NULL];
        
        if (duration != nil)
            time = [NSString stringWithFormat:TGLocalized(@"Notification.CallFormat"), time, duration];
        
        _typeModel = [[TGModernTextViewModel alloc] initWithText:type font:TGCoreTextMediumFontOfSize(16.0f)];
        _typeModel.maxNumberOfLines = 1;
        _typeModel.textColor = _incomingAppearance ? _context.presentation.pallete.chatIncomingTextColor : _context.presentation.pallete.chatOutgoingTextColor;
        [_contentModel addSubmodel:_typeModel];
        
        _timeModel = [[TGModernTextViewModel alloc] initWithText:time font:TGCoreTextSystemFontOfSize(13.0f)];
        _timeModel.maxNumberOfLines = 1;
        _timeModel.textColor = _incomingAppearance ? _context.presentation.pallete.chatIncomingSubtextColor : _context.presentation.pallete.chatOutgoingSubtextColor;
        [_contentModel addSubmodel:_timeModel];
        
        _iconModel = [[TGModernImageViewModel alloc] init];
        _iconModel.image = outgoing ? (missed ? outgoingRedIcon : outgoingGreenIcon) : (missed ? incomingRedIcon : incomingGreenIcon);
        [_contentModel addSubmodel:_iconModel];
        
        __weak TGCallMessageViewModel *weakSelf = self;
        _callButtonModel = [[TGModernButtonViewModel alloc] init];
        _callButtonModel.pressed = ^
        {
            __strong TGCallMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf callPressed];
        };
        _callButtonModel.image = _incomingAppearance ? _context.presentation.images.chatCallIconIncoming : _context.presentation.images.chatCallIconOutgoing;
        _callButtonModel.modernHighlight = true;
        [self addSubmodel:_callButtonModel];
        
        [_contentModel removeSubmodel:(TGModernViewModel *)_dateModel viewStorage:nil];
        [_contentModel removeSubmodel:(TGModernViewModel *)_editedLabelModel viewStorage:nil];
    }
    return self;
}

- (void)callPressed
{
    [_context.companionHandle requestAction:@"callRequested" options:@{@"mid": @(_callForMessageId), @"immediate": @true}];
}

- (void)doubleTapGestureRecognizerSingleTapped:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    [self callPressed];
}

- (void)layoutContentForHeaderHeight:(CGFloat)__unused headerHeight
{
    _typeModel.frame = CGRectMake(2.0f, 6.0f, _typeModel.frame.size.width, _typeModel.frame.size.height);
    _timeModel.frame = CGRectMake(16.0f, 30.0f, _timeModel.frame.size.width, _timeModel.frame.size.height);
    _iconModel.frame = CGRectMake(3.0f, 36.5f, 9.0f, 9.0f);
    
    CGFloat typeWidth = _typeModel.frame.size.width;
    CGFloat timeWidth = _timeModel.frame.size.width;
    CGFloat width = MIN(typeWidth, timeWidth) + fabs(typeWidth - timeWidth);
    width = MAX(110, width);
    _callButtonModel.frame = CGRectMake(_contentModel.frame.origin.x + width + 18.0f, _contentModel.frame.origin.y + 4.0f, 50.0f, 50.0f);
}

- (CGSize)contentSizeForContainerSize:(CGSize)containerSize needsContentsUpdate:(bool *)needsContentsUpdate infoWidth:(CGFloat)__unused infoWidth
{
    CGSize typeContainerSize = CGSizeMake(MIN(200, containerSize.width - 18), containerSize.height);
    bool updateTypeContents = [_typeModel layoutNeedsUpdatingForContainerSize:typeContainerSize additionalTrailingWidth:0.0f layoutFlags:0];
    if (updateTypeContents)
        [_typeModel layoutForContainerSize:typeContainerSize];
    
    CGSize timeContainerSize = CGSizeMake(MAX(_typeModel.frame.size.width, containerSize.width - 30.0f), containerSize.height);
    bool updateTimeContents = [_timeModel layoutNeedsUpdatingForContainerSize:timeContainerSize additionalTrailingWidth:0.0f layoutFlags:0];
    if (updateTimeContents)
        [_timeModel layoutForContainerSize:timeContainerSize];
    
    CGFloat typeWidth = _typeModel.frame.size.width;
    CGFloat timeWidth = _timeModel.frame.size.width;
    CGFloat width = MIN(typeWidth, timeWidth) + fabs(typeWidth - timeWidth);
    width = MAX(110, width);
    
    *needsContentsUpdate = updateTypeContents || updateTimeContents;
    
    return CGSizeMake(width + 60.0f, 52.0f);
}

@end
