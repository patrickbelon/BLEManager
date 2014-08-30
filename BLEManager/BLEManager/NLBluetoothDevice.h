//
//  NLBluetoothDevice.h
//  BLEManager
//
//  Created by Patrick Belon on 8/27/14.
//  Copyright (c) 2014 nectarLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NLBluetoothDevice : NSObject

@property NSUUID *deviceAddress;
@property NSString *deviceName;
@property NSNumber *rssi;
@property Boolean isConnectable;
@property NSData  *manufacturerData;

@end
