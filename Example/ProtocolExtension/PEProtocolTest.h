//
//  PEProtocolTest.h
//  ProtocolExtension
//
//  Created by 沈强 on 2017/3/26.
//  Copyright © 2017年 yuzhoulangzik@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+ProtocolExtension.h"

@protocol PETest <NSObject>

@optional

- (id)test:(id)arg1 arg2:(id)arg2 arg3:(id)arg3;

@end


@interface PEProtocolTest : NSObject<PETest>

@end
