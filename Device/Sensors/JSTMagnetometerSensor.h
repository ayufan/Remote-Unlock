#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"
#import "JSTSensorTag.h"

typedef enum {
    JSTSensorMagnetometerDisabled       = 0x00,
    JSTSensorMagnetometerEnabled        = 0x01,
} JSTSensorMagnetometerConfig;

@interface JSTMagnetometerSensor : JSTBaseSensor
- (JSTVector3D)value;
-(void)calibrate;
@end
