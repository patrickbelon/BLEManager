//
//  BLEManager.m
//  BLEManager
//
//  Created by Patrick Belon on 8/8/14.
//  Copyright (c) 2014 nectarLabs. All rights reserved.
//

#import "BLEManager.h"

@interface BLEManager()
{
    @private bool isBluetoothSupported;
}
    @property CBCentralManager  *centralManager;
    @property CBPeripheral      *connectedPeripheral;
    //TODO weak? Who's responsibility is it?
    @property (weak) NSArray    *interestedServices;
    @property   NSMutableArray  *foundDevices;
    @property   NSMutableDictionary *UUIDAndAdvertisementData;
@end


@implementation BLEManager

#pragma mark Init
+ (id) sharedInstance
{
	static BLEManager *this	= nil;
    
	if (!this)
		this = [[BLEManager alloc] init];
    
	return this;
}

- (id)init{
    self = [super init];
    if (self) {
        self.driverState = NLBluetoothDriverStateUnknown;
		self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        
		self.discoveredPeripherals      =   [[NSMutableArray alloc] init];
        self.timeoutIntervalInSeconds   =   DEFAULT_TIMEOUT_INTERVAL;
        self.UUIDAndAdvertisementData                =   [[NSMutableDictionary alloc]init];
	}
    return self;
}

#pragma mark --
#pragma mark --CENTRAL MANAGER DELEGATE--
#pragma mark Monitoring Connections

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.driverDelegate connectionSuccessful];
    self.connectedPeripheral = peripheral;
    self.connectedPeripheral.delegate = self;
    self.connectedPeripheralUUID = self.connectedPeripheral.identifier;
    
    [self.connectedPeripheral discoverServices:self.interestedServices];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if(error!=nil){
        NSLog(@"error: %@",error.localizedFailureReason);
    }
    self.connectedPeripheral = nil;
    self.connectedPeripheral.delegate = nil;
    self.connectedPeripheralUUID = nil;
    [self.driverDelegate disconnected];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    [self.driverDelegate connectionError:error];
    NSLog(@"Error connecting peripheral: %@, with error: %@",peripheral.name,error.localizedFailureReason);
}


#pragma mark Discovering and Retrieving Peripherals

//Here do checking if there are multiple discovered peripherals and then update higher layer.
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    if (![self.discoveredPeripherals containsObject:peripheral]) {
        NSLog(@"Found periph: %@",peripheral.name);
		[self.discoveredPeripherals addObject:peripheral];
        [self.UUIDAndAdvertisementData setObject:advertisementData forKey:peripheral.identifier];
        
        [self.discoveryDelegate discoveryDidRefresh];
        [self.discoveryDelegate discoveredPeripheralsWithMatchingServiceUUIDs:self.UUIDAndAdvertisementData];
	}
    
}

-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals{
    
}

-(void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    
}

#pragma mark Monitoring Changes to the Central Manager’s State
//TODO
//-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict{
//    
//}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch(central.state){
        case CBCentralManagerStateUnknown:
            self.driverState = NLBluetoothDriverStateUnknown;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverStateUnknown];
            NSLog(@"Central manager changed state: %@",@"Unknown");
            break;
        case CBCentralManagerStateResetting:
            self.driverState = NLBluetoothDriverStateUnknown;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverStateUnknown];
            NSLog(@"Central manager changed state: %@",@"Resetting");
            break;
        case CBCentralManagerStateUnsupported:
            isBluetoothSupported = NO;
            self.driverState = NLBluetoothDriverPoweredOff;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverPoweredOff];
            [self.discoveryDelegate bluetoothNotSupported];
            NSLog(@"Central manager changed state: %@",@"Unsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            isBluetoothSupported = NO;
            self.driverState = NLBluetoothDriverPoweredOff;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverPoweredOff];
            [self.discoveryDelegate bluetoothNotSupported];
            NSLog(@"Central manager changed state: %@",@"Unauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            self.driverState = NLBluetoothDriverPoweredOff;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverPoweredOff];
            NSLog(@"Central manager changed state: %@",@"Powered Off");
            break;
        case CBCentralManagerStatePoweredOn:
            self.driverState = NLBluetoothDriverPoweredOn;
            [self.driverDelegate driverChangedStated:NLBluetoothDriverPoweredOn];
            NSLog(@"Central manager changed state: %@",@"Powered On");
            break;
    }
}

