//
//  RealStuff.m
//  GankIO
//
//  Created by Josscii on 16/7/24.
//  Copyright © 2016年 Josscii. All rights reserved.
//

#import "RealStuff.h"

@implementation RealStuff

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"desc": @"desc",
             @"type": @"type",
             @"url": @"url",
             @"who": @"who"
             };
}

@end