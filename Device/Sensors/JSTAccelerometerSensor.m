#import "JSTAccelerometerSensor.h"
#import "JSTSensorTag.h"

static NSString *const JSTSensorAccelerometerServiceUUID = @"F000AA10-0451-4000-B000-000000000000";

// Accelerometer Characteristic UUID
static NSString *const JSTSensorAccelerometerDataCharacteristicUUID = @"F000AA11-0451-4000-B000-000000000000";    // X:Y:Z Coordinates
static NSString *const JSTSensorAccelerometerConfigCharacteristicUUID = @"F000AA12-0451-4000-B000-000000000000";  // Write "01" to select range 2G, "02" for 4G, "03" for 8G, "00" disable sensor
static NSString *const JSTSensorAccelerometerPeriodCharacteristicUUID = @"F000AA13-0451-4000-B000-000000000000";  // Period =[Input*10]ms, (lower limit 100 ms), default 1000 ms

@interface JSTAccelerometerSensor ()
@property(nonatomic) char range;
@property(nonatomic, readwrite) JSTVector3D acceleration;
@end

@implementation JSTAccelerometerSensor {

}

- (void)configureWithValue:(char)value {
    [super configureWithValue:value];
    self.range = value;
}


+ (NSString *)dataCharacteristicUUID {
    return JSTSensorAccelerometerDataCharacteristicUUID;
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;

    //Orientation of sensor on board means we need to swap Y (multiplying with -1)
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    float x = ((scratchVal[0] * 1.0) / (256 / [self currentRange]));
    float y = ((scratchVal[1] * 1.0) / (256 / [self currentRange])) * -1;
    float z = ((scratchVal[2] * 1.0) / (256 / [self currentRange]));
    
    JSTVector3D vector3D = {x, y, z};
    self.acceleration = vector3D;

    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

+ (NSString *)serviceUUID {
    return JSTSensorAccelerometerServiceUUID;
}

+ (NSString *)configurationCharacteristicUUID {
    return JSTSensorAccelerometerConfigCharacteristicUUID;
}

+ (NSString *)periodCharacteristicUUID {
    return JSTSensorAccelerometerPeriodCharacteristicUUID;
}

#pragma mark -
- (float)currentRange {
    switch (self.range) {
        case JSTSensorAccelerometer2GRange:
            return 2.f;
        case JSTSensorAccelerometer4GRange:
            return 4.f;
        case JSTSensorAccelerometer8GRange:
            return 8.f;
        default:
            return -1.f;
    }
}

@end
