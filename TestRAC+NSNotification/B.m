//
//  B.m
//  TestRAC+NSNotification
//
//  Created by ys on 2018/9/6.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "B.h"

@interface B ()

@end

@implementation B

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"B" object:nil];
}

- (IBAction)notifyAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"B" object:nil];
}

@end
