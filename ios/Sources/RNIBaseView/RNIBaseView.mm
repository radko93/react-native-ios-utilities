//
//  RNIBaseView.m
//  react-native-ios-utilities
//
//  Created by Dominic Go on 4/30/24.
//


#import "RNIBaseView.h"

#import "react-native-ios-utilities/Swift.h"
#import "react-native-ios-utilities/UIApplication+RNIHelpers.h"

#import <react-native-ios-utilities/RNIObjcUtils.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RCTFabricComponentsPlugins.h"
#import <React/RCTFollyConvert.h>

#include "RNIBaseViewState.h"
#include "RNIBaseViewProps.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/graphics/Float.h>
#include <react/renderer/core/graphicsConversions.h>
#endif

#if __cplusplus
using namespace facebook;
using namespace react;
#endif

@interface RNIBaseView () <RNIViewLifecycleEventsNotifying>
@end


@implementation RNIBaseView {
  BOOL _didNotifyForInit;
#ifdef RCT_NEW_ARCH_ENABLED
  UIView * _view;
  RNIBaseViewState::SharedConcreteState _state;
  NSMutableArray<UIView *> *_reactSubviews;
#else
  CGRect _reactFrame;
#endif
}

// MARK: - Init
// ------------

#ifdef RCT_NEW_ARCH_ENABLED
- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if(self == nil) {
    return nil;
  }
  
  Class viewDelegateClass = [self viewDelegateClass];
  if(![viewDelegateClass isSubclassOfClass: [UIView class]]) {
    return nil;
  }
  
  if(![viewDelegateClass conformsToProtocol:@protocol(RNIViewLifecycleEventsNotifiable)]) {
    return nil;
  }
  
  UIView<RNIViewLifecycleEventsNotifiable> *viewDelegate =
    [[viewDelegateClass new] initWithFrame:frame];
  
  self.lifecycleEventDelegate = viewDelegate;
  self.contentView = viewDelegate;
  
  BOOL shouldNotifyDelegate =
       !self->_didNotifyForInit
    && [viewDelegate respondsToSelector:@selector(notifyOnInitWithSender:)];
  
  if (shouldNotifyDelegate) {
    self->_didNotifyForInit = YES;
    [viewDelegate notifyOnInitWithSender:self];
  }
  
  [self initCommon];
  return self;
}
#else
- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super init]) {
    self.bridge = bridge;
    [self _reactSubviews];
  }
  
  [self initCommon];
  return self;
}
#endif

- (void)initCommon
{
  // no-op
  // NOTE: to be overridden + impl. by child class
}

// MARK: - Functions
// -----------------

- (void)setSize:(CGSize)size
{
  if(self->_state != nullptr){
    RNIBaseViewState prevState = self->_state->getData();
    RNIBaseViewState newState = RNIBaseViewState(prevState);
    
    auto newSize = [RNIObjcUtils convertToReactSizeForSize:size];
    newState.frameSize = newSize;
    newState.shouldSetSize = true;
    
    self->_state->updateState(std::move(newState));
    [self->_view setNeedsLayout];
  }
};

- (void)setPadding:(UIEdgeInsets)padding
{
  RNIBaseViewState prevState = self->_state->getData();
  RNIBaseViewState newState = RNIBaseViewState(prevState);
  
  auto newPadding = [RNIObjcUtils convertToReactRectangleEdgesForEdgeInsets:padding];
  newState.padding = newPadding;
  newState.shouldSetPadding = true;
  
  self->_state->updateState(std::move(newState));
  [self->_view setNeedsLayout];
}

- (void)setPositionType:(RNIPositionType)positionType
{
  RNIBaseViewState prevState = self->_state->getData();
  RNIBaseViewState newState = RNIBaseViewState(prevState);
  
  newState.positionType =
    [RNIObjcUtils convertToYGPostionTypeForRNIPostionType:positionType];
     
  newState.shouldSetPositionType = true;
  
  self->_state->updateState(std::move(newState));
  [self->_view setNeedsLayout];
}


// MARK: - Fabric Lifecycle
// ------------------------

