#import "JSTSensorTag.h"
#import "JSTSensorConstants.h"
#import "JSTSensorManager.h"
#import "JSTIRSensor.h"
#import "JSTAccelerometerSensor.h"
#import "JSTHumiditySensor.h"
#import "JSTMagnetometerSensor.h"
#import "JSTPressureSensor.h"
#import "JSTGyroscopeSensor.h"
#import "JSTKeysSensor.h"
#import "CBUUID+StringRepresentation.h"

NSString *const JSTSensorTagDidFinishDiscoveryNotification = @"JSTSensorTagDidFinishDiscoveryNotification";
NSString *const JSTSensorTagConnectionFailureNotification = @"JSTSensorTagConnectionFailureNotification";
NSString *const JSTSensorTagConnectionFailureNotificationErrorKey = @"JSTSensorTagConnectionFailureNotificationErrorKey";

@interface JSTSensorTag () <CBPeripheralDelegate>
@property(nonatomic, readwrite) CBPeripheral *peripheral;
@property(nonatomic) int numberOfDiscoveredServices;
@property(nonatomic) UInt16 *calibrationDataUnsigned;
@property(nonatomic) int16_t *calibrationDataSigned;
@property(nonatomic, readwrite) JSTIRSensor *irSensor;
@property(nonatomic, readwrite) JSTAccelerometerSensor *accelerometerSensor;
@property(nonatomic, readwrite) JSTGyroscopeSensor *gyroscopeSensor;
@property(nonatomic, readwrite) JSTHumiditySensor *humiditySensor;
@property(nonatomic, readwrite) JSTKeysSensor *keysSensor;
@property(nonatomic, readwrite) JSTMagnetometerSensor *magnetometerSensor;
@property(nonatomic, readwrite) JSTPressureSensor *pressureSensor;
@end

@implementation JSTSensorTag {
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    self = [self init];
    if (self) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
        
        self.calibrationDataUnsigned = (UInt16 *)malloc(sizeof(UInt16) * 8);
        self.calibrationDataSigned = (int16_t *)malloc(sizeof(int16_t) * 8);
        self.numberOfDiscoveredServices = 0;
        
        self.irSensor = [[JSTIRSensor alloc] initWithPeripheral:peripheral];
        self.accelerometerSensor = [[JSTAccelerometerSensor alloc] initWithPeripheral:peripheral];
        self.gyroscopeSensor = [[JSTGyroscopeSensor alloc] initWithPeripheral:peripheral];
        self.humiditySensor = [[JSTHumiditySensor alloc] initWithPeripheral:peripheral];
        self.keysSensor = [[JSTKeysSensor alloc] initWithPeripheral:peripheral];
        self.magnetometerSensor = [[JSTMagnetometerSensor alloc] initWithPeripheral:peripheral];
        self.pressureSensor = [[JSTPressureSensor alloc] initWithPeripheral:peripheral];
    }
    return self;
}

- (void)dealloc {
    if (self.calibrationDataUnsigned) {
        free(self.calibrationDataUnsigned);
    }

    if (self.calibrationDataSigned) {
        free(self.calibrationDataSigned);
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, peripheral.services);

    if (error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
        [[NSNotificationCenter defaultCenter] postNotificationName:JSTSensorTagConnectionFailureNotification object:self userInfo:@{JSTSensorTagConnectionFailureNotificationErrorKey : error}];
    } else {
        for (CBService *service in [peripheral services]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s peripheral:%@, service:%@, characteristics: %@", __PRETTY_FUNCTION__, peripheral.identifier, service, service.characteristics);

    if (error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
        [[NSNotificationCenter defaultCenter] postNotificationName:JSTSensorTagConnectionFailureNotification object:self userInfo:@{JSTSensorTagConnectionFailureNotificationErrorKey : error}];
    } else {

        if ([service.UUID.stringRepresentation isEqualToString:@"180a"]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID.stringRepresentation isEqualToString:@"2a23"]) {
                    [peripheral readValueForCharacteristic:characteristic];
                }
            }
        }
        ++self.numberOfDiscoveredServices;
        [self tryToFinishConnection];
    }
}

- (void)tryToFinishConnection {
    if (self.numberOfDiscoveredServices == [JSTSensorTag availableServicesUUIDArray].count && self.macAddress) {
        [[NSNotificationCenter defaultCenter] postNotificationName:JSTSensorTagDidFinishDiscoveryNotification object:self];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, peripheral.identifier, characteristic);
    NSMutableString* tmpString = [NSMutableString string];
    for (size_t i = characteristic.value.length - 1; i > 0; i -= 1)
    {
        Byte byteValue;
        [characteristic.value getBytes:&byteValue range:NSMakeRange(i, sizeof(Byte))];
        [tmpString appendFormat:@"%02x", byteValue];
    }
    self.macAddress = tmpString;

    [self tryToFinishConnection];
    [[self sensorForCharacteristic:characteristic] processReadFromCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, peripheral.identifier);
    [[self sensorForCharacteristic:characteristic] processWriteFromCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, peripheral.identifier);
    [[self sensorForCharacteristic:characteristic] processNotificationsUpdateFromCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, peripheral, invalidatedServices);
    [peripheral discoverServices:invalidatedServices];
}

#pragma mark -

- (void)discoverServices {
    self.numberOfDiscoveredServices = 0;
    [self.peripheral discoverServices:[JSTSensorTag availableServicesUUIDArray]];
}

#pragma mark -
+ (NSArray *)availableServicesUUIDArray {
    return @[
            [CBUUID UUIDWithString:[JSTIRSensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTAccelerometerSensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTHumiditySensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTMagnetometerSensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTPressureSensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTGyroscopeSensor serviceUUID]],
            [CBUUID UUIDWithString:[JSTKeysSensor serviceUUID]],
            [CBUUID UUIDWithString:@"180A"]
    ];
}


#pragma mark -
- (JSTBaseSensor *)sensorForCharacteristic:(CBCharacteristic *)characteristic {
    NSString *uuid = [[characteristic.service.UUID stringRepresentation] lowercaseString];
    if ([uuid isEqualToString:[[JSTIRSensor serviceUUID] lowercaseString] ]) {
        return self.irSensor;
    } else if ([uuid isEqualToString:[[JSTAccelerometerSensor serviceUUID] lowercaseString] ]) {
        return self.accelerometerSensor;
    } else if ([uuid isEqualToString:[[JSTHumiditySensor serviceUUID] lowercaseString] ]) {
        return self.humiditySensor;
    } else if ([uuid isEqualToString:[[JSTMagnetometerSensor serviceUUID] lowercaseString] ]) {
        return self.magnetometerSensor;
    } else if ([uuid isEqualToString:[[JSTPressureSensor serviceUUID] lowercaseString] ]) {
        return self.pressureSensor;
    } else if ([uuid isEqualToString:[[JSTGyroscopeSensor serviceUUID] lowercaseString] ]) {
        return self.gyroscopeSensor;
    } else if ([uuid isEqualToString:[[JSTKeysSensor serviceUUID] lowercaseString] ]) {
        return self.keysSensor;
    }
    return nil;
}

@end
