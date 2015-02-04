#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"
#import "JSTSensorTag.h"

typedef enum {
    JSTSensorGyroscopeDisabled          = 0x00,
    JSTSensorGyroscopeXOnly             = 0x01,
    JSTSensorGyroscopeYOnly             = 0x02,
    JSTSensorGyroscopeXAndY             = 0x03,
    JSTSensorGyroscopeZOnly             = 0x04,
    JSTSensorGyroscopeXAndZ             = 0x05,
    JSTSensorGyroscopeYAndZ             = 0x06,
    JSTSensorGyroscopeAllAxis           = 0x07,
} JSTSensorGyroscopeConfig;

@interface JSTGyroscopeSensor : JSTBaseSensor

- (void)calibrate;
- (JSTVector3D)value;
@end
