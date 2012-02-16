//
//  UltraSignupAppDelegate.h
//  UltraSignup
//
//  Created by Jon Kroll on 7/3/11.
//  Copyright 2011. All rights reserved.
//

@interface UltraSignupAppDelegate : NSObject <UIApplicationDelegate> {

    NSOperationQueue *queue;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (nonatomic, retain) NSOperationQueue *queue;

void uncaughtExceptionHandler(NSException *exception);

@end
