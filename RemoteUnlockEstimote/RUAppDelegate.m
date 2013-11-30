//
//  RUAppDelegate.m
//  RemoteUnlockEstimote
//
//  Created by Kamil Trzciński on 30/11/13.
//  Copyright (c) 2013 Polidea. All rights reserved.
//

#import "RUAppDelegate.h"
#import "ESTBeaconManager.h"
#import "ESTBeaconRegion.h"
#import "ESTBeacon.h"

#define BEACON_UUID @"f1eed054ac4e"
#define LOCK_SIGNAL -70
#define UNLOCK_SIGNAL -70
#define LOCK_DELAY 2
#define UNLOCK_DELAY 0.5

@interface RUAppDelegate () <ESTBeaconManagerDelegate, ESTBeaconDelegate>

@property (nonatomic, strong) ESTBeaconManager* beaconManager;

@property (nonatomic, strong) NSTimer * unlockTimer;
@property (nonatomic, strong) NSTimer * lockTimer;

@property (nonatomic) bool locked;

@end

@implementation RUAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    ESTBeaconRegion *region = [[ESTBeaconRegion alloc] initRegionWithIdentifier:@"dd"];
    [self.beaconManager startEstimoteBeaconsDiscoveryForRegion:region];
}

-(void)beaconManager:(ESTBeaconManager *)manager
  didDiscoverBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    ESTBeacon * beacon = nil;
    
    for(int i = 0; i < [beacons count]; ++i) {
        ESTBeacon * current = (ESTBeacon*)[beacons objectAtIndex:i];
        if([current.macAddress isEqualToString:BEACON_UUID]) {
            beacon = current;
            break;
        }
    }
    
    if(beacon) {
        NSLog(@"BeaconFound: mac:%@ power:%f rssi:%f", beacon.macAddress, [beacon.measuredPower floatValue], [beacon.rssi floatValue]);
    } else {
        // NSLog(@"BeaconNotFound");
    }

    [self scheduleLockScreen:beacon.rssi];
    [self scheduleUnlockScreen:beacon.rssi];
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
    
    system("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend");
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
}

@end