//
//  RNIUtilitiesTurboModule.cpp
//  react-native-ios-utilities
//
//  Created by Dominic Go on 5/19/24.
//

#if __cplusplus
#include "RNIUtilitiesTurboModule.h"
#include "RNICxxUtils.h"

#include <jsi/JSIDynamic.h>

#if DEBUG
#include <string>
#include <iostream>
#endif

using namespace facebook;
namespace RNIUtilities {

std::function<void(int)> RNIUtilitiesTurboModule::dummyFunction_;
ViewCommandRequestFunction RNIUtilitiesTurboModule::viewCommandRequest_;
ModuleCommandRequestFunction RNIUtilitiesTurboModule::moduleCommandRequest_;

const char RNIUtilitiesTurboModule::MODULE_NAME[] = "RNIUtilitiesModule";

// MARK: - Init + Deinit
// ---------------------

RNIUtilitiesTurboModule::RNIUtilitiesTurboModule(
  std::function<void(int)> dummyFunction,
  ViewCommandRequestFunction viewCommandRequest,
  ModuleCommandRequestFunction moduleCommandRequest
) {
  dummyFunction_ = dummyFunction;
  viewCommandRequest_ = viewCommandRequest;
  moduleCommandRequest_ = moduleCommandRequest;
}

RNIUtilitiesTurboModule::~RNIUtilitiesTurboModule(){
  // no-op
};

// MARK: - JSI Conformance
// -----------------------

jsi::Value RNIUtilitiesTurboModule::get(
  jsi::Runtime &rt,
  const jsi::PropNameID &name
) {

  auto propName = name.utf8(rt);
  if (propName == "dummyFunction") {
    return jsi::Function::createFromHostFunction(rt, name, 1, dummyFunction);
  };
  
  if(propName == "viewCommandRequest"){
    return jsi::Function::createFromHostFunction(rt, name, 3, viewCommandRequest);
  };
  
  if(propName == "moduleCommandRequest"){
    return jsi::Function::createFromHostFunction(rt, name, 3, moduleCommandRequest);
  };
  
  return jsi::Value::undefined();
}

void RNIUtilitiesTurboModule::set(
  jsi::Runtime &,
  const jsi::PropNameID &,
  const jsi::Value &
){
  // no-op
};

std::vector<jsi::PropNameID> RNIUtilitiesTurboModule::getPropertyNames(
  jsi::Runtime &rt
) {
  std::vector<jsi::PropNameID> properties;
  properties.push_back(jsi::PropNameID::forUtf8(rt, "dummyFunction"));
  properties.push_back(jsi::PropNameID::forUtf8(rt, "viewCommandRequest"));
  properties.push_back(jsi::PropNameID::forUtf8(rt, "moduleCommandRequest"));

  return properties;
}

// MARK: - Commands
// ----------------

jsi::Value RNIUtilitiesTurboModule::dummyFunction(
  jsi::Runtime &rt,
  const jsi::Value &thisValue,
  const jsi::Value *arguments,
  size_t count
) {
  if (count < 1) {
    throw jsi::JSError(rt,
      "`dummyFunction` method requires 1 argument."
    );
  }
  
  #if DEBUG
  std::cout << "RNIUtilitiesTurboModule::dummyFunction"
    << "\n - arguments[0]:" << arguments[0].asNumber()
    << std::endl;
  #endif
  
  //int stackTag = arguments[0].asNumber();
  dummyFunction_(-1);
  return jsi::Value::undefined();
}

jsi::Value RNIUtilitiesTurboModule::viewCommandRequest(
  jsi::Runtime &rt,
  const jsi::Value &thisValue,
  const jsi::Value *arguments,
  size_t count
) {

#if DEBUG
  std::cout
    << RNI_DEBUG_STRING
    << " - arg count: " << count
    << std::endl;
#endif


  if (count < 3) {
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Requires 3 arguments")
    );
  }
  
  std::string viewID = [&rt, &arguments]{
    if (arguments[0].isString()){
      auto jsString = arguments[0].asString(rt);
      return jsString.utf8(rt);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `viewID` param must be a string literal")
    );
  }();
  
  std::string commandName = [&rt, &arguments]{
    if (arguments[1].isString()){
      auto jsString = arguments[1].asString(rt);
      return jsString.utf8(rt);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `commandName` param must be a string literal")
    );
  }();
  
