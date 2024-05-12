//
//  UIApplication+RNIHelpers.m
//  react-native-ios-utilities
//
//  Created by Dominic Go on 5/8/24.
//


#import "UIApplication+RNIHelpers.h"

#if __cplusplus
#import "RCTAppDelegate.h"

#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <React/RCTMountingManager.h>
#import <React/RCTComponentViewRegistry.h>
#import <React/RCTScheduler.h>

#import <react/renderer/uimanager/UIManager.h>
#endif

@implementation UIApplication (RNIHelpers)
#if __cplusplus
- (RCTAppDelegate *)reactAppDelegate
{
  id<UIApplicationDelegate> appDelegate =
    [[UIApplication sharedApplication] delegate];
    
  if(![appDelegate isKindOfClass:[RCTAppDelegate class]]){
    return nil;
  };
  
  return (RCTAppDelegate *) appDelegate;
}

- (RCTSurfacePresenterBridgeAdapter *)reactBridgeAdapter
{
  RCTAppDelegate *reactAppDelegate = [self reactAppDelegate];
  
  if(reactAppDelegate == nil){
    return nil;
  };
  
  return [reactAppDelegate bridgeAdapter];
}

- (RCTRootViewFactory *)reactRootViewFactory
{
  RCTAppDelegate *reactAppDelegate = [self reactAppDelegate];
  
  if(reactAppDelegate == nil){
    return nil;
  };
  
  return [reactAppDelegate rootViewFactory];
}

- (RCTSurfacePresenter *) reactSurfacePresenter
{
  RCTSurfacePresenterBridgeAdapter *reactBridgeAdapter = [self reactBridgeAdapter];
  
  if(reactBridgeAdapter == nil){
    return nil;
  };
  
  return [reactBridgeAdapter surfacePresenter];
}

- (RCTMountingManager *)reactMountingManager
{
  RCTSurfacePresenter *reactSurfacePresenter = [self reactSurfacePresenter];
  
  if(reactSurfacePresenter == nil){
    return nil;
  };
  
  return [reactSurfacePresenter mountingManager];
}

- (RCTComponentViewRegistry *)reactComponentViewRegistry
{
  RCTMountingManager *reactMountingManager = [self reactMountingManager];
  
  if(reactMountingManager == nil){
    return nil;
  };
  
  return [reactMountingManager componentViewRegistry];
}

- (RCTScheduler *)reactScheduler
{
  RCTSurfacePresenter *reactSurfacePresenter = [self reactSurfacePresenter];
  if(reactSurfacePresenter == nil){
    return nil;
  };
  
  return [reactSurfacePresenter scheduler];
}

/// Note - Prefer to use:
/// ```
/// RCTScheduler *reactScheduler = [self reactScheduler];
/// std::shared_ptr<facebook::react::UIManager> = *uiManager [reactScheduler uiManager];
///
/// ```
- (facebook::react::UIManager *)reactUIManager
{
  RCTScheduler *reactScheduler = [self reactScheduler];
  if(reactScheduler == nil){
    return nil;
  };
  
  return [reactScheduler uiManager].get();
}
#endif
@end

