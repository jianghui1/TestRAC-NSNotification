//
//  C.m
//  TestRAC+NSNotification
//
//  Created by ys on 2018/9/6.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "C.h"

#import <ReactiveCocoa.h>

@interface C ()

@end

@implementation C

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"B" object:nil]
     subscribeNext:^(id x) {
         NSLog(@"C收到B的通知了");
     }];
}

- (void)dealloc
{
    NSLog(@"c挂了");
}

@end
