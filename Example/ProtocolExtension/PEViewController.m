//
//  PEViewController.m
//  ProtocolExtension
//
//  Created by yuzhoulangzik@126.com on 03/25/2017.
//  Copyright (c) 2017 yuzhoulangzik@126.com. All rights reserved.
//

#import "PEViewController.h"
#import "PEProtocolTest.h"

@interface PEViewController ()

@end

@implementation PEViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  id test = [[PEProtocolTest new] test:@"xxxxxxxxxxxxx" arg2:@"yyyyyyyy" arg3:@"zzzzzzzzzzzz"];
  [test test:@"xxxxxxxxxxxxx" arg2:@"yyyyyyyy" arg3:@"zzzzzzzzzzzz"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
  NSLog(@"PEViewController release");
}

@end
