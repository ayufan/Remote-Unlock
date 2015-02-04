#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class JSTBaseSensor;

@protocol JSTBaseSensorDelegate<NSObject>
- (void)sensorDidUpdateValue:(JSTBaseSensor *)sensor;
- (void)sensorDidFailCommunicating:(JSTBaseSensor *)sensor withError:(NSError *)error;
- (void)sensorDidFinishCalibration:(JSTBaseSensor *)sensor;
@end

@interface JSTBaseSensor : NSObject

@property (nonatomic, readonly) CBPeripheral *peripheral;
@property (nonatomic, weak) id<JSTBaseSensorDelegate> sensorDelegate;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)configureWithValue:(char)value;
- (void)setPeriodValue:(char)periodValue;
- (void)setNotificationsEnabled:(BOOL)enabled;

- (BOOL)canBeConfigured;
- (BOOL)canSetPeriod;

- (CBCharacteristic *)characteristicForUUID:(NSString *)UUID;

// Methods to override
- (BOOL)processReadFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (BOOL)processWriteFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (BOOL)processNotificationsUpdateFromCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

+ (NSString *)serviceUUID;
+ (NSString *)configurationCharacteristicUUID;
+ (NSString *)periodCharacteristicUUID;
+ (NSString *)dataCharacteristicUUID;
@end
