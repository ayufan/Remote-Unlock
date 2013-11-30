//
//  ESTBeaconRegion.h
//  EstimoteMacSDK
//
//  Created by Grzegorz Krukiewicz-Gacek on 18.11.2013.
//  Copyright (c) 2013 Estimote. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  ESTBeaconMajorValue
 *
 *  Discussion:
 *    Type represents the most significant value in a beacon.
 *
 */
typedef uint16_t ESTBeaconMajorValue;

/*
 *  ESTBeaconMinorValue
 *
 *  Discussion:
 *    Type represents the least significant value in a beacon.
 *
 */
typedef uint16_t ESTBeaconMinorValue;


/**
 
 A ESTBeaconRegion object defines a type of region that is based on the device’s proximity to a Bluetooth beacon, as opposed to a geographic location. A beacon region looks for devices whose identifying information matches the information you provide. When that device comes in range, the region triggers the delivery of an appropriate notification.
 
 ESTBeaconRegion immitates basic CLBeaconRegion Core Location object known from iOS.
    It allows to directly initialize region that is supported by Estimote Cloud platform.
 
 */
@interface ESTBeaconRegion : NSObject

/**
 *  identifier
 *
 *  Discussion:
 *    Region's identifier
 */
@property (readonly, nonatomic) NSString *identifier;

/**
 *  proximityUUID
 *
 *  Discussion:
 *    Proximity identifier associated with the region.
 *
 */
@property (readonly, nonatomic) NSUUID *proximityUUID;

/**
 *  major
 *
 *  Discussion:
 *    The most significant value representing the region.
 *
 */
@property (readonly, nonatomic) NSNumber *major;

/**
 *  minor
 *
 *  Least significant value representing the region.
 *
 */
@property (readonly, nonatomic) NSNumber *minor;

/**
 * Initialize a Estimote beacon region. Major and minor values will be wildcarded.
 *
 * @param identifier Region identifier
 * @return Initialized ESTBeaconRegion object
 **/
- (id)initRegionWithIdentifier:(NSString *)identifier;

/**
 * Initialize a Estimote beacon region with major value. Minor value will be wildcarded.
 *
 * @param major minor location value
 * @param identifier Region identifier
 * @return Initialized ESTBeaconRegion object
 **/
- (id)initRegionWithMajor:(ESTBeaconMajorValue)major identifier:(NSString *)identifier;

/**
 * Initialize a Estimote beacon region identified by a major and minor values.
 *
 * @param major minor location value
 * @param minor minor location value
 * @param identifier Region identifier
 * @return Initialized ESTBeaconRegion object
 **/
- (id)initRegionWithMajor:(ESTBeaconMajorValue)major minor:(ESTBeaconMinorValue)minor identifier:(NSString *)identifier;

/**
 *  peripheralDataWithMeasuredPower:
 *
 *  @param measuredPower measuredPower value
 *  @return Dictionary for peripheralManager advertisement packet
 *
 **/
- (NSMutableDictionary *)peripheralDataWithMeasuredPower:(NSNumber *)measuredPower;

@end
