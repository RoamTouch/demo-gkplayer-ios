//
//  AppDelegate.m
//  RandomMusicPlayer
//
//  Created by Julio Andrés Carrettoni on 09/11/13.
//  Copyright (c) 2013 RoamTouch. All rights reserved.
//

#import "AppDelegate.h"
#import "MusicViewController.h"

#import "GestureKit.h"
@interface AppDelegate()
@property (nonatomic, retain) MusicViewController* musicViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    application.statusBarStyle = UIStatusBarStyleLightContent;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [GestureKit showDebugLogs:NO];
    [GestureKit showAlertLogs:NO];
    [GestureKit runInWindow:self.window withGID:@"988786d4-56dd-45d6-a558-1245954d815c"];//SOLE
    [GestureKit setPos:CGPointMake(0, 0)];
    
    self.musicViewController = [MusicViewController new];
    self.window.rootViewController = self.musicViewController;
    return YES;
}

- (void) PAUSE {
    [self.musicViewController pause:nil];
}

- (void) PLAY {
    [self.musicViewController play:nil];
}

- (void) STOP {
    [self.musicViewController stop:nil];
}

- (void) FORWARD {
    [self.musicViewController nextSong:nil];
}

- (void) BACKWARD {
    [self.musicViewController previousSong:nil];
}

- (void) SHARETW:(NSString*) metadata {
    [self.musicViewController sharetw:metadata];
}

- (void) SHAREFB:(NSString*) metadata {
    [self.musicViewController sharefb:metadata];
}

@end
