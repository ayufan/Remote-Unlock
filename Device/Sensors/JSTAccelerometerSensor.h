#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"
#import "JSTSensorTag.h"


typedef enum {
    JSTSensorAccelerometerDisabled      = 0x00,
    JSTSensorAccelerometer2GRange       = 0x01,
    JSTSensorAccelerometer4GRange       = 0x02,
    JSTSensorAccelerometer8GRange       = 0x03,
} JSTSensorAccelerometerConfig;

@interface JSTAccelerometerSensor : JSTBaseSensor
@property(nonatomic, readonly) JSTVector3D acceleration;
@end
