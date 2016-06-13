//
//  AppDelegate.m
//  BPushTest
//
//  Created by 焦星星 on 16/6/10.
//  Copyright © 2016年 jxx. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "BPush.h"

@interface AppDelegate ()
@property (nonatomic ,strong) ViewController *viewController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.viewController = [[ViewController alloc] init];
    self.window.rootViewController = self.viewController;
    /*
     // 根视图是普通的viewctr
     _tabBarCtr.viewControllers = @[self.viewController]; */
    [self.window makeKeyAndVisible];
    
    // iOS8 下需要使用新的 API
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
#warning 测试 开发环境 时需要修改BPushMode为BPushModeDevelopment 需要修改Apikey为自己的Apikey
    
    // 在 App 启动时注册百度云推送服务，需要提供 Apikey
    
    [BPush registerChannel:launchOptions apiKey:@"zhGY1QlaBacqd0Yyf29yYvq9" pushMode:BPushModeDevelopment withFirstAction:@"打开" withSecondAction:@"回复" withCategory:@"test" useBehaviorTextInput:YES isDebug:YES];
    
    // 禁用地理位置推送 需要再绑定接口前调用。
    
    [BPush disableLbs];
    
    // App 是用户点击推送消息启动
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"推送消息"
                                                           message:@"您有一条通知"
                                                          delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:@"查看详情", nil];
        [alertView show];
        
        [BPush handleNotification:userInfo];
    }
    //角标清0
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    /*
     // 测试本地通知
     [self performSelector:@selector(testLocalNotifi) withObject:nil afterDelay:1.0];
     */
    return YES;
}

- (void)testLocalNotifi
{
    NSLog(@"测试本地通知啦！！！");
    NSDate *fireDate = [[NSDate new] dateByAddingTimeInterval:5];
    [BPush localNotification:fireDate alertBody:@"这是本地通知" badge:3 withFirstAction:@"打开" withSecondAction:@"关闭" userInfo:nil soundName:nil region:nil regionTriggersOnce:YES category:nil useBehaviorTextInput:YES];
}

// 此方法是 用户点击了通知，应用在前台 或者开启后台并且应用在后台 时调起
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNewData);
    // 打印到日志 textView 中
    NSLog(@"********** iOS7.0之后 background **********");
    // 应用在前台，不跳转页面，让用户选择。
    if (application.applicationState == UIApplicationStateActive) {
        NSLog(@"acitve ");
        UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:@"收到一条消息" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
    }
    
    NSLog(@"%@",userInfo);
}

// 在 iOS8 系统中，还需要添加这个方法。通过新的 API 注册推送服务
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    
    [application registerForRemoteNotifications];
    
    
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"test:%@",deviceToken);
    [BPush registerDeviceToken:deviceToken];
    [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
        NSLog(@"%@",result);
        // 需要在绑定成功后进行 settag listtag deletetag unbind 操作否则会失败
        
        // 网络错误
        if (error) {
            return ;
        }
        if (result) {
            // 确认绑定成功
            if ([result[@"error_code"]intValue]!=0) {
                return;
            }
            // 获取channel_id
            NSString *myChannel_id = [BPush getChannelId];
            NSLog(@"==%@",myChannel_id);
            
            [BPush listTagsWithCompleteHandler:^(id result, NSError *error) {
                if (result) {
                    NSLog(@"result ============== %@",result);
                }
            }];
            [BPush setTag:@"Mytag" withCompleteHandler:^(id result, NSError *error) {
                if (result) {
                    NSLog(@"设置tag成功");
                }
            }];
        }
    }];
}

// 当 DeviceToken 获取失败时，系统会回调此方法
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"DeviceToken 获取失败，原因：%@",error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    NSLog(@"收到了通知");
    // App 收到推送的通知
//    [BPush handleNotification:userInfo];
//    NSLog(@"********** ios7.0之前 **********");
//    // 应用在前台 或者后台开启状态下，不跳转页面，让用户选择。
//    if (application.applicationState == UIApplicationStateActive || application.applicationState == UIApplicationStateBackground) {
//        NSLog(@"acitve or background");
//        UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:@"收到一条消息" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
//        [alertView show];
//    }
//    else//杀死状态下，直接跳转到跳转页面。
//    {
//        SkipViewController *skipCtr = [[SkipViewController alloc]init];
//        [_tabBarCtr.selectedViewController pushViewController:skipCtr animated:YES];
//    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"接收本地通知啦！！！");
    [BPush showLocalNotificationAtFront:notification identifierKey:nil];
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex == 1) {
//        SkipViewController *skipCtr = [[SkipViewController alloc]init];
//        // 根视图是nav 用push 方式跳转
//        [_tabBarCtr.selectedViewController pushViewController:skipCtr animated:YES];
//        /*
//         // 根视图是普通的viewctr 用present跳转
//         [_tabBarCtr.selectedViewController presentViewController:skipCtr animated:YES completion:nil]; */
//    }
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
