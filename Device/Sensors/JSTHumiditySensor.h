#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"

typedef enum {
    JSTSensorHumidityDisabled           = 0x00,
    JSTSensorHumidityEnabled            = 0x01,
} JSTSensorHumidityConfig;

@interface JSTHumiditySensor : JSTBaseSensor
@property(nonatomic, readonly) float humidity;
@property(nonatomic, readonly) UInt16 temperature;
@end