  folly::dynamic commandArgs = [&rt, &arguments]{
    if (arguments[2].isObject()){
      return jsi::dynamicFromValue(rt, arguments[2]);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `commandArgs` param must be an object")
    );
  }();
  
  auto promise = rt.global().getPropertyAsFunction(rt, "Promise");
  auto promiseBody = [&viewID, &commandName, &commandArgs](
    jsi::Runtime &rt,
    const jsi::Value &thisValue,
    const jsi::Value *args,
    size_t count
  ) -> jsi::Value {
  
    auto resolve = [&rt, &args]{
      auto resolveValue = std::make_shared<jsi::Value>(rt, args[0]);
      return resolveValue->asObject(rt).asFunction(rt);
    }();
    
    auto reject = [&rt, &args]{
      auto rejectValue = std::make_shared<jsi::Value>(rt, args[1]);
      return rejectValue->asObject(rt).asFunction(rt);
    }();
    
    viewCommandRequest_(
      viewID,
      commandName,
      commandArgs,
      [&rt, &resolve](folly::dynamic resultDyn){
        auto resultValue = jsi::valueFromDynamic(rt, resultDyn);
        resolve.call(rt, std::move(resultValue));
      },
      [&rt, &reject](std::string errorMessage){
        auto jsString = jsi::String::createFromUtf8(rt, errorMessage);
        reject.call(rt, std::move(jsString));
      }
    );
    
    return {};
  };
  
  auto promiseFunction = jsi::Function::createFromHostFunction(
    /* runtime    : */ rt,
    /* name       : */ jsi::PropNameID::forAscii(rt, "executor"),
    /* param count: */  2,
    /* function   : */ promiseBody
  );
  
  return promise.callAsConstructor(rt, promiseFunction);
}

jsi::Value RNIUtilitiesTurboModule::moduleCommandRequest(
  jsi::Runtime &rt,
  const jsi::Value &thisValue,
  const jsi::Value *arguments,
  size_t count
) {

#if DEBUG
  std::cout
    << RNI_DEBUG_STRING
    << " - arg count: " << count
    << std::endl;
#endif

  if (count < 3) {
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Requires 3 arguments")
    );
  }
  
  std::string moduleName = [&rt, &arguments]{
    if (arguments[0].isString()){
      auto jsString = arguments[0].asString(rt);
      return jsString.utf8(rt);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `moduleName` param must be a string literal")
    );
  }();
  
  std::string commandName = [&rt, &arguments]{
    if (arguments[1].isString()){
      auto jsString = arguments[1].asString(rt);
      return jsString.utf8(rt);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `commandName` param must be a string literal")
    );
  }();
  
  folly::dynamic commandArgs = [&rt, &arguments]{
    if (arguments[2].isObject()){
      return jsi::dynamicFromValue(rt, arguments[2]);
    };
    
    throw jsi::JSError(rt,
      RNI_DEBUG_MESSAGE("Argument passed to `commandArgs` param must be an object")
    );
  }();
  
  auto promise = rt.global().getPropertyAsFunction(rt, "Promise");
  auto promiseBody = [&moduleName, &commandName, &commandArgs](
    jsi::Runtime &rt,
    const jsi::Value &thisValue,
    const jsi::Value *args,
    size_t count
  ) -> jsi::Value {
  
    auto resolve = [&rt, &args]{
      auto resolveValue = std::make_shared<jsi::Value>(rt, args[0]);
      return resolveValue->asObject(rt).asFunction(rt);
    }();
    
    auto reject = [&rt, &args]{
      auto rejectValue = std::make_shared<jsi::Value>(rt, args[1]);
      return rejectValue->asObject(rt).asFunction(rt);
    }();
    
    moduleCommandRequest_(
      moduleName,
      commandName,
      commandArgs,
      [&rt, &resolve](folly::dynamic resultDyn){
        auto resultValue = jsi::valueFromDynamic(rt, resultDyn);
        resolve.call(rt, std::move(resultValue));
      },
      [&rt, &reject](std::string errorMessage){
        auto jsString = jsi::String::createFromUtf8(rt, errorMessage);
        reject.call(rt, std::move(jsString));
      }
    );
    
    return {};
  };
  
  auto promiseFunction = jsi::Function::createFromHostFunction(
    /* runtime    : */ rt,
    /* name       : */ jsi::PropNameID::forAscii(rt, "executor"),
    /* param count: */  2,
    /* function   : */ promiseBody
  );
  
  return promise.callAsConstructor(rt, promiseFunction);
};

} // namespace RNScreens
#endif
