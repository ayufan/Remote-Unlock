//
//  RUAppDelegate.m
//  RemoteUnlockEstimote
//
//  Created by Kamil Trzciński on 30/11/13.
//  Copyright (c) 2013 Polidea. All rights reserved.
//

#import "RUAppDelegate.h"
#import "JSTSensorManager.h"
#import "JSTSensorTag.h"
#import "JSTMagnetometerSensor.h"
#import <WebKit/WebKit.h>

#define BEACON_UUID @"f1eed054ac4e"
#define LOCK_SIGNAL -80
#define UNLOCK_SIGNAL -75
#define LOCK_DELAY 2.0
#define UNLOCK_DELAY 0.5

@interface RUAppDelegate () <JSTSensorManagerDelegate, JSTBaseSensorDelegate>

@property (nonatomic, strong) JSTSensorManager *sensorManager;

@property (nonatomic, strong) NSTimer * unlockTimer;
@property (nonatomic, strong) NSTimer * lockTimer;

@property (nonatomic) bool locked;

@end

static bool connected = false;

@implementation RUAppDelegate

- (void)manager:(JSTSensorManager *)manager didConnectSensor:(JSTSensorTag *)sensor
{
    // NSLog(@"Sensor connected: %@", sensor.macAddress);

    sensor.magnetometerSensor.sensorDelegate = self;
    [sensor.magnetometerSensor configureWithValue:JSTSensorMagnetometerEnabled];
    [sensor.magnetometerSensor setPeriodValue:10];
    [sensor.magnetometerSensor setNotificationsEnabled:YES];
}

- (void)manager:(JSTSensorManager *)manager didDisconnectSensor:(JSTSensorTag *)sensor error:(NSError *)error
{
    connected = false;

//    connected = true;
//    [self.sensorManager connectSensorWithUUID:
//            [[NSUUID alloc] initWithUUIDString:@"063A3DBD-2002-46B7-9AC9-98862CA8042F"]];
}

- (void)manager:(JSTSensorManager *)manager didFailToConnectToSensorWithError:(NSError *)error
{
    connected = false;
//    connected = true;
//    [self.sensorManager connectSensorWithUUID:
//            [[NSUUID alloc] initWithUUIDString:@"063A3DBD-2002-46B7-9AC9-98862CA8042F"]];
}

- (void)manager:(JSTSensorManager *)manager didDiscoverSensor:(JSTSensorTag *)sensor
{
    if (!sensor) {
        return;
    }

    if ([sensor.macAddress isEqualToString:@"BC:6A:29:AB:45:79"]) {
        if (![sensor.magnetometerSensor canBeConfigured]) {
            NSLog(@"Can't be configured");
            return;
        }
    }

    //  NSLog(@"CB: %@, RSSI: %d", sensor.peripheral, sensor.rssi);

//    if (!connected) {
//    }
}

- (void)manager:(JSTSensorManager *)manager didChangeStateTo:(CBCentralManagerState)state
{
    static bool started_scanning = false;
    
    if(!started_scanning && state == CBCentralManagerStatePoweredOn) {
        started_scanning = true;
        // [self.sensorManager startScanning];
    }
}


- (void)sensorDidUpdateValue:(JSTBaseSensor *)sensor {
    static bool isCalibrated = false;
    if ([sensor isKindOfClass:[JSTMagnetometerSensor class]]) {
        JSTMagnetometerSensor *magnetometerSensor = (JSTMagnetometerSensor *) sensor;
        if (!isCalibrated) {
            isCalibrated = YES;
            [magnetometerSensor calibrate];
        } else {
            float length = magnetometerSensor.value.x * magnetometerSensor.value.x
                    + magnetometerSensor.value.y * magnetometerSensor.value.y
                    + magnetometerSensor.value.z * magnetometerSensor.value.z;
            length = sqrtf(length);

            NSLog(@"Length: %f", length);

            static bool isLocked = false;

            static bool lastToggled = false;
            bool shouldToggle = false;

            if(length > 500) {
                shouldToggle = true;
            }

            if (shouldToggle && lastToggled != shouldToggle) {
                if (!isLocked) {
                    isLocked = true;
                    [self lock];
                } else {
                    isLocked = false;
                    [self unlock];
                }
            }

            lastToggled = shouldToggle;
        }
    }
}

