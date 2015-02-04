#import <Foundation/Foundation.h>
#import "JSTBaseSensor.h"

@interface JSTKeysSensor : JSTBaseSensor
@property(nonatomic, readonly) BOOL pressedLeftButton;
@property(nonatomic, readonly) BOOL pressedRightButton;
@end
