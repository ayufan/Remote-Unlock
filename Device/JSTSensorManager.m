#import "JSTSensorManager.h"
#import "JSTSensorTag.h"
#import "CBUUID+StringRepresentation.h"

static NSTimeInterval JSTWatchdogInterval = 15.f;

static NSString *const kJSTSensorManagerLastDeviceUUID = @"kJSTSensorManagerLastDeviceUUID";
static NSString *const JSTSensorManagerNoDeviceError = @"No device found.";
static NSString *const JSTSensorManagerConnectionTimeoutError = @"Connection timeout.";

NSString *const JSTSensorTagErrorDomain = @"JSTSensorTagErrorDomain";

@interface JSTSensorManager ()
@property(nonatomic, strong) CBCentralManager *centralManager;
@property(nonatomic) BOOL shouldStartScanning;
@property(nonatomic, strong) NSMutableDictionary *peripherals;
@property(nonatomic) BOOL isScanning;
@property(nonatomic, strong) JSTSensorTag *connectingSensor;
@property(nonatomic, strong) NSTimer *watchdogTimer;
@end

@implementation JSTSensorManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_queue_create("JitterTISensorTagManagerQueue", DISPATCH_QUEUE_SERIAL)];
        self.peripherals = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDiscovery:) name:JSTSensorTagDidFinishDiscoveryNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopWatchdog];
}


- (void)finishedDiscovery:(NSNotification *)finishedDiscovery {
    [self stopWatchdog];
    [self.delegate manager:self didConnectSensor:finishedDiscovery.object];
}

#pragma mark -

- (void)startScanning {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.shouldStartScanning = YES;
    [self scan];
}

- (void)stopScanning {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.centralManager stopScan];
}

- (void)connectSensorWithUUID:(NSUUID *)uuid {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, uuid);
    JSTSensorTag *sensorTag = self.peripherals[uuid.UUIDString];
    if (sensorTag) {
        [self.centralManager connectPeripheral:sensorTag.peripheral options:nil];
        [self startWatchdogForSensor:sensorTag];
    } else {
        CBPeripheral *peripheral = [[self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]] firstObject];
        if (peripheral) {
            sensorTag = [[JSTSensorTag alloc] initWithPeripheral:peripheral];
            self.peripherals[uuid.UUIDString] = sensorTag;
            [self.centralManager connectPeripheral:peripheral options:nil];
            [self startWatchdogForSensor:sensorTag];
        } else {
            [self.delegate manager:self didFailToConnectToSensorWithError:[NSError errorWithDomain:JSTSensorTagErrorDomain code:JSTSensorManagerErrorNoDeviceFound userInfo:@{NSLocalizedDescriptionKey : JSTSensorManagerNoDeviceError}]];
        }
    }
}

- (void)startWatchdogForSensor:(JSTSensorTag *)sensor {
    [self stopWatchdog];
    self.connectingSensor = sensor;
    self.watchdogTimer = [NSTimer timerWithTimeInterval:JSTWatchdogInterval
                                                     target:self
                                                   selector:@selector(watchdogFired)
                                                   userInfo:nil
                                                    repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.watchdogTimer forMode:NSDefaultRunLoopMode];
}

- (void)watchdogFired {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.centralManager cancelPeripheralConnection:self.connectingSensor.peripheral];
    [self.delegate manager:self didFailToConnectToSensorWithError:[NSError errorWithDomain:JSTSensorTagErrorDomain code:JSTSensorManagerTimeout userInfo:@{NSLocalizedDescriptionKey : JSTSensorManagerConnectionTimeoutError}]];

    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
}

- (void)connectNearestSensor {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(findNearestAndConnect) withObject:nil afterDelay:10 inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    });
    [self startScanning];
}

- (void)connectLastSensor {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self connectSensorWithUUID:[[NSUUID alloc] initWithUUIDString:[[NSUserDefaults standardUserDefaults] objectForKey:kJSTSensorManagerLastDeviceUUID]]];
}

- (BOOL)hasPreviouslyConnectedSensor {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kJSTSensorManagerLastDeviceUUID] != nil;
}

- (void)findNearestAndConnect {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self stopScanning];
    NSArray *sortedPeripherals = [[self.peripherals allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(rssi)) ascending:NO]]];
    if (sortedPeripherals.count == 0) {
        [self.delegate manager:self didFailToConnectToSensorWithError:[NSError errorWithDomain:JSTSensorTagErrorDomain code:JSTSensorManagerErrorNoDeviceFound userInfo:@{NSLocalizedDescriptionKey : JSTSensorManagerNoDeviceError}]];
    } else {
        JSTSensorTag *tag = [sortedPeripherals firstObject];
        [self connectSensorWithUUID:tag.peripheral.identifier];
    }
}

- (void)scan {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.shouldStartScanning && self.centralManager.state == CBCentralManagerStatePoweredOn) {
        self.shouldStartScanning = NO;
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self.delegate manager:self didChangeStateTo:central.state];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // NSLog(@"%s %@", __PRETTY_FUNCTION__, peripheral);
    JSTSensorTag *sensor = self.peripherals[peripheral.identifier.UUIDString];
    if (!sensor && ([peripheral.name isEqualToString:@"SensorTag"] || [peripheral.name isEqualToString:@"TI BLE Sensor Tag"])) {
        sensor = [[JSTSensorTag alloc] initWithPeripheral:peripheral];
        self.peripherals[peripheral.identifier.UUIDString] = sensor;
    }
    sensor.rssi = [RSSI integerValue];

    [self.delegate manager:self didDiscoverSensor:sensor];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, peripheral);
    [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier.UUIDString forKey:kJSTSensorManagerLastDeviceUUID];
    [[NSUserDefaults standardUserDefaults] synchronize];

    JSTSensorTag *sensor = self.peripherals[peripheral.identifier.UUIDString];
    [sensor discoverServices];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, peripheral, error);
    [self.delegate manager:self didFailToConnectToSensorWithError:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, peripheral, error);
    [self.delegate manager:self didDisconnectSensor:self.peripherals[peripheral.identifier.UUIDString] error:error];
}

- (CBCentralManagerState)state {
    return self.centralManager.state;
}

- (void)disconnectSensor:(JSTSensorTag *)sensorTag {
    [self stopWatchdog];
    if (sensorTag.peripheral) {
        [self.centralManager cancelPeripheralConnection:sensorTag.peripheral];
    }
}

- (void)stopWatchdog {
    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
}

- (NSArray *)sensors {
    return [self.peripherals allValues];
}

@end
