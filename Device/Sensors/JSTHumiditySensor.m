#import "JSTHumiditySensor.h"

static NSString *const JSTSensorHumidityServiceUUID = @"F000AA20-0451-4000-B000-000000000000";

static NSString *const JSTSensorHumidityDataCharacteristicUUID = @"F000AA21-0451-4000-B000-000000000000";         // TempLSB:TempMSB:HumidityLSB:HumidityMSB
static NSString *const JSTSensorHumidityConfigCharacteristicUUID = @"F000AA22-0451-4000-B000-000000000000";       // Write "01" to start measurements, "00" to stop
static NSString *const JSTSensorHumidityPeriodCharacteristicUUID = @"F000AA23-0451-4000-B000-000000000000";       // Period =[Input*10]ms, (lower limit 100 ms), default 1000 ms


@interface JSTHumiditySensor ()
@property(nonatomic, readwrite) float humidity;
@property(nonatomic, readwrite) UInt16 temperature;
@end

@implementation JSTHumiditySensor {

}

+ (NSString *)dataCharacteristicUUID {
    return JSTSensorHumidityDataCharacteristicUUID;
}

+ (NSString *)serviceUUID {
    return JSTSensorHumidityServiceUUID;
}

+ (NSString *)configurationCharacteristicUUID {
    return JSTSensorHumidityConfigCharacteristicUUID;
}

+ (NSString *)periodCharacteristicUUID {
    return JSTSensorHumidityPeriodCharacteristicUUID;
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:data.length];
    UInt16 hum;
    float rHVal;
    hum = (scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00);
    rHVal = -6.0f + 125.0f * hum / 65535.f;
    UInt16 temp;
    temp = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    
    self.temperature = temp;
    self.humidity = rHVal;
    
    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

@end
