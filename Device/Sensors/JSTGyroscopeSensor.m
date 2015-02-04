#import "JSTGyroscopeSensor.h"

#define IMU3000_RANGE 500.0

static NSString *const JSTSensorGyroscopeServiceUUID = @"F000AA50-0451-4000-B000-000000000000";

// Gyroscope Characteristic UUID
static NSString *const JSTSensorGyroscopeDataCharacteristicUUID = @"F000AA51-0451-4000-B000-000000000000";        // XLSB:XMSB:YLSB:YMSB:ZLSB:ZMSB
static NSString *const JSTSensorGyroscopeConfigCharacteristicUUID = @"F000AA52-0451-4000-B000-000000000000";      // Write 0 to turn off gyroscope, 1 to enable X axis only, 2 to enable Y axis only, 3 = X and Y, 4 = Z only, 5 = X and Z, 6 = Y and Z, 7 = X, Y and Z
static NSString *const JSTSensorGyroscopePeriodCharacteristicUUID = @"F000AA53-0451-4000-B000-000000000000";      // Period =[Input*10]ms, (lower limit 100 ms), default 1000 ms

@interface JSTGyroscopeSensor ()
@property(nonatomic) double lastX;
@property(nonatomic) double lastY;
@property(nonatomic) double lastZ;
@property(nonatomic) double calX;
@property(nonatomic) double calY;
@property(nonatomic) double calZ;
@end

@implementation JSTGyroscopeSensor {

}

+ (NSString *)dataCharacteristicUUID {
    return JSTSensorGyroscopeDataCharacteristicUUID;
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;
    //Orientation of sensor on board means we need to swap X and Y (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawX = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    self.lastX = (((float)rawX * 1.0) / ( 65536 / IMU3000_RANGE )) * -1;
    int16_t rawY = ((scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00));
    self.lastY = (((float)rawY * 1.0) / ( 65536 / IMU3000_RANGE )) * -1;
    int16_t rawZ = (scratchVal[4] & 0xff) | ((scratchVal[5] << 8) & 0xff00);
    self.lastZ = ((float)rawZ * 1.0) / ( 65536 / IMU3000_RANGE );

    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

- (void)calibrate {
    self.calX = self.lastX;
    self.calY = self.lastY;
    self.calZ = self.lastZ;
    [self.sensorDelegate sensorDidFinishCalibration:self];
}

+ (NSString *)serviceUUID {
    return JSTSensorGyroscopeServiceUUID;
}

+ (NSString *)configurationCharacteristicUUID {
    return JSTSensorGyroscopeConfigCharacteristicUUID;
}

+ (NSString *)periodCharacteristicUUID {
    return JSTSensorGyroscopePeriodCharacteristicUUID;
}

- (JSTVector3D)value {
    JSTVector3D vector3D = {(float) (self.lastX - self.calX), (float) (self.lastY - self.calY), (float) (self.lastZ - self.calZ)};
    return vector3D;
}


@end
