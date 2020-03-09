//
//  MLNSwitch.m
//
//
//  Created by MoMo on 2018/12/18.
//

#import "MLNSwitch.h"
#import "MLNViewExporterMacro.h"
#import "MLNBlock.h"
#import "MLNKitHeader.h"

@interface MLNSwitchActionHandler : NSObject

@end

@implementation MLNSwitchActionHandler

- (void)switchAction:(MLNSwitch *)sender
{
    if (sender.switchChangedCallback) {
        [sender.switchChangedCallback addBOOLArgument:sender.on];
        [sender.switchChangedCallback callIfCan];
    }
}

@end


@interface MLNSwitch()

@property (nonatomic, strong) MLNSwitchActionHandler *switchHandler;

@end

@implementation MLNSwitch

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSwitchObserver];
    }
    return self;
}

- (void)lua_setOn:(BOOL)on
{
    [self setOn:on animated:YES];
}

- (BOOL)lua_on
{
    return self.isOn;
}

- (void)lua_setSwitchChangedCallback:(MLNBlock *)callback
{
    MLNCheckTypeAndNilValue(callback, @"function", MLNBlock);
    self.switchChangedCallback = callback;
}

#pragma mark - private methoc
- (void)addSwitchObserver
{
    [self addTarget:self.switchHandler action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (MLNSwitchActionHandler *)switchHandler
{
    if (!_switchHandler) {
        _switchHandler = [[MLNSwitchActionHandler alloc] init];
    }
    return _switchHandler;
}

#pragma mark - Override
- (void)lua_addSubview:(UIView *)view
{
    MLNKitLuaAssert(NO, @"Not found \"addView\" method, just continar of View has it!");
}

- (void)lua_insertSubview:(UIView *)view atIndex:(NSInteger)index
{
    MLNKitLuaAssert(NO, @"Not found \"insertView\" method, just continar of View has it!");
}

- (void)lua_removeAllSubViews
{
    MLNKitLuaAssert(NO, @"Not found \"removeAllSubviews\" method, just continar of View has it!");
}

- (BOOL)lua_layoutEnable
{
    return YES;
}

#pragma mark - Export For Lua
//LUA_EXPORT_VIEW_BEGIN(MLNSwitch)
//LUA_EXPORT_PROPERTY(on, "lua_setOn:", "lua_on", MLNSwitch)
//LUA_EXPORT_VIEW_METHOD(setSwitchChangedCallback, "lua_setSwitchChangedCallback:", MLNSwitch)
//LUA_EXPORT_VIEW_END(MLNSwitch, Switch, YES, "MLNView", NULL)

//typedef struct mln_objc_method {
//    const char *l_mn;  /* Object-C method name in lua*/
//    const char *mn; /* Object-C method name */
//    const char *clz; /* Object-C class name */
//    BOOL isProperty; /* It's YES if property method*/
//    const char *setter_n; /* Object-C getter method name*/
//    const char *getter_n; /* Object-C setter method name */
//    lua_CFunction func; /* C function in lua */
//} mln_objc_method;

static const struct mln_objc_method mln_Method_MLNSwitch [] = {
    {("on"), (((void*)0)), ("MLNSwitch"), (__objc_yes), ("lua_setOn:"), ("lua_on"), (mln_lua_obj_method)},
    {("setSwitchChangedCallback"), ("lua_setSwitchChangedCallback:"), ("MLNSwitch"), (__objc_no), (((void*)0)), (((void*)0)), (mln_lua_obj_method)},
    {((void*)0), ((void*)0), ((void*)0), __objc_no, ((void*)0), ((void*)0), ((void*)0)}
};

static const struct mln_objc_class mln_Clazz_Info_MLNSwitch =
{
    "mln","MLNSwitch","Switch","mln" "." "Switch","MLN_UserDataNativeObject",
    !(__objc_yes),"MLNView",__objc_yes,(struct mln_objc_method *)mln_Method_MLNSwitch,((void*)0),{("constructor"), (((void*)0)), ("MLNSwitch"), (__objc_no), (((void*)0)), (((void*)0)), (mln_lua_constructor)}
};

+ (const mln_objc_class *)mln_clazzInfo{
    return &mln_Clazz_Info_MLNSwitch;
}

+ (MLNExportType)mln_exportType {
    return (MLNExportTypeEntity);
}

static const void *kLuaCore_MLNSwitch = &kLuaCore_MLNSwitch;

- (void)setMln_luaCore:(MLNLuaCore *)mln_myLuaCore {
    MLNWeakAssociatedObject *wp = objc_getAssociatedObject(self, kLuaCore_MLNSwitch);
    if (!wp) {
        wp = [MLNWeakAssociatedObject weakAssociatedObject:mln_myLuaCore]; objc_setAssociatedObject(self, kLuaCore_MLNSwitch, wp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (wp.associatedObject != mln_myLuaCore) {
        [wp updateAssociatedObject:mln_myLuaCore];
    }
}

- (MLNLuaCore *)mln_luaCore{
    MLNWeakAssociatedObject *wp = objc_getAssociatedObject(self, kLuaCore_MLNSwitch);
    return wp.associatedObject;
}

static const void *kLuaRetainCountMLNSwitch = &kLuaRetainCountMLNSwitch;
- (int)mln_luaRetainCount{
    return [objc_getAssociatedObject(self, kLuaRetainCountMLNSwitch) intValue];
}

- (void)mln_luaRetain:(MLNUserData *)userData{
    userData->object = CFBridgingRetain(self);
    int count = [self mln_luaRetainCount];
    objc_setAssociatedObject(self, kLuaRetainCountMLNSwitch, @(count + 1), OBJC_ASSOCIATION_ASSIGN);
}

- (void)mln_luaRelease{
    CFBridgingRelease((__bridge CFTypeRef _Nullable)self);
    int count = [self mln_luaRetainCount];
    objc_setAssociatedObject(self, kLuaRetainCountMLNSwitch, @(count - 1), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)mln_isConvertible{
    return __objc_yes;
}

@end
