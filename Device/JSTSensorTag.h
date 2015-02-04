#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "JSTSensorConstants.h"

@class JSTSensorTag;
@class JSTIRSensor;
@class JSTAccelerometerSensor;
@class JSTGyroscopeSensor;
@class JSTHumiditySensor;
@class JSTKeysSensor;
@class JSTMagnetometerSensor;
@class JSTPressureSensor;

typedef struct {
    float x, y, z;
} JSTVector3D;

extern NSString *const JSTSensorTagDidFinishDiscoveryNotification;

@interface JSTSensorTag : NSObject

@property(nonatomic, readonly) CBPeripheral *peripheral;

@property(nonatomic) NSInteger rssi;

@property(nonatomic, copy) NSString *macAddress;

@property(nonatomic, readonly) JSTIRSensor *irSensor;

@property(nonatomic, readonly) JSTAccelerometerSensor *accelerometerSensor;

@property(nonatomic, readonly) JSTGyroscopeSensor *gyroscopeSensor;

@property(nonatomic, readonly) JSTHumiditySensor *humiditySensor;

@property(nonatomic, readonly) JSTKeysSensor *keysSensor;

@property(nonatomic, readonly) JSTMagnetometerSensor *magnetometerSensor;

@property(nonatomic, readonly) JSTPressureSensor *pressureSensor;

+ (NSArray *)availableServicesUUIDArray;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)discoverServices;

@end
