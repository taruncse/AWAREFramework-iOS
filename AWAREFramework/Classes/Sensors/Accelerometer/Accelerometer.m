//
//  Accelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Accelerometer.h"
#import "AWAREUtils.h"
#import "EntityAccelerometer.h"
#import "EntityAccelerometer+CoreDataProperties.h"
#import "ObjectModels/AWAREAccelerometerOM+CoreDataClass.h"
#import "../../Core/Storage/SQLite/AWAREBatchDataOM+CoreDataClass.h"
#import "JSONStorage.h"
#import "SQLiteStorage.h"
#import "../../Core/Storage/SQLite/SQLiteSeparatedStorage.h"

NSString * const AWARE_PREFERENCES_STATUS_ACCELEROMETER    = @"status_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER = @"frequency_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER = @"frequency_hz_accelerometer";
NSString * const AWARE_PREFERENCES_THRESHOLD_ACCELEROMETER = @"threshold_accelerometer";

@implementation Accelerometer{
    CMMotionManager *manager;
    NSArray * lastValues;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"accelerometer"];
    } else if (dbType == AwareDBTypeCSV){
        NSArray * headerLabels = @[@"timestamp",@"device_id",@"double_values_0",@"double_values_1",@"double_values_2",@"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"accelerometer" headerLabels:headerLabels headerTypes:headerTypes];
    } else{
        
       SQLiteStorage * sqlite = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:@"accelerometer"
                                            entityName:NSStringFromClass([EntityAccelerometer class])
                                        insertCallBack:nil];
        
        /// use the separated database if the existing database is empty
        NSError * error = nil;
        BOOL exist = [sqlite isExistUnsyncedDataWithError:error];
        if (!exist && error==nil) {
            storage = [[SQLiteSeparatedStorage alloc] initWithStudy:study sensorName:@"accelerometer"
                                                    objectModelName:NSStringFromClass([AWAREAccelerometerOM class])
                                                      syncModelName:NSStringFromClass([AWAREBatchDataOM class])
                                                          dbHandler:AWAREAcceleromoeterCoreDataHandler.shared];
        }else{
            if (error!=nil) {
                NSLog(@"[%@] Error: %@", [self getSensorName], error.debugDescription);
            }
            storage = sqlite;
        }
        
    }
    [self setNotificationNames:@[]];
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                             storage:storage];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        lastValues = [[NSArray alloc] init];
    }
    
    if (self.isDebug) {
        NSLog(@"[%@][%@] init sensor",[self getSensorName],self);
    }
    
    return self;
}

- (void) createTable {
    if ([self isDebug]){
        NSLog(@"[%@][%@] create table", [self getSensorName],self);
    }
    TCQMaker * queryMaker = [[TCQMaker alloc] init];
    [queryMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [queryMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:queryMaker];
}



- (void)setParameters:(NSArray *)parameters{
    if(parameters != nil){
        double tempFrequency = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER];
        if(tempFrequency != -1){
            [self setSensingIntervalWithSecond:[self convertMotionSensorFrequecyFromAndroid:tempFrequency]];
        }
        
        double tempHz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER];
        if(tempHz > 0){
            [self setSensingIntervalWithSecond:1.0f/tempHz];
        }
        
        double threshold = [self getSensorSetting:parameters withKey:@"threshold_accelerometer"];
        if (threshold > 0) {
            [self setThreshold:threshold];
        }
    }
}


- (BOOL) startSensorWithSensingInterval:(double)sensingInterval
                         savingInterval:(double)savingInterval{
    // Set and start a data uploader
    if ([self isDebug]) {
        NSLog(@"[%@][%@] start sensor", [self getSensorName], self);
    }
    
    if (![manager isAccelerometerAvailable]) {
        if ([self isDebug]) { NSLog(@"[accelerometer] accelerometer sensor is not supported.");}
        return NO;
    }
    
    // Set buffer size for reducing file access
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    manager.accelerometerUpdateInterval = sensingInterval;
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue: [NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"[accelerometer] %@:%zd", [error domain], [error code] );
                                      } else {
                                                                                    
                                          if (self.threshold > 0 && [self getLatestData] !=nil &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.x lastValueKey:@"double_values_0"] &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.y lastValueKey:@"double_values_1"] &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.z lastValueKey:@"double_values_2"]
                                            ) {
                                              return;
                                          }
                                          
                                          // SQLite
                                          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                          [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                          [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                          [dict setObject:@(accelerometerData.acceleration.x) forKey:@"double_values_0"];
                                          [dict setObject:@(accelerometerData.acceleration.y) forKey:@"double_values_1"];
                                          [dict setObject:@(accelerometerData.acceleration.z) forKey:@"double_values_2"];
                                          [dict setObject:@3 forKey:@"accuracy"];
                                          if (self.label != nil) {
                                              [dict setObject:self.label forKey:@"label"];
                                          }else{
                                              [dict setObject:@"" forKey:@"label"];
                                          }
                                          [self setLatestValue:[NSString stringWithFormat:
                                                                @"%f, %f, %f",
                                                                accelerometerData.acceleration.x,
                                                                accelerometerData.acceleration.y,
                                                                accelerometerData.acceleration.z]];
                                          
                                          [self setLatestData:dict];
                                          
                                          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                               forKey:EXTRA_DATA];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ACCELEROMETER
                                                                                              object:nil
                                                                                            userInfo:userInfo];
                                          
                                          SensorEventHandler handler = [self getSensorEventHandler];
                                          if (handler!=nil) {
                                              handler(self, dict);
                                          }
                                          
                                          //[self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                      }
                                  }];
    [self setSensingState:YES];

    return YES;
}



-(BOOL) stopSensor {
    [manager stopAccelerometerUpdates];
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    if ([self isDebug]) {
        NSLog(@"[%@][%@] stop sensor", [self getSensorName], self);
    }
    return YES;
}

- (void)startSyncDB{
    if ([self isDebug]){
        NSLog(@"[%@][%@] start sync", [self getSensorName],self);
    }
    [super startSyncDB];
}

@end


static AWAREAcceleromoeterCoreDataHandler * shared;
@implementation AWAREAcceleromoeterCoreDataHandler
+ (AWAREAcceleromoeterCoreDataHandler * _Nonnull)shared {
    @synchronized(self){
        if (!shared){
            shared =  (AWAREAcceleromoeterCoreDataHandler *)[[BaseCoreDataHandler alloc] initWithDBName:@"AWARE_Accelerometer"];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (shared == nil) {
            shared= [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

@end

