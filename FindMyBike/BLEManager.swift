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
    var transferServiceUUID:CBUUID = MACtransferServiceUUID
    var transferCharacteristicUUID:CBUUID = MACtransferCharacteristicUUID

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
    func startScan() {
        NSLog("---BLEManager--- Start scan")
        centralManager?.scanForPeripherals(
            withServices: [transferServiceUUID], options: nil
        )
        
        NSLog("---BLEManager--- Scanning....")
    }
    
    /** Stop Scan*/
    func stopScan() {
        NSLog("---BLEManager--- Stopping scan")
        centralManager?.stopScan()
    }
   
    /**Connect to selected peripheral*/
    func connect(peripheral: CBPeripheral){
        NSLog("---BLEManager--- Connecting to peripheral \(peripheral)")
        centralManager?.connect(peripheral, options: nil)
    }
    
    /** Collect existing peripheral that connected now*/
    func retrieveExistingPeripheral(){
        existingPeripheralList = (centralManager?.retrieveConnectedPeripherals(withServices: [transferServiceUUID]) ?? nil)!
        NSLog("---BLEManager--- Existing peripheral list = \(existingPeripheralList)")
        if existingPeripheralList.count != 0 {
            connect(peripheral: existingPeripheralList[0])
        }
    }
    
    /** Send command to peripheral device in order to change led light*/
    func ChangeLED(){
        NSLog("---BLEManager--- Start send command to arduino with TransferServiceUUID=\(discoveredPeripheral!.identifier.uuidString), TransferCharacteristicUUID=\(String(describing: discoveredCharacteristic?.uuid))")
        
        //send command to arduino
        if ledIndex == 0 {
            let data = Data(bytes: [valueOn])
            ledIndex = 1
            NSLog("---BLEManager--- data = \(data)")
            discoveredPeripheral!.writeValue(data, for: discoveredCharacteristic!, type: .withResponse)
        }
        else{
            let data = Data(bytes: [valueOff])
            ledIndex = 0
            NSLog("---BLEManager--- data = \(data)")
            discoveredPeripheral!.writeValue(data, for: discoveredCharacteristic!, type: .withResponse)
        }
    }
    
    /** centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("\(#line) \(#function)")
        
        if central.state == .poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            NSLog("---BLEManager--- Bluetooth Already Enabled")
            
            // The state must be CBCentralManagerStatePoweredOn...
            // ... so start scanning
            startScan()
            retrieveExistingPeripheral()
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            NSLog("---BLEManager--- Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
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
        //            NSLog("Device not at correct range")
        //            return
        //        }
        
        NSLog("---BLEManager--- Discovered Peripheral Device: Name = \(String(describing: peripheral.name)), UUID = \(peripheral.identifier.uuidString), RSSI = \(RSSI)")
        
        if peripheralList.contains(peripheral) == false {
            peripheralList.append(peripheral)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadBLEList"), object: nil)
        }
        else{
            NSLog("---BLEManager--- peripheral exist: \(peripheral)")
        }
    }
    
    /** If the connection fails for whatever reason, we need to deal with it. */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        NSLog("---BLEManager---  Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEFailToConnect"), object: nil)
        cleanup()
    }
    
    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic. */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("---BLEManager--- Peripheral Connected")
        
        // Stop scanning
        centralManager?.stopScan()
        NSLog("---BLEManager--- Scanning stopped")
        
        // Clear the data that we may already have
        data.length = 0
        isConnected = true;
        discoveredPeripheral = peripheral
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([transferServiceUUID])
    }
    
    /** The Transfer Service was discovered */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        NSLog("---BLEManager---  Success discover Transfer Services")
        guard error == nil else {
            NSLog("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        NSLog("---BLEManager--- Services: \(services)")
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        if services.isEmpty {
            NSLog("---BLEManager--- Services is empty, cancel peripheral connection")
            cancelPeripheralConnection()
        }
        else {
            for service in services {
                peripheral.discoverCharacteristics([transferCharacteristicUUID], for: service)
            }
        }
    }
    
    /** The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        NSLog("---BLEManager--- Success discover Transfer Characteristic")
        
        // Deal with errors (if any)
        guard error == nil else {
            NSLog("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        // Again, we loop through the array, just in case.
        for characteristic in characteristics {
            // And check if it's the right one
            NSLog("---BLEManager--- characteristic UUID = \(characteristic.uuid), properties = \(characteristic.properties)")
            if (characteristic.uuid.isEqual(transferCharacteristicUUID)) {
                // If it is, subscribe to it
                NSLog("---BLEManager--- Characteristic is match, characteristic UUID = \(characteristic.uuid)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else{
                cancelPeripheralConnection()
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /** This callback lets us know more data has arrived via notification on the characteristic */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            NSLog("---BLEManager--- Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        NSLog("---BLEManager--- inside didUpdateValueFor, characteristic UUID = \(characteristic.uuid)")
    }
    
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        NSLog("---BLEManager--- Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid.isEqual(transferCharacteristicUUID) else {
            return
        }
        
        // Notification has started
        if (characteristic.isNotifying) {
            NSLog("---BLEManager--- Notification began on \(characteristic)")
            discoveredCharacteristic = characteristic
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEConnectSuccess"), object: nil)
        } else { // Notification has stopped
            NSLog("---BLEManager--- Notification stopped on (\(characteristic))  Disconnecting")
            centralManager?.cancelPeripheralConnection(peripheral)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEFailToConnect"), object: nil)
        }
    }
    
    /** read RSSI device to determine the range of user and device*/
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            NSLog("---BLEManager--- Error discovering RSSI number: \(error!.localizedDescription)")
            return
        }
        
        discoveredRSSI = RSSI
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GetRSSI"), object: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        NSLog("---BLEManager--- service = \(invalidatedServices)")
        cancelPeripheralConnection()
    }
    
    /** Once the disconnection happens, we need to clean up our local copy of the peripheral*/
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("---BLEManager--- Peripheral is Disconnected")
        discoveredPeripheral = nil
        isConnected = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEDisconnected"), object: nil)
        
        peripheralList.remove(at: peripheralList.firstIndex(of: peripheral)!)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadBLEList"), object: nil)
        
        // We're disconnected, so start scanning again
        startScan()
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
                if characteristic.uuid.isEqual(transferCharacteristicUUID) && characteristic.isNotifying {
                    discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                    // And we're done.
                    return
                }
            }
        }
        
        isConnected = false
    }
    
    fileprivate func cancelPeripheralConnection() {
        // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
        NSLog("---BLEManager--- Cancel peripheral connection")
        centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
    }
    
    /*func checkBluetoothConnection(){
        if isConnected == true && discoveredPeripheral?.state == CBPeripheralState.disconnected {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEDisconnected"), object: nil)
        }
    }*/
}