- (void)sensorDidFailCommunicating:(JSTBaseSensor *)sensor withError:(NSError *)error {

}

- (void)sensorDidFinishCalibration:(JSTBaseSensor *)sensor {

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.sensorManager = [JSTSensorManager new];
    self.sensorManager.delegate = self;

    connected = true;
    [self.sensorManager connectSensorWithUUID:
            [[NSUUID alloc] initWithUUIDString:@"063A3DBD-2002-46B7-9AC9-98862CA8042F"]];

    NSRect screenRect = [[NSScreen mainScreen] frame];
    
    WebView *webView = [[WebView alloc] init];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"lock"
                                                         ofType:@"html"
                                                    inDirectory:@""];
    NSURL* fileURL = [NSURL fileURLWithPath:filePath];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:fileURL];
    [[webView mainFrame] loadRequest:urlRequest];
    [webView setFrame:screenRect];

    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    [self.window setContentView:webView];
    
    [self.window setStyleMask:NSBorderlessWindowMask];
    [self.window setFrame:[[NSScreen mainScreen] frame] display:NO animate:NO];
    
    [self.window setLevel:NSScreenSaverWindowLevel];
    [self.window makeKeyAndOrderFront:nil];
    
    [self.window miniaturize:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
//    if(self.locked) {
//        system("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend");
//    }
}

- (void) scheduleLockScreen:(NSNumber*)rssi
{
    double rssiValue = [rssi doubleValue];
    if(!rssi || rssiValue < LOCK_SIGNAL) {
        [self scheduleLockScreen];
    } else {
        [self unscheduleLockScreen];
    }
}

- (void) scheduleLockScreen
{
    if(self.lockTimer) {
        return;
    }
    if(self.locked) {
        return;
    }
    NSLog(@"Scheduling screen lock");
    self.lockTimer = [NSTimer scheduledTimerWithTimeInterval:LOCK_DELAY
                                                          target:self
                                                        selector:@selector(lockScreen)
                                                        userInfo:nil repeats:YES];
}

- (void) unscheduleLockScreen
{
    if(self.lockTimer) {
        NSLog(@"Unscheduling screen lock");
        [self.lockTimer invalidate];
        self.lockTimer = nil;
    }
}

- (void) lockScreen
{
    if(self.lockTimer) {
        [self.lockTimer invalidate];
        self.lockTimer = nil;
    }
    NSLog(@"LockScreen");
    self.locked = true;
    
    // system("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend");
    
    [self lock];
}

- (void) scheduleUnlockScreen:(NSNumber*)rssi
{
    double rssiValue = [rssi doubleValue];
    if(rssi && rssiValue > UNLOCK_SIGNAL) {
        [self scheduleUnlockScreen];
    } else {
        [self unscheduleUnlockScreen];
    }
}

- (void) scheduleUnlockScreen
{
    if(self.unlockTimer) {
        return;
    }
    if(!self.locked) {
        return;
    }
    NSLog(@"Scheduling screen unlock");
    self.unlockTimer = [NSTimer scheduledTimerWithTimeInterval:UNLOCK_DELAY
                                                      target:self
                                                    selector:@selector(unlockScreen)
                                                    userInfo:nil repeats:YES];
}

- (void) unscheduleUnlockScreen
{
    if(self.unlockTimer) {
        NSLog(@"Unscheduling screen unlock");
        [self.unlockTimer invalidate];
        self.unlockTimer = nil;
    }
}

- (void) unlockScreen
{
    if(self.unlockTimer) {
        [self.unlockTimer invalidate];
        self.unlockTimer = nil;
    }
    NSLog(@"UnlockScreen");
    self.locked = false;
    
    //system("defaults write com.apple.screensaver askForPassword 0");
    //system("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -switchToUserID 501");
    //system("defaults write com.apple.screensaver askForPassword 1");
    
    [self unlock];
}

- (void)unlock {
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"unlock" ofType:@"mp3"];
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
    [sound play];
    
    [[self window] miniaturize:self];
}

- (void)lock {
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"lock" ofType:@"mp3"];
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
    [sound play];
    [self.window setFrame:[[NSScreen mainScreen] frame] display:YES animate:YES];
    [self.window deminiaturize:self];
}

@end
