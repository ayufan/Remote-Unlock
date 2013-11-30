//
//  ESTBeaconManager.h
//  EstimoteMacSDK
//
//  Created by Grzegorz Krukiewicz-Gacek on 18.11.2013.
//  Copyright (c) 2013 Estimote. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTBeaconRegion.h"
#import "ESTBeacon.h"

@class ESTBeaconManager;

/**
 
 The ESTBeaconManagerDelegate protocol defines the delegate methods to respond for related events.
 */

@protocol ESTBeaconManagerDelegate <NSObject>

@optional

/**
 * Method triggered when device starts advertising
 * as iBeacon.
 *
 * @param manager estimote beacon manager
 * @param error info about any error
 *
 * @return void
 */
-(void)beaconManagerDidStartAdvertising:(ESTBeaconManager *)manager
                                  error:(NSError *)error;

/**
 * Delegate method invoked to handle discovered
 * ESTBeacon objects using CoreBluetooth framework
 * in particular region.
 *
 * @param manager estimote beacon manager
 * @param beacons all beacons as ESTBeacon objects
 * @param region estimote beacon region
 *
 * @return void
 */
- (void)beaconManager:(ESTBeaconManager *)manager
   didDiscoverBeacons:(NSArray *)beacons
             inRegion:(ESTBeaconRegion *)region;

/**
 * Delegate method invoked when CoreBluetooth based
 * discovery process fails.
 *
 * @param manager estimote beacon manager
 * @param region estimote beacon region
 *
 * @return void
 */
- (void)beaconManager:(ESTBeaconManager *)manager
didFailDiscoveryInRegion:(ESTBeaconRegion *)region;

@end


/**
 
 The ESTBeaconManager class defines the interface for handling and configuring the estimote beacons and get related events to your application. You use an instance of this class to establish the parameters that describes each beacon behavior. You can also use a beacon manager object to retrieve all beacons in range.
 
 A beacon manager object provides support for the following location-related activities:
 
 * Reporting the range to nearby beacons and ther distance for the device.
 
 */

@interface ESTBeaconManager : NSObject

@property (nonatomic, weak) id <ESTBeaconManagerDelegate> delegate;

@property (nonatomic, strong) ESTBeaconRegion* virtualBeaconRegion;

/**
 * Allows to turn Mac into virtual estimote beacon.
 *
 * @param major minor beacon value
 * @param minor major beacon value
 * @param identifier unique identifier for you region
 *
 * @return void
 */
-(void)startAdvertisingWithMajor:(ESTBeaconMajorValue)major
                       withMinor:(ESTBeaconMinorValue)minor
                  withIdentifier:(NSString*)identifier;


/**
 * Stop beacon advertising
 *
 * @return void
 */
-(void)stopAdvertising;

/**
 * Start beacon discovery process. 
 * Immitates the behaviour of CoreLocation iBeacon ranging
 * in iOS
 *
 * @param region estimote beacon region
 *
 * @return void
 */
-(void)startEstimoteBeaconsDiscoveryForRegion:(ESTBeaconRegion*)region;


/**
 * Stops beacon discovery process.
 *
 * @return void
 */
-(void)stopEstimoteBeaconDiscovery;

@end
