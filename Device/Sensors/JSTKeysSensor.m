#import "JSTKeysSensor.h"

NSString *const JSTSensorSimpleKeysServiceUUID = @"FFE0";

// Simple Keys Characteristic UUID
NSString *const JSTSensorSimpleKeysCharacteristicUUID = @"FFE1";    // Key press state

@interface JSTKeysSensor ()
@property(nonatomic, readwrite) BOOL pressedLeftButton;
@property(nonatomic, readwrite) BOOL pressedRightButton;
@end

@implementation JSTKeysSensor {

}

+ (NSString *)dataCharacteristicUUID {
    return JSTSensorSimpleKeysCharacteristicUUID;
}

+ (NSString *)serviceUUID {
    return JSTSensorSimpleKeysServiceUUID;
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:data.length];

    self.pressedLeftButton = (scratchVal[0] & 0x02) != 0;
    self.pressedRightButton = (scratchVal[0] & 0x01) != 0;
    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

@end
