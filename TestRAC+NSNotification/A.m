//
//  A.m
//  TestRAC+NSNotification
//
//  Created by ys on 2018/9/6.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "A.h"

#import <ReactiveCocoa.h>

@interface A ()

@end

@implementation A

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"B" object:nil]
     subscribeNext:^(id x) {
         NSLog(@"A收到B的通知了");
     }];
}

@end
