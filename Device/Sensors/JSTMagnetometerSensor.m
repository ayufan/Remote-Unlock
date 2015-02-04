#import "JSTMagnetometerSensor.h"

#define MAG3110_RANGE 2000.0

static NSString *const JSTSensorMagnetometerServiceUUID = @"F000AA30-0451-4000-B000-000000000000";

// Magnetometer Characteristic UUID
static NSString *const JSTSensorMagnetometerDataCharacteristicUUID = @"F000AA31-0451-4000-B000-000000000000";     // XLSB:XMSB:YLSB:YMSB:ZLSB:ZMSB Coordinates
static NSString *const JSTSensorMagnetometerConfigCharacteristicUUID = @"F000AA32-0451-4000-B000-000000000000";   // Write "01" to start Sensor and Measurements, "00" to put to sleep
static NSString *const JSTSensorMagnetometerPeriodCharacteristicUUID = @"F000AA33-0451-4000-B000-000000000000";   // Period =[Input*10]ms, (lower limit 100 ms), default 2000 ms

@interface JSTMagnetometerSensor ()
@property(nonatomic) double lastX;
@property(nonatomic) double lastY;
@property(nonatomic) double lastZ;
@property(nonatomic) double calX;
@property(nonatomic) double calY;
@property(nonatomic) double calZ;
@end

@implementation JSTMagnetometerSensor {

}

-(void)calibrate {
    self.calX = self.lastX;
    self.calY = self.lastY;
    self.calZ = self.lastZ;
    [self.sensorDelegate sensorDidFinishCalibration:self];
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;
    // Orientation of sensor on board means we need to swap X and Y (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawX = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    int16_t rawY = ((scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00));
    int16_t rawZ = (scratchVal[4] & 0xff) | ((scratchVal[5] << 8) & 0xff00);
    self.lastX = (((float)rawX * 1.0) / ( 65536 / MAG3110_RANGE )) * -1;
    self.lastY = (((float)rawY * 1.0) / ( 65536 / MAG3110_RANGE )) * -1;
    self.lastZ =  ((float)rawZ * 1.0) / ( 65536 / MAG3110_RANGE );

    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

- (JSTVector3D)value {
    JSTVector3D vector3D = {(float) (self.lastX - self.calX), (float) (self.lastY - self.calY), (float) (self.lastZ - self.calZ)};
    return vector3D;
}


+ (NSString *)serviceUUID {
    return JSTSensorMagnetometerServiceUUID;
}

+ (NSString *)configurationCharacteristicUUID {
    return JSTSensorMagnetometerConfigCharacteristicUUID;
}

+ (NSString *)periodCharacteristicUUID {
    return JSTSensorMagnetometerPeriodCharacteristicUUID;
}

+ (NSString *)dataCharacteristicUUID {
    return JSTSensorMagnetometerDataCharacteristicUUID;
}

@end
