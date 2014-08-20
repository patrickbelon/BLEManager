//
//  BLEManager.h
//  BLEManager
//
//  Created by Patrick Belon on 8/8/14.
//  Copyright (c) 2014 nectarLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define DEFAULT_TIMEOUT_INTERVAL 10;

typedef enum{
    NLBluetoothDriverStateUnknown = 0,
    NLBluetoothDriverPoweredOff,
    NLBluetoothDriverPoweredOn,
}NLBluetoothDriverState;


#pragma mark --
#pragma mark protocol
@protocol NLBluetoothDriverDelegate <NSObject>
//- (void) peripheralChangedState:(CBPeripheralState) state;
-(void)disconnected;
-(void)connectionSuccessful;
-(void)connectionError:(NSError*)error;
-(void)driverChangedStated:(NLBluetoothDriverState) state;
-(void)characteristicUUID:(CBUUID*) uuid valueChanged: (NSData*)value error: (NSError *) error;
-(void)characteristicValueWritten:(CBUUID*) uuid error: (NSError*)error;
@end

@protocol NLBluetoothDiscoveryDelegate <NSObject>

- (void) discoveryDidRefresh;
- (void) discoveryStatePoweredOff;
//TODO May add later? 
//- (void) discoveryDidUpdateState:(CBPeripheralState) state;
- (void) searchTimeout;
- (void)discoveredPeripheralsWithMatchingServiceUUIDs:(NSDictionary*)peripherals;
- (void) bluetoothNotSupported;
@end



@interface BLEManager : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

@property           int                         timeoutIntervalInSeconds;
@property (atomic)  NSMutableArray              *discoveredPeripherals;
@property           NLBluetoothDriverState      driverState;
@property           NSUUID                      *connectedPeripheralUUID;

#pragma mark  --
#pragma mark Delegates
@property (nonatomic, weak) id<NLBluetoothDiscoveryDelegate>           discoveryDelegate;
@property (nonatomic, weak) id<NLBluetoothDriverDelegate>       driverDelegate;

+(id)sharedInstance;

#pragma mark --
#pragma mark ACTIONS

-(void)connectToPeripheral:(NSUUID *)peripheralUUID;

//-(void) connectToPeripheralsWithServiceUUIDs:(NSArray*)serviceUUIDS AdvertisementValues:(NSDictionary*)advertisementValues;

-(void) discoverPeripheralsWithServiceUUIDs:(NSArray*) serviceUUIDs;

-(void) disconnect;

-(void) setNotifyForCharacteristicUUIDs: (NSArray*) characteristicUUIDs;

-(void) removeNotifyForCharacteristicUUIDs:(NSArray*) characteristicUUIDs;


@end
