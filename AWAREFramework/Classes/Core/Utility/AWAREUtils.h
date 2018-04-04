//
//  AWAREUtils.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AWAREUtils : NSObject

// Application state (foreground or background)
+ (BOOL) getAppState;
+ (BOOL) isForeground;
+ (BOOL) isBackground;

// Notification
//+ (UILocalNotification *) sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;
//+ (UILocalNotification *) sendLocalNotificationForMessage:(NSString *)message
//                                   title:(NSString *)title
//                               soundFlag:(BOOL)soundFlag
//                                category:(NSString *) category
//                                fireDate:(NSDate*)fireDate
//                          repeatInterval:(NSCalendarUnit)repeatInterval
//                                userInfo:(NSDictionary *) userInfo
//                         iconBadgeNumber:(NSInteger)iconBadgeNumber;
//+ (bool) cancelLocalNotification:(UILocalNotification *) notification;

//+ (void) sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;
//+ (void) sendLocalNotificationForMessage:(NSString *)message
//                                                    title:(NSString *)title
//                                                soundFlag:(BOOL)soundFlag
//                                                 category:(NSString *) category
//                                                 fireDate:(NSDate*)fireDate
//                                           repeatInterval:(NSCalendarUnit)repeatInterval
//                                                 userInfo:(NSDictionary *) userInfo
//                                          iconBadgeNumber:(NSInteger)iconBadgeNumber;
// + (bool) cancelLocalNotification:(UNNotification *) notification;


// Device information
+ (float) getCurrentOSVersionAsFloat;
+ (NSString *)getSystemUUID;
+ (NSString*) deviceName;

// Date Controller
+ (NSNumber *) getUnixTimestamp:(NSDate *)nsdate;
+ (NSDate *) getTargetNSDate:(NSDate *) nsDate
                        hour:(int)hour
                     nextDay:(BOOL)nextDay;
+ (NSDate *)getTargetNSDate:(NSDate *)nsDate
                       hour:(int)hour
                     minute:(int)minute
                     second:(int)second
                    nextDay:(BOOL)nextDay;

// Hash Methods
+ (NSString*) sha1:(NSString*)input;
+ (NSString*) sha1:(NSString*)input debug:(BOOL)debug;

+ (NSString*) md5:(NSString*)input;

// Format checker
+ (BOOL)validateEmailWithString:(NSString *)str;

+ (BOOL) checkURLFormat:(NSString *)urlStr;

+ (NSDictionary*) getDictionaryFromURLParameter:(NSURL *)url;

+ (NSString *)stringByAddingPercentEncoding:(NSString *)string;
+ (NSString *)stringByAddingPercentEncoding:(NSString *)string unreserved:(NSString*)unreserved;


@end