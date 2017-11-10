//
//  RTBaseViewController.m
//  RTRecordVideo
//
//  Created by RongTian on 13-11-4.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTBaseViewController.h"
#import "RTRecordVideoViewController.h"
@interface RTBaseViewController ()

@end

@implementation RTBaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(30, 100, 100, 40);
    [btn setTitle:@"Record" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pushAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)pushAction:(UIButton *)sender
{
    RTRecordVideoViewController *recordVC = [[RTRecordVideoViewController alloc]init];
    [self.navigationController presentViewController:recordVC animated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
