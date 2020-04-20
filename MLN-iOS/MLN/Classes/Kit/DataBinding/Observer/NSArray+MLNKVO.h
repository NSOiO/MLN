//
//  NSArray+MLNKVO.h
//  AFNetworking
//
//  Created by Dai Dongpeng on 2020/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (MLNKVO)

@property (nonatomic, copy)NSString *(^mln_resueIdBlock)(NSArray *items, NSUInteger section, NSUInteger row);

// AutoFitAdaper 会自动计算行高，所以不需要.
@property (nonatomic, copy, nullable)NSUInteger(^mln_heightBlock)(NSArray *items, NSUInteger section, NSUInteger row);

@end

NS_ASSUME_NONNULL_END
