//
//  BLEPeripheralModule.m
//  sportdream
//
//  Created by lili on 2018/5/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "BLEPeripheralModule.h"

@interface BLEPeripheralModule()
@property (nonatomic,strong) CBPeripheralManager* peripheral;
@property (nonatomic,strong) CBMutableCharacteristic* characteristic;
@property (nonatomic,strong) CBMutableService* service;
@property (nonatomic,strong) NSMutableDictionary<NSString*,CBCentral*>* mBluetoothDevices;
@property (nonatomic,strong) NSData* groupPendingData; //群发的需要重发的信息

@property (nonatomic,strong) NSString* serviceName;
@property (nonatomic,strong) CBUUID* serviceUUID;
@property (nonatomic,strong) CBUUID* characteristicUUID;
@end

@implementation BLEPeripheralModule
RCT_EXPORT_MODULE(BLEPeripheralModule)
- (NSArray<NSString *> *)supportedEvents
{
  return @[
           @"peripheralManagerDidStartAdvertising",
           @"sendToAllSubscribersError",
           @"reSendToAllSubscribersError",
           @"sendToSingleSubscriberError",
           @"didSubscribeToCharacteristic",
           @"didUnsubscribeFromCharacteristic",
           @"didReceiveWriteRequests"
           ];
}

RCT_EXPORT_METHOD(startPeripheral)
{
  self.peripheral = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
  self.serviceName = @"P2PNode";
  self.serviceUUID = [CBUUID UUIDWithString:@"00007e57-0000-1000-8000-00805f9b34fb"];
  self.characteristicUUID = [CBUUID UUIDWithString:@"13333333-3333-3333-3333-333333330003"];
  self.mBluetoothDevices = [[NSMutableDictionary alloc] init];
  [self enableService];
}

RCT_EXPORT_METHOD(stopPeripheral)
{
  [self disableService];
  self.peripheral = nil;
  self.serviceName = nil;
  self.serviceUUID = nil;
  self.characteristicUUID = nil;
  self.mBluetoothDevices = nil;
}

RCT_EXPORT_METHOD(notifyAllDevice:(NSString*)message)
{
  NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
  [self sendToAllSubscribers:data];
}

RCT_EXPORT_METHOD(notifyDeviceByUUID:(NSString*)message centralUUID:(NSString*)centralUUID)
{
  NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
  CBCentral* central = [self.mBluetoothDevices valueForKey:centralUUID];
  if(central){
    [self sendToSingleSubscriber:data central:central];
  }
}

-(void)startAdvertising
{
  if(self.peripheral.isAdvertising){
    [self.peripheral stopAdvertising];
  }
  
  NSDictionary *advertisment = @{
                                 CBAdvertisementDataServiceUUIDsKey : @[self.serviceUUID],
                                 CBAdvertisementDataLocalNameKey: self.serviceName
                                 };
  [self.peripheral startAdvertising:advertisment];
}

-(void)stopAdvertising
{
  [self.peripheral stopAdvertising];
}

-(BOOL)isAdvertising
{
  return [self.peripheral isAdvertising];
}

