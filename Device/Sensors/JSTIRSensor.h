#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"

typedef enum {
    JSTSensorIRTemperatureDisabled      = 0x00,
    JSTSensorIRTemperatureEnabled       = 0x01,
} JSTSensorIRTemperatureConfig;

@interface JSTIRSensor : JSTBaseSensor
@property(nonatomic, readonly) float ambientTemperature;
@property(nonatomic) float objectTemperature;
@end