#pragma mark --
#pragma mark --CB_PERIPHERAL_DELEGATE--
#pragma mark Discovering Services
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if(error==nil)
    {
        for(CBService *service in peripheral.services){
            NSLog(@"Discovered service: %@",service.UUID.UUIDString);
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    else{
        //TODO report error
        NSLog(@"error: %@",error.localizedFailureReason);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    //TODO implementation
    
}

#pragma mark Discovering Characteristics and Characteristic Descriptors
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if(error==nil){
        for(CBCharacteristic *character in peripheral.services)
        {
            NSLog(@"Discovered characteristic: %@ for service %@",character.UUID.UUIDString,service.UUID.UUIDString);
        }
    }
    else {
        //TODO Report error
        NSLog(@"error: %@",error.localizedFailureReason);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //TODO
}

#pragma mark Retrieving Characteristic and Characteristic Descriptor Values
-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error==nil)
    {
        NSLog(@"update succeeded for characteristic: %@",characteristic.UUID.UUIDString);
    }
    else{
        NSLog(@"error: %@",error.localizedFailureReason);
    }
    [self.driverDelegate characteristicUUID:characteristic.UUID valueChanged:characteristic.value error:error];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    
}

#pragma mark Writing Characteristic and Characteristic Descriptor Values
-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error==nil){
        NSLog(@"Write success for characteristic: %@",characteristic.UUID.UUIDString);
    }
    else {
        NSLog(@"error: %@",error.localizedFailureReason);
    }
    [self.driverDelegate characteristicValueWritten:characteristic.UUID error:error];
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //TODO Implementation
}

#pragma mark Managing Notifications for a Characteristics Value
-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"characteristic %@ updated notification state to: %@",characteristic.UUID.UUIDString, characteristic.isNotifying? @"YES": @"NO");
}

#pragma mark Peripheral RSSI
-(void) peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    //TODO
}

#pragma mark Monitoring Changes to a Peripherals Name or Services
-(void) peripheralDidUpdateName:(CBPeripheral *)peripheral{
    //TODO
}

-(void) peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices{
    //TODO
}

#pragma mark --
#pragma mark --ACTIONS--
#pragma mark Discovery
-(void) discoverPeripheralsWithServiceUUIDs:(NSArray*) serviceUUIDs{
    if(self.driverState == NLBluetoothDriverPoweredOn){
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
        self.interestedServices = serviceUUIDs;
    }
    else {
        //TODO report error
    }
}

#pragma mark Connection
-(void)connectToPeripheral:(NSUUID*)peripheralUUID{
    
    if(self.driverState == NLBluetoothDriverPoweredOn){
        [self.centralManager stopScan];
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
        
        for(CBPeripheral *periph in self.discoveredPeripherals){
            if([periph.identifier isEqual:peripheralUUID]){
                [self.centralManager connectPeripheral:periph options:options];
            }
        }
    
    }
    else {
        //TODO report error
    }
    
}

-(void)disconnect{
    if(self.driverState == NLBluetoothDriverPoweredOn){
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    }
    else {
        //TODO report error
    }
    
}

#pragma mark Notify for Characteristics
-(void) setNotifyForCharacteristicUUIDs:(NSArray *)characteristicUUIDs{
    
    //TODO Error checking and alert if UUID does not exist.
    
    
    for (CBService *service in self.connectedPeripheral.services) {
        for(CBCharacteristic *charac in service.characteristics)
        {
            if([characteristicUUIDs containsObject:charac.UUID]){
                [self.connectedPeripheral setNotifyValue:YES forCharacteristic:charac];
            }
        }
    }
    
}

-(void) removeNotifyForCharacteristicUUIDs:(NSArray *)characteristicUUIDs{
    
    //TODO Error checking and alert if UUID does not exist.
    
    for (CBService *service in self.connectedPeripheral.services) {
        for(CBCharacteristic *charac in service.characteristics)
        {
            if([characteristicUUIDs containsObject:charac.UUID]){
                [self.connectedPeripheral setNotifyValue:NO forCharacteristic:charac];
            }
        }
    }
    
}


@end