-(void)enableService
{
  if(self.service){
    // If the service is already registered, we need to re-register it again.
    [self.peripheral removeService:self.service];
  }
    // Create a BTLE Peripheral Service and set it to be the primary. If it
    // is not set to the primary, it will not be found when the app is in the
    // background.
    self.service = [[CBMutableService alloc]
                    initWithType:self.serviceUUID primary:YES];
    
    // Set up the characteristic in the service. This characteristic is only
    // readable through subscription (CBCharacteristicsPropertyNotify) and has
    // no default value set.
    //
    // There is no need to set the permission on characteristic.
    self.characteristic =
    [[CBMutableCharacteristic alloc]
     initWithType:self.characteristicUUID
     properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse
     value:nil
     permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    
    // Assign the characteristic.
    self.service.characteristics =
    [NSArray arrayWithObject:self.characteristic];
    
    // Add the service to the peripheral manager.
    [self.peripheral addService:self.service];
}

-(void)disableService
{
  [self.peripheral removeService:self.service];
  self.service = nil;
  [self stopAdvertising];
}

//群发
-(void)sendToAllSubscribers:(NSData *)data {
  if (self.peripheral.state != CBPeripheralManagerStatePoweredOn) {
    return;
  }
  BOOL success = [self.peripheral updateValue:data
                            forCharacteristic:self.characteristic
                         onSubscribedCentrals:nil];
  if (!success) {
    [self sendEventWithName:@"sendToAllSubscribersError" body:@{}];
    self.groupPendingData = data;
    return;
  }
}

//重新群发
-(void)reSendToAllSubscribers:(NSData *)data {
  if (self.peripheral.state != CBPeripheralManagerStatePoweredOn) {
    return;
  }
  BOOL success = [self.peripheral updateValue:data
                            forCharacteristic:self.characteristic
                         onSubscribedCentrals:nil];
  if (!success) {
    [self sendEventWithName:@"reSendToAllSubscribersError" body:@{}];
    self.groupPendingData = data;
    return;
  }
}

//单发
-(void)sendToSingleSubscriber:(NSData*)data central:(CBCentral*)central
{
  if (self.peripheral.state != CBPeripheralManagerStatePoweredOn) {
    return;
  }
  BOOL success = [self.peripheral updateValue:data
                            forCharacteristic:self.characteristic
                         onSubscribedCentrals:@[central]];
  if (!success) {
    [self sendEventWithName:@"sendToSingleSubscriberError" body:@{@"CentralUUID":central.identifier.UUIDString}];
    return;
  }
}


//CBPeripheralManagerDelegate
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
  // As soon as the service is added, we should start advertising.
  [self startAdvertising];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  switch (peripheral.state) {
    case CBPeripheralManagerStatePoweredOn:
      NSLog(@"peripheralStateChange: Powered On");
      // As soon as the peripheral/bluetooth is turned on, start initializing
      // the service.
      [self enableService];
      break;
    case CBPeripheralManagerStatePoweredOff: {
      NSLog(@"peripheralStateChange: Powered Off");
      [self disableService];
      break;
    }
    case CBPeripheralManagerStateResetting: {
      NSLog(@"peripheralStateChange: Resetting");
      break;
    }
    case CBPeripheralManagerStateUnauthorized: {
      NSLog(@"peripheralStateChange: Deauthorized");
      [self disableService];
      break;
    }
    case CBPeripheralManagerStateUnsupported: {
      NSLog(@"peripheralStateChange: Unsupported");
      // TODO: Give user feedback that Bluetooth is not supported.
      break;
    }
    case CBPeripheralManagerStateUnknown:
      NSLog(@"peripheralStateChange: Unknown");
      break;
    default:
      break;
  }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  //收到中心设备的订阅请求，对应socket的connect事件
  NSString* uuid = central.identifier.UUIDString;
  [self.mBluetoothDevices setValue:central forKey:uuid];
  [self sendEventWithName:@"didSubscribeToCharacteristic" body:@{@"CentralUUID":uuid}];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
  //收到中心设备的取消订阅请求，对应socket的断开连接事件
  NSString* uuid = central.identifier.UUIDString;
  [self.mBluetoothDevices removeObjectForKey:uuid];
  [self sendEventWithName:@"didUnsubscribeFromCharacteristic" body:@{@"CentralUUID":uuid}];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
  if (error) {
    return;
  }
  [self sendEventWithName:@"peripheralManagerDidStartAdvertising" body:@{}];
}

//如果发送失败，在这里进行重发
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
  if (self.groupPendingData) {
    NSData *data = [self.groupPendingData copy];
    self.groupPendingData = nil;
    [self reSendToAllSubscribers:data];
  }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
  if([request.characteristic.UUID isEqual:self.characteristic.UUID]){
    NSString* value = @"CharacteristicValue";
    request.value = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral respondToRequest:request withResult:CBATTErrorSuccess];
  }else{
    [self.peripheral respondToRequest:request withResult:CBATTErrorAttributeNotFound];
  }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
  CBATTRequest* request  = [requests objectAtIndex:0];
  if([request.characteristic.UUID isEqual:self.characteristic.UUID]){
    NSString* value = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
    [self.peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    [self sendEventWithName:@"didReceiveWriteRequests" body:@{@"CentralUUID":request.central.identifier.UUIDString,@"value":value}];
  }else{
    [self.peripheral respondToRequest:request withResult:CBATTErrorAttributeNotFound];
  }
}

@end
