//
//  MLNBridgeNormal.m
//  LuaNative
//
//  Created by Dai Dongpeng on 2020/4/11.
//  Copyright © 2020 MoMo. All rights reserved.
//

#import "MLNBridgeNormal.h"

@implementation MLNBridgeNormal 

- (void)test:(id)obj1 a:(id)obj2 {
    
}

//LUA_EXPORT_BEGIN(MLNBridgeNormal)
//LUA_EXPORT_METHOD(test, "test:a:", MLNBridgeNormal)
//LUA_EXPORT_END(MLNBridgeNormal, Normal, NO, NULL, NULL)


///**
// 方法信息结构体
// */
//typedef struct mln_objc_method {
//    const char *l_mn;  /* Object-C method name in lua*/
//    const char *mn; /* Object-C method name */
//    const char *clz; /* Object-C class name */
//    BOOL isProperty; /* It's YES if property method*/
//    const char *setter_n; /* Object-C getter method name*/
//    const char *getter_n; /* Object-C setter method name */
//    lua_CFunction func; /* C function in lua */
//} mln_objc_method;
//
///**
// 类描述信息结构体
// */
//typedef struct mln_objc_class {
//    const char *pkg; /* packge name */
//    const char *clz; /* Object-C class name */
//    const char *l_clz; /* Object-C class name in lua */
//    const char *l_name; /* Object-C class name in lua */
//    const char *l_type; /* its type of Object-C class in lua  */
//    BOOL isRoot; /* is root function,it should be YES if no base class. */
//    const char *supreClz; /* base Object-C class */
//    BOOL hasConstructor; /* it should be NO if static class. */
//    MLN_Method_List methods; /* Object-C method */
//    MLN_Method_List clz_methods; /* Object-C class method */
//    struct mln_objc_method constructor; /* Object-C constructor method */
//} mln_objc_class;


static const struct mln_objc_method mln_Method_MLNBridgeNormal [] = {
    {
        ("test"),
        ("test:a:"),
        ("MLNBridgeNormal"),
        (__objc_no),
        (((void*)0)),
        (((void*)0)),
        (mln_lua_obj_method)
    },
    {
        ((void*)0), ((void*)0), ((void*)0), __objc_no, ((void*)0), ((void*)0), ((void*)0)
    }
};

static const struct mln_objc_class mln_Clazz_Info_MLNBridgeNormal = {
    "mln", // const char *pkg; /* packge name */
    "MLNBridgeNormal", // const char *clz; /* Object-C class name */
    "Normal", // const char *l_clz; /* Object-C class name in lua */
    "mln" "." "Normal", //const char *l_name; /* Object-C class name in lua */
    "MLN_UserDataNativeObject", // const char *l_type; /* its type of Object-C class in lua  */
    !(__objc_no), // BOOL isRoot; /* is root function,it should be YES if no base class. */
    ((void*)0), // const char *supreClz; /* base Object-C class */
    __objc_yes, // BOOL hasConstructor; /* it should be NO if static class. */
    (struct mln_objc_method *)mln_Method_MLNBridgeNormal, // MLN_Method_List methods; /* Object-C method */
    ((void*)0), // MLN_Method_List clz_methods; /* Object-C class method */
    {           // struct mln_objc_method constructor; /* Object-C constructor method */
        // const char *l_mn;  /* Object-C method name in lua*/
        ("constructor"),
        // const char *mn; /* Object-C method name */
        (((void*)0)),
        // const char *clz; /* Object-C class name */
        ("MLNBridgeNormal"),
        // BOOL isProperty; /* It's YES if property method*/
        (__objc_no),
        // const char *setter_n; /* Object-C getter method name*/
        (((void*)0)),
        // const char *getter_n; /* Object-C setter method name */
        (((void*)0)),
        // lua_CFunction func; /* C function in lua */
        (mln_lua_constructor)
    }
};

+ (const mln_objc_class *)mln_clazzInfo{
    return &mln_Clazz_Info_MLNBridgeNormal;
}

+ (MLNExportType)mln_exportType {
    return (MLNExportTypeEntity);
}

static const void *kLuaCore_MLNBridgeNormal = &kLuaCore_MLNBridgeNormal;
- (void)setMln_luaCore:(MLNLuaCore *)mln_myLuaCore{
    MLNWeakAssociatedObject *wp = objc_getAssociatedObject(self, kLuaCore_MLNBridgeNormal);
    if (!wp) {
        wp = [MLNWeakAssociatedObject weakAssociatedObject:mln_myLuaCore];
        objc_setAssociatedObject(self, kLuaCore_MLNBridgeNormal, wp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (wp.associatedObject != mln_myLuaCore) {
        [wp updateAssociatedObject:mln_myLuaCore]; }
}

- (MLNLuaCore *)mln_luaCore{
    MLNWeakAssociatedObject *wp = objc_getAssociatedObject(self, kLuaCore_MLNBridgeNormal);
    return wp.associatedObject;
}

static const void *kLuaRetainCountMLNBridgeNormal = &kLuaRetainCountMLNBridgeNormal;
- (int)mln_luaRetainCount{
    return [objc_getAssociatedObject(self, kLuaRetainCountMLNBridgeNormal) intValue];
}
- (void)mln_luaRetain:(MLNUserData *)userData{
    userData->object = CFBridgingRetain(self);
    int count = [self mln_luaRetainCount];
    objc_setAssociatedObject(self, kLuaRetainCountMLNBridgeNormal, @(count + 1), OBJC_ASSOCIATION_ASSIGN);
}
- (void)mln_luaRelease{
    CFBridgingRelease((__bridge CFTypeRef _Nullable)self);
    int count = [self mln_luaRetainCount];
    NSAssert(count > 0, @"lua 过度释放UserData");
    objc_setAssociatedObject(self, kLuaRetainCountMLNBridgeNormal, @(count - 1), OBJC_ASSOCIATION_ASSIGN);
}

// 是否是userData
- (BOOL)mln_isConvertible{
    return __objc_yes;
}

@end

/*
     do {
         // __FILE__
 # 19 "/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"
 #pragma clang diagnostic push
 # 19 "/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"
 #pragma clang diagnostic ignored "-Wformat-extra-args"
 # 19 "/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"
  if (__builtin_expect(!(count > 0), 0)) {
      NSString *__assert_file__ = [NSString stringWithUTF8String:"/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"]; __assert_file__ = __assert_file__ ? __assert_file__ : @"<Unknown File>"; [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:__assert_file__ lineNumber:19 description:(@"lua 过度释放UserData")]; }
 # 19 "/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"
 #pragma clang diagnostic pop
 # 19 "/Users/deepak/Development/MoMo/Lua/MLNUI/MLN/MLN-iOS/Example/MLN/BridgeTest/MLNBridgeNormal.m"
  } while(0);
 */
