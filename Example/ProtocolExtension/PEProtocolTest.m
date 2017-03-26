//
//  PEProtocolTest.m
//  ProtocolExtension
//
//  Created by 沈强 on 2017/3/26.
//  Copyright © 2017年 yuzhoulangzik@126.com. All rights reserved.
//

#import "PEProtocolTest.h"

@extension(PETest)


- (id)test:(id)arg1 arg2:(id)arg2 arg3:(id)arg3 {
  NSLog(@"===================>%@===%@=====%@",arg1,arg2,arg3);
  [self testLog];
  return [NSObject new];
}

- (void)testLog {
  NSLog(@"======================class: %@",self.class);
}

@end

@implementation PEProtocolTest

@end
