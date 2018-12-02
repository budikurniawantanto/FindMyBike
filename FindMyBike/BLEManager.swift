//
//  BLEManager.swift
//  team5ui
//
//  Created by budi on 2018/11/30.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var targetService: CBService?
    var vc: UIViewController?
    var peripheralList: Array<CBPeripheral> = []
    var existingPeripheralList: Array<CBPeripheral> = []
    
    var discoveredPeripheral: CBPeripheral?
    var discoveredCharacteristic: CBCharacteristic?
    var discoveredRSSI: NSNumber?
    
    // And somewhere to store the incoming data
    fileprivate let data = NSMutableData()
    var isConnected:Bool! = false
    var ledIndex:Int! = 0
    var valueOn:UInt8 = 1
    var valueOff:UInt8 = 0

    private static var mInstance:BLEManager?
    static func shared() -> BLEManager {
        if mInstance == nil {
            mInstance = BLEManager()
        }
        return mInstance!
    }
    
    /** Initialize CentralManager BLE*/
    func startBLE() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.vc = UIViewController()
    }
    
    /** Scan for peripherals - specifically for our service's 128bit CBUUID*/
    func scan() {
        print("---BLEManager--- Enter scan function")
        centralManager?.scanForPeripherals(
            withServices: [MACtransferServiceUUID], options: nil
        )
        
        print("---BLEManager--- Scanning started")
    }
    
    /** Stop Scan*/
    func stopScan() {
        print("---BLEManager--- Stopping scan")
        centralManager?.stopScan()
    }
   
    /**Connect to selected peripheral*/
    func connect(peripheral: CBPeripheral){
        print("---BLEManager--- Connecting to peripheral \(peripheral)")
        centralManager?.connect(peripheral, options: nil)
    }
    
    /** Collect existing peripheral that connected now*/
    func retrieveExistingPeripheral(){
        existingPeripheralList = (centralManager?.retrieveConnectedPeripherals(withServices: [MACtransferServiceUUID]) ?? nil)!
        print("---BLEManager--- Existing peripheral list = \(existingPeripheralList)")
        if existingPeripheralList.count != 0 {
            connect(peripheral: existingPeripheralList[0])
        }
    }
    
    /** Send command to peripheral device in order to change led light*/
    func ChangeLED(){
        print("---BLEManager--- Start send command to arduino with TransferServiceUUID=\(discoveredPeripheral!.identifier.uuidString), TransferCharacteristicUUID=\(String(describing: discoveredCharacteristic?.uuid))")
        
        //send command to arduino
        if ledIndex == 0 {
            let data = Data(bytes: [valueOn])
            ledIndex = 1
            print("---BLEManager--- data = \(data)")
            discoveredPeripheral!.writeValue(data, for: discoveredCharacteristic!, type: .withResponse)
        }
        else{
            let data = Data(bytes: [valueOff])
            ledIndex = 0
            print("---BLEManager--- data = \(data)")
            discoveredPeripheral!.writeValue(data, for: discoveredCharacteristic!, type: .withResponse)
        }
    }
    
    /** centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\(#line) \(#function)")
        
        if central.state == .poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("---BLEManager--- Bluetooth Already Enabled")
            
            // The state must be CBCentralManagerStatePoweredOn...
            // ... so start scanning
            scan()
            retrieveExistingPeripheral()
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("---BLEManager--- Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.vc!.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            vc!.present(alertVC, animated: true, completion: nil)
        }
    }
    
    /** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
     *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
     *  we start the connection process
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Reject any where the value is above reasonable range
        // Reject if the signal strength is too low to be close enough (Close is around -22dB)
        
        //        if  RSSI.integerValue < -15 && RSSI.integerValue > -35 {
        //            println("Device not at correct range")
        //            return
        //        }
        
        print("---BLEManager--- Discovered Peripheral Device: Name = \(String(describing: peripheral.name)), UUID = \(peripheral.identifier.uuidString), RSSI = \(RSSI)")
        
        // Ok, it's in range - have we already seen it?
        /*if discoveredPeripheral != peripheral {
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripheral = peripheral
            
            // And connect
            connect(peripheral: peripheral)
        }*/
        if peripheralList.contains(peripheral) == false {
            peripheralList.append(peripheral)
        }
        else{
            print("---BLEManager--- peripheral exist: \(peripheral)")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    /** If the connection fails for whatever reason, we need to deal with it. */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("---BLEManager---  Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "failed"), object: nil)
        cleanup()
    }
    
    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic. */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("---BLEManager--- Peripheral Connected")
        
        // Stop scanning
        centralManager?.stopScan()
        print("---BLEManager--- Scanning stopped")
        
        // Clear the data that we may already have
        data.length = 0
        isConnected = true;
        discoveredPeripheral = peripheral
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([MACtransferServiceUUID])
    }
    
    /** The Transfer Service was discovered */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("---BLEManager---  Success discover Transfer Services")
        guard error == nil else {
            print("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        print("---BLEManager--- Services: \(services)")
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        for service in services {
            peripheral.discoverCharacteristics([MACtransferCharacteristicUUID], for: service)
        }
    }
    
    /** The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("---BLEManager--- Success discover Transfer Characteristic")
        
        // Deal with errors (if any)
        guard error == nil else {
            print("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        // Again, we loop through the array, just in case.
        for characteristic in characteristics {
            // And check if it's the right one
            print("---BLEManager--- characteristic UUID = \(characteristic.uuid), properties = \(characteristic.properties)")
            if (characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)) && characteristic.uuid.isEqual(MACtransferCharacteristicUUID) {
                // If it is, subscribe to it
                print("---BLEManager--- Characteristic is match, characteristic UUID = \(characteristic.uuid)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /** This callback lets us know more data has arrived via notification on the characteristic */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        print("---BLEManager--- inside didUpdateValueFor, characteristic UUID = \(characteristic.uuid)")
    }
    
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("---BLEManager--- Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid.isEqual(MACtransferCharacteristicUUID) else {
            return
        }
        
        // Notification has started
        if (characteristic.isNotifying) {
            print("---BLEManager--- Notification began on \(characteristic)")
            discoveredCharacteristic = characteristic
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "success"), object: nil)
        } else { // Notification has stopped
            print("---BLEManager--- Notification stopped on (\(characteristic))  Disconnecting")
            centralManager?.cancelPeripheralConnection(peripheral)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "failed"), object: nil)
        }
    }
    
    /** read RSSI device to determine the range of user and device*/
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            print("---BLEManager--- Error discovering RSSI number: \(error!.localizedDescription)")
            return
        }
        
        discoveredRSSI = RSSI
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "rssi"), object: nil)
    }
    
    /** Once the disconnection happens, we need to clean up our local copy of the peripheral*/
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("---BLEManager--- Peripheral Disconnected")
        discoveredPeripheral = nil
        isConnected = false
        
        // We're disconnected, so start scanning again
        scan()
    }
    
    /** Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    fileprivate func cleanup() {
        // Don't do anything if we're not connected
        // self.discoveredPeripheral.isConnected is deprecated
        guard discoveredPeripheral?.state == .connected else {
            return
        }
        
        // See if we are subscribed to a characteristic on the peripheral
        guard let services = discoveredPeripheral?.services else {
            cancelPeripheralConnection()
            return
        }
        
        for service in services {
            guard let characteristics = service.characteristics else {
                continue
            }
            
            for characteristic in characteristics {
                if characteristic.uuid.isEqual(MACtransferCharacteristicUUID) && characteristic.isNotifying {
                    discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                    // And we're done.
                    return
                }
            }
        }
    }
    
    fileprivate func cancelPeripheralConnection() {
        // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
    }
}