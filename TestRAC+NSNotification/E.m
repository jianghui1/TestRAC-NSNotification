//
//  E.m
//  TestRAC+NSNotification
//
//  Created by ys on 2019/1/9.
//  Copyright © 2019 ys. All rights reserved.
//

#import "E.h"

#import <ReactiveCocoa.h>

@interface E ()

@end

@implementation E

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"B" object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(id x) {
         NSLog(@"E收到B的通知了");
     }];
}

- (void)dealloc
{
    NSLog(@"e挂了");
}

@end
