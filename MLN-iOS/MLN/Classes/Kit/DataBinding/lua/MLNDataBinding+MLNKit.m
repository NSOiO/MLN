//
//  MLNDataBinding+MLNKit.m
//  AFNetworking
//
//  Created by Dai Dongpeng on 2020/3/3.
//

#import "MLNDataBinding+MLNKit.h"
#import "MLNStaticExporterMacro.h"
#import "MLNKitHeader.h"
#import "MLNKitViewController.h"
#import "MLNBlock.h"
#import "MLNBlockObserver.h"
#import "MLNKitViewController+DataBinding.h"
#import "MLNListViewObserver.h"

@implementation MLNDataBinding (MLNKit)

+ (void)lua_bindDataForKeyPath:(NSString *)keyPath handler:(MLNBlock *)handler {
    MLNKitViewController *kitViewController = (MLNKitViewController *)MLN_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSObject<MLNKVOObserverProtol> *observer = [MLNBlockObserver observerWithBlock:handler keyPath:keyPath];
    [kitViewController addDataObserver:observer forKeyPath:keyPath];
}

+ (id __nullable)lua_dataForKeyPath:(NSString *)keyPath
{
    MLNKitViewController *kitViewController = (MLNKitViewController *)MLN_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    return [kitViewController dataForKeyPath:keyPath];
}

+ (void)lua_updateDataForKeyPath:(NSString *)keyPath value:(id)value
{
    MLNKitViewController *kitViewController = (MLNKitViewController *)MLN_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    [kitViewController updateDataForKeyPath:keyPath value:value];
}

#pragma mark - ListView
+ (void)lua_bindListViewForKey:(NSString *)key listView:(UIView *)listView
{
    MLNKitViewController *kitViewController = (MLNKitViewController *)MLN_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
//    NSObject<MLNKVObserverProtocol> *observer = [[MLNListViewObserver alloc] initWithListView:listView];
//    [kitViewController addDataObserver:observer forKeyPath:keyPath];
    MLNListViewObserver *observer = [MLNListViewObserver observerWithListView:listView keyPath:key];
    [kitViewController.dataBinding addArrayObserver:observer forKey:key];
}

+ (void)lua_bindDataListForKeyPath:(NSString *)keyPath handler:(MLNBlock *)handler
{
//    MLNKitViewController *kitViewController = (MLNKitViewController *)MLN_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
//    NSObject<MLNKVObserverProtocol> *observer = [[MLNBlockObserver alloc] initWithBloclk:handler];
//    [kitViewController addDataObserver:observer forKeyPath:keyPath];
}

+ (NSUInteger)lua_sectionCountForKey:(NSString *)key {
    return 1;
}

+ (NSUInteger)lua_rowCountForKey:(NSString *)key {
    NSArray *arr = [self lua_dataForKeyPath:key];
    return arr.count;
}

+ (id)lua_modelForKey:(NSString *)key section:(NSUInteger)section row:(NSUInteger)row path:(NSString *)path {
    NSArray *array = [self lua_dataForKeyPath:key];
    id resust = [[array objectAtIndex:row - 1] valueForKeyPath:path];
    return resust;
}

#pragma mark - Setup For Lua
LUA_EXPORT_STATIC_BEGIN(MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(bind, "lua_bindDataForKeyPath:handler:", MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(update, "lua_updateDataForKeyPath:value:", MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(get, "lua_dataForKeyPath:", MLNDataBinding)

LUA_EXPORT_STATIC_METHOD(bindListView, "lua_bindListViewForKey:listView:", MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(getSectionCount, "lua_sectionCountForKey:", MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(getRowCount, "lua_rowCountForKey:", MLNDataBinding)
LUA_EXPORT_STATIC_METHOD(getModel, "lua_modelForKey:section:row:path:", MLNDataBinding)

LUA_EXPORT_STATIC_END(MLNDataBinding, DataBinding, NO, NULL)

@end
