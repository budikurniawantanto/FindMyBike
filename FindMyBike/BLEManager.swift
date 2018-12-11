//
//  BLEManager.swift
//  team5ui
//
//  Created by budi on 2018/11/30.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class BLEManager: NSObject, PTDBeanManagerDelegate, PTDBeanDelegate {
    
    var vc: UIViewController?
    
    var beanManager: PTDBeanManager?
    var myBean: PTDBean?
    var beanList: Array<PTDBean> = []
    
    // And somewhere to store the incoming data
    fileprivate let data = NSMutableData()
    var isConnected:Bool! = false
    var ledIndex:Int! = 0
    var ledOn:Bool = true
    var ledOff:Bool = false

    private static var mInstance:BLEManager?
    static func shared() -> BLEManager {
        if mInstance == nil {
            mInstance = BLEManager()
        }
        return mInstance!
    }
    
    /** Initialize CentralManager BLE*/
    func startBLE() {
        self.vc = UIViewController()
        
        beanManager = PTDBeanManager()
        beanManager!.delegate = self
    }
    
    // Bean SDK: We check to see if Bluetooth is on.
    func beanManagerDidUpdateState(_ beanManager: PTDBeanManager!) {
        NSLog("---BLEManager--- inside beanManagerDidUpdateState")
        var scanError: NSError?
        
        if beanManager!.state == BeanManagerState.poweredOn {
            NSLog("---BLEManager--- BeanManagerState is ON")
            startScan()
            if let e = scanError {
                NSLog("\(e)")
            }
        }
    }
    
    // Scan for Beans
    func startScan() {
        NSLog("---BLEManager--- start scanning bean")
        var error: NSError?
        beanManager!.startScanning(forBeans_error: &error)
        if let e = error {
            NSLog("start scanning error = \(e)")
        }
    }
    
    // Stop Scan for Beans
    func stopScan() {
        NSLog("---BLEManager--- stop scanning bean")
        var error: NSError?
        beanManager!.stopScanning(forBeans_error: &error)
        if let e = error {
            NSLog("stop scanning error = \(e)")
        }
    }
    
    // We connect to a specific Bean
    func beanManager(_ beanManager: PTDBeanManager!, didDiscover bean: PTDBean!, error: Error!) {
        NSLog("---BLEManager--- enter didDiscoverBean")
        if let e = error {
            NSLog("\(e)")
        }
        
        NSLog("---BLEManager--- Discover a Bean: \(String(describing: bean.name))")
        if !beanList.contains(bean) {
            beanList.append(bean)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadBLEList"), object: nil)
        }
    }
    
    // Bean SDK: connects to Bean
    func connectToBean(bean: PTDBean) {
        var error: NSError?
        NSLog("---BLEManager---  Connect to bean : \(String(describing: bean.name))")
        beanManager?.connect(to: bean, error: &error)
    }
    
    func disconnectFromBean(bean: PTDBean){
        var error: NSError?
        NSLog("---BLEManager---  Disconnect from bean : \(String(describing: bean.name))")
        beanManager?.disconnectBean(bean, error: &error)
    }
    
    func beanManager(_ beanManager: PTDBeanManager!, didConnect bean: PTDBean!, error: Error!) {
        if let e = error {
            NSLog("\(e)")
            NSLog("---BLEManager--- Fail Connected to Bean: \(String(describing: bean.name))")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEFailToConnect"), object: nil)
        }
        else{
            NSLog("---BLEManager--- Connected to Bean: \(String(describing: bean.name))")
            isConnected = true
            myBean = bean
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEConnectSuccess"), object: nil)
        }
    }
    
    func beanManager(_ beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: Error!) {
        if let e = error {
            NSLog("\(e)")
        }
        
        isConnected = false;
        myBean = nil;
        
        NSLog("---BLEManager---  Disconnected from Bean: \(String(describing: bean.name))")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEDisconnected"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadBLEList"), object: nil)
    }
    
    
    func bean(_ bean: PTDBean!, serialDataReceived data: Data!) {
        NSLog("---BLEManager--- Get string from Bean: \(data.base64EncodedString())")
    }
    
    func beanDidUpdateRSSI(_ bean: PTDBean!, error: Error!) {
        NSLog("---BLEManager--- RSSI update : \(String(describing: bean.rssi))")
    }
    
    // Bean SDK: Send serial data to the Bean
    func ChangeLED() {
        if ledIndex == 0 {
            let data = Data(bytes: &ledOn, count: MemoryLayout.size(ofValue: ledOn))
            ledIndex = 1
            NSLog("---BLEManager - Bean---  send data to Bean: \(String(describing: myBean!.name)), data total = \(data.count), turn on led)")
            myBean?.sendSerialData(data)
        }
        else{
            let data = Data(bytes: &ledOff, count: MemoryLayout.size(ofValue: ledOff))
            ledIndex = 0
            NSLog("---BLEManager - Bean---  send data to Bean: \(String(describing: myBean!.name)), data total = \(data.count), turn off led)")
            myBean?.sendSerialData(data)
        }
    }
}
