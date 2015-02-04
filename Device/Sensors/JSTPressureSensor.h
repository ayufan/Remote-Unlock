#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"

typedef enum {
    JSTSensorPressureDisabled          = 0x00,
    JSTSensorPressureEnabled           = 0x01,
    JSTSensorPressureReadCalibration   = 0x02,
} JSTSensorBarometerConfig;

@interface JSTPressureSensor : JSTBaseSensor
@property(nonatomic, readonly) int pressure;
@property(nonatomic, readonly) int temperature;

- (void)calibrate;
@end
