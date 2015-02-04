#import "JSTIRSensor.h"
#import "JSTSensorConstants.h"

static NSString *const JSTSensorIRTemperatureServiceUUID = @"F000AA00-0451-4000-B000-000000000000";

// Temperature Sensor Characteristic UUID
static NSString *const JSTSensorIRTemperatureDataCharacteristicUUID = @"F000AA01-0451-4000-B000-000000000000";    // ObjectLSB:ObjectMSB:AmbientLSB:AmbientMSB
static NSString *const JSTSensorIRTemperatureConfigCharacteristicUUID = @"F000AA02-0451-4000-B000-000000000000";  // Write "01" to start Sensor and Measurements, "00" to put to sleep
static NSString *const JSTSensorIRTemperaturePeriodCharacteristicUUID = @"F000AA03-0451-4000-B000-000000000000";  // Period =[Input*10]ms, (lower limit 300 ms), default 1000 ms

@interface JSTIRSensor ()
@property(nonatomic, readwrite) float ambientTemperature;
@end

@implementation JSTIRSensor {

}

+ (NSString *)dataCharacteristicUUID {
    return JSTSensorIRTemperatureDataCharacteristicUUID;
}

+ (NSString *)serviceUUID {
    return JSTSensorIRTemperatureServiceUUID;
}

+ (NSString *)configurationCharacteristicUUID {
    return JSTSensorIRTemperatureConfigCharacteristicUUID;
}

+ (NSString *)periodCharacteristicUUID {
    return JSTSensorIRTemperaturePeriodCharacteristicUUID;
}

- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![super processReadFromCharacteristic:characteristic error:error]) {
        return NO;
    }

    NSData *data = characteristic.value;
    char scratchVal[data.length];
    int16_t ambTemp;
    int16_t objTemp;
    [data getBytes:(void *)&scratchVal length:data.length];
    ambTemp = (int16_t) ((scratchVal[2] & 0xff)| ((scratchVal[3] << 8) & 0xff00));
    objTemp = (scratchVal[0] & 0xff)| ((scratchVal[1] << 8) & 0xff00);
    
    self.ambientTemperature = ambTemp / 128.f;
    
    float temp = (float)((float)ambTemp / (float)128);
    long double Vobj2 = (double)objTemp * .00000015625;
    long double Tdie2 = (double)temp + 273.15;
    long double S0 = 6.4*pow(10,-14);
    long double a1 = 1.75*pow(10,-3);
    long double a2 = -1.678*pow(10,-5);
    long double b0 = -2.94*pow(10,-5);
    long double b1 = -5.7*pow(10,-7);
    long double b2 = 4.63*pow(10,-9);
    long double c2 = 13.4f;
    long double Tref = 298.15;
    long double S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2));
    long double Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2);
    long double fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2);
    long double Tobj = pow(pow(Tdie2,4) + (fObj/S),.25);
    Tobj = (Tobj - 273.15);
    
    self.objectTemperature = (float)Tobj;

    [self.sensorDelegate sensorDidUpdateValue:self];
    return YES;
}

@end
