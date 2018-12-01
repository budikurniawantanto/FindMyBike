//
//  BTLECentralVC.swift
//  Bluetooth
//
//  Created by Mick on 12/20/14.
//  Copyright (c) 2014 MacCDevTeam LLC. All rights reserved.
//

import UIKit
import CoreBluetooth

class BTLECentralVC: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet fileprivate weak var textView: UITextView!
    
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    var targetService: CBService?
    var writableCharacteristic: CBCharacteristic?
    
    
    // And somewhere to store the incoming data
    fileprivate let data = NSMutableData()
    var index:Int! = 0
    var UUID_Array = [String]()
    var valueOn:UInt8 = 1
    var valueOff:UInt8 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start up the CBCentralManager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("Stopping scan")
        centralManager?.stopScan()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            print("Bluetooth Enabled")
            
            // The state must be CBCentralManagerStatePoweredOn...
            // ... so start scanning
            scan()
            
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    /** Scan for peripherals - specifically for our service's 128bit CBUUID
    */
    func scan() {
        //let transferUUID = CBUUID(string: "ec00")
        centralManager?.scanForPeripherals(
            withServices: [transferServiceUUID], options: nil
        )
        
        print("Scanning started")
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

        //print("\n----------- Discovered Peripheral Device -----------")
        //print("Name = \(String(describing: peripheral.name))")
        print("UUID = \(peripheral.identifier.uuidString), RSSI = \(RSSI)")
        //print("RSSI = \(RSSI)")

        // Ok, it's in range - have we already seen it?
        if peripheral.identifier.uuidString == "609E5D1A-7FEC-6CE3-85C1-06D0E9A51AB1" {
        //if peripheral.identifier.uuidString == "B4C5E6CD-A755-5557-8D9E-4D9B5C5AF979" {
        //if discoveredPeripheral != peripheral {
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripheral = peripheral
            print("it's match, UUID = \(peripheral.identifier.uuidString)");
            
            // And connect
            print("Connecting to peripheral \(peripheral)")
            
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    /** If the connection fails for whatever reason, we need to deal with it.
    */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        
        cleanup()
    }

    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
    */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        centralManager?.stopScan()
        print("Scanning stopped")
        
        // Clear the data that we may already have
        data.length = 0
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([transferServiceUUID])
    }
    
    /** The Transfer Service was discovered
    */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Success discover Transfer Services")
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }

        guard let services = peripheral.services else {
            return
        }

        print("Services:")
        print("\(services)")
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        for service in services {
            peripheral.discoverCharacteristics([transferCharacteristicUUID], for: service)
        }
    }
    
    /** The Transfer characteristic was discovered.
    *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
    */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Success discover Transfer Characteristic")
        
        // Deal with errors (if any)
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            cleanup()
            return
        }


        guard let characteristics = service.characteristics else {
            return
        }

        // Again, we loop through the array, just in case.
        for characteristic in characteristics {
            // And check if it's the right one
            print("characteristic UUID = \(characteristic.uuid), properties = \(characteristic.properties)")
            if (characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)) && characteristic.uuid.isEqual(transferCharacteristicUUID) {
                // If it is, subscribe to it
                print("Characteristic is match, characteristic UUID = \(characteristic.uuid)")
                if(characteristic.properties.contains(.write)) {print("it has write")}
                if(characteristic.properties.contains(.writeWithoutResponse)) {print("it has writeWithoutResponse")}
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /** This callback lets us know more data has arrived via notification on the characteristic
    */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        print("inside didUpdateValueFor, characteristic UUID = \(characteristic.uuid)")
    }

    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
    */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid.isEqual(transferCharacteristicUUID) else {
            return
        }
        
        // Notification has started
        if (characteristic.isNotifying) {
            print("Notification began on \(characteristic)")
            print("Start send command to arduino with TransferServiceUUID=\(peripheral.identifier.uuidString) and TransferCharacteristicUUID=\(characteristic.uuid)")
            
            //send command to arduino
            let data = Data(bytes: [valueOn])
            print("data = \(data)")
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } else { // Notification has stopped
            print("Notification stopped on (\(characteristic))  Disconnecting")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    /** Once the disconnection happens, we need to clean up our local copy of the peripheral
    */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral Disconnected")
        discoveredPeripheral = nil
        
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
                if characteristic.uuid.isEqual(transferCharacteristicUUID) && characteristic.isNotifying {
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
