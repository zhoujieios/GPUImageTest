//
//  AppDelegate.m
//  GPUImageTest
//
//  Created by 公司 on 2017/3/29.
//  Copyright © 2017年 learning. All rights reserved.
//

#import "AppDelegate.h"
#import "FilterViewController.h"
#import "FilterValueModel.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSMutableArray *imageArray = [[NSMutableArray alloc] init];
    [imageArray addObject:[UIImage imageNamed:@"Lambeau.jpg"]];
    [imageArray addObject:[UIImage imageNamed:@"timg.jpeg"]];
    
    NSMutableArray *filterValueArray = [[NSMutableArray alloc] init];
    [filterValueArray addObject:[[FilterValueModel alloc] init]];
    [filterValueArray addObject:[[FilterValueModel alloc] init]];
    
    FilterViewController *vc = [[FilterViewController alloc] init];
    vc.imageArray = imageArray;
    vc.filterValueArray = filterValueArray;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
