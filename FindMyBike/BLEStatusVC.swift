//
//  BLEStatusVC.swift
//  team5ui
//
//  Created by budi on 2018/12/1.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit

class BLEStatusVC: UIViewController {

    var bleStatus: String! = ""
    var defaultColor: UIColor?
    @IBOutlet weak var bleStatusLabel: UILabel!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var changeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        //NSLog("---BLEStatusVC--- viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    /** callback function when BLEStatusVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        defaultColor = changeBtn.backgroundColor
        addNotificationObserver()
        checkConnection()
        //BLEManager.shared().checkBluetoothConnection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //NSLog("---BLEStatusVC--- viewWillDisappear")
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //NSLog("---BLEStatusVC--- viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    /** function to check current connected device */
    func checkConnection(){
        // Do any additional setup after loading the view.
        if BLEManager.shared().isConnected == false {
            bleStatus = "Disconnected"
            disconnectBtn.isEnabled = false
            disconnectBtn.backgroundColor = UIColor.lightGray
        }
        else{
            bleStatus = "Connected to "
            NSLog("---BLEStatusVC--- connected bean = \(BLEManager.shared().myBean!)")
            bleStatus.append((BLEManager.shared().myBean?.name)!)
            disconnectBtn.isEnabled = true
            disconnectBtn.backgroundColor = defaultColor
        }
        NSLog("---BLEStatusVC--- BLE status = \(String(describing: bleStatus))")
        bleStatusLabel.text = bleStatus
    }
    
    @IBAction func press_disconnectBtn(_ sender: Any) {
        BLEManager.shared().disconnectFromBean(bean: BLEManager.shared().myBean!)
    }
    
    /** add notification observer */
    func addNotificationObserver(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(BLEDisconnected),
            name: NSNotification.Name(rawValue: "BLEDisconnected"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(BLEFailToConnect),
            name: NSNotification.Name(rawValue: "BLEFailToConnect"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppGoToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppGoToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }
    
    @objc func AppGoToForeground(){
        NSLog("---MapVC--- App go to foreground")
        checkConnection()
    }
    
    @objc func AppGoToBackground(){
        NSLog("---MapVC--- App go to background")
    }
    
    @objc func BLEDisconnected(){
        NSLog("---BLEStatusVC--- BLE disconnect")
        bleStatus = "Disconnected"
        bleStatusLabel.text = bleStatus
        disconnectBtn.isEnabled = false
        disconnectBtn.backgroundColor = UIColor.lightGray
    }
    
    @objc func BLEFailToConnect(){
        NSLog("---BLEStatusVC--- BLE fail to connect")
        bleStatus = "Disconnected"
        bleStatusLabel.text = bleStatus
        disconnectBtn.isEnabled = false
        disconnectBtn.backgroundColor = UIColor.lightGray
    }
}