-(void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView
                         index:(NSInteger)index
{
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnMountChildComponentViewWithSender:childComponentView:index:)];
  
  if(shouldNotifyDelegate){
    [self.lifecycleEventDelegate notifyOnMountChildComponentViewWithSender:self
                                                        childComponentView:childComponentView
                                                                     index:index];
  }
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index
{
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnMountChildComponentViewWithSender:childComponentView:index:)];
  
  if(shouldNotifyDelegate){
    [self.lifecycleEventDelegate notifyOnUnmountChildComponentViewWithSender:self
                                                          childComponentView:childComponentView
                                                                      index:index];
  }
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics
{
  RNILayoutMetrics *layoutMetricsNew = [RNIObjcUtils createRNILayoutMetricsFrom:layoutMetrics];
  self.cachedLayoutMetrics = layoutMetricsNew;

  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnUpdateLayoutMetricsWithSender:oldLayoutMetrics:newLayoutMetrics:)];
  
  if (shouldNotifyDelegate) {
    RNILayoutMetrics *layoutMetricsOld = [RNIObjcUtils createRNILayoutMetricsFrom:oldLayoutMetrics];
    
    [self.lifecycleEventDelegate notifyOnUpdateLayoutMetricsWithSender:self
                                                      oldLayoutMetrics:layoutMetricsOld
                                                      newLayoutMetrics:layoutMetricsNew];
  }
  
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps
{
  const auto &basePropsOld = *std::static_pointer_cast<RNIBaseViewProps const>(_props);
  const auto &basePropsNew = *std::static_pointer_cast<RNIBaseViewProps const>(props);

  NSDictionary *dictPropsOld = ^{
    if(oldProps == nullptr){
      return @{};
    };
    
    return [RNIObjcUtils convertToDictForFollyDynamicMap:basePropsOld.propsMap];
  }();
  
  NSDictionary *dictPropsNew =
    [RNIObjcUtils convertToDictForFollyDynamicMap:basePropsNew.propsMap];
    
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnUpdatePropsWithSender:oldProps:newProps:)];
    
  if(shouldNotifyDelegate){
    [self.lifecycleEventDelegate notifyOnUpdatePropsWithSender:self
                                                      oldProps:dictPropsOld
                                                      newProps:dictPropsNew];
  };

  [super updateProps:props oldProps:oldProps];
}

- (void)updateState:(const State::Shared &)state
           oldState:(const State::Shared &)oldState
{
  auto newState =
    std::static_pointer_cast<const RNIBaseViewState::ConcreteState>(state);
    
  self->_state = newState;
  
  auto newStateData = newState->getData();
  auto newStateDynamic = newStateData.getDynamic();
  
  NSDictionary *newStateDict =
    [RNIObjcUtils convertFollyDynamicToId:&newStateDynamic];
    
  auto _oldState =
    std::static_pointer_cast<const RNIBaseViewState::ConcreteState>(oldState);
  
  std::optional<RNIBaseViewState> oldStateData = std::nullopt;
  
  if(_oldState != nullptr){
    oldStateData = _oldState->getData();
  };
  
  std::optional<folly::dynamic> oldStateDynamic = oldStateData.has_value()
    ? std::make_optional(oldStateData.value().getDynamic())
    : std::nullopt;
  

  NSMutableDictionary *oldStateDict = oldStateDynamic.has_value()
    ? [RNIObjcUtils convertFollyDynamicToId:&newStateDynamic]
    : nil;
    
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnUpdateStateWithSender:oldState:newState:)];
    
  if(shouldNotifyDelegate){
    [self.lifecycleEventDelegate notifyOnUpdateStateWithSender:self
                                                      oldState:oldStateDict
                                                      newState:newStateDict];
  };
    
  [super updateState:state oldState:oldState];
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask
{
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnUnmountChildComponentViewWithSender:childComponentView:index:)];
    
  if(shouldNotifyDelegate){
    RNIComponentViewUpdateMask *swiftMask =
      [[RNIComponentViewUpdateMask new] initWithRawValue:updateMask];
  
    [self.lifecycleEventDelegate notifyOnFinalizeUpdatesWithSender:self
                                                     updateMaskRaw:updateMask
                                                        updateMask:swiftMask];
  }
  
  [super finalizeUpdates:updateMask];
}

-(void) prepareForRecycle
{
  BOOL shouldNotifyDelegate =
       self.lifecycleEventDelegate != nil
    && [self.lifecycleEventDelegate respondsToSelector:@selector(notifyOnPrepareForReuseWithSender:)];
  
  if(shouldNotifyDelegate){
    [self.lifecycleEventDelegate notifyOnPrepareForReuseWithSender:self];
  }
  
  [super prepareForRecycle];
}

// MARK: - Dummy Impl.
// -------------------

// This is meant to be overridden by the subclass
- (Class _Nonnull)viewDelegateClass {
  return [UIView class];
}

@end

