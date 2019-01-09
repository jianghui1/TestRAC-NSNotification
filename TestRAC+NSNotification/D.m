//
//  D.m
//  TestRAC+NSNotification
//
//  Created by ys on 2018/9/6.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "D.h"

#import <ReactiveCocoa.h>

@interface D ()

@property (nonatomic, strong) id observer;

@end

@implementation D

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"B" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"D收到B的通知了");
    }];
}

- (void)dealloc
{
    NSLog(@"d挂了");
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}

@end
