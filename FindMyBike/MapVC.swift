//
//  MapVC.swift
//  team5ui
//
//  Created by budi on 2018/11/30.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import CoreBluetooth

class MapVC: UIViewController {

    @IBOutlet weak var ledBtn: UIButton!
    @IBOutlet weak var arBtn: UIButton!
    var peripheral: CBPeripheral?
    var RSSI: NSNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeBLE()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GetRSSI), name: NSNotification.Name(rawValue: "rssi"), object: nil)
    }
    
    /** callback function when MapVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if BLEManager.shared().isConnected == false {
            BLEManager.shared().scan()
        }
        else{
            BLEManager.shared().discoveredPeripheral?.readRSSI()
        }
    }
    
    /** initialize BLEManager */
    func initializeBLE(){
        print("---BLEStatusVC--- initialize BLE : start BLE")
        BLEManager.shared().startBLE()
    }
    
    /** callback function when BLEManager success get RSSI of connected device */
    @objc func GetRSSI(){
        RSSI = BLEManager.shared().discoveredRSSI!
        print("---MapVC--- getRSSI = \(RSSI!)")
        
        if  RSSI!.intValue < -15 && RSSI!.intValue > -35 {
            print("---MapVC--- Device not at correct range, RSSI = \(RSSI!)")
            ledBtn.backgroundColor = UIColor.white
        }
        else{
            print("---MapVC--- Device is at correct range, RSSI = \(RSSI!)")
            ledBtn.backgroundColor = UIColor.yellow
        }
    }
    
    /** Define action when user press LED button
     * White = bluetooth device is out of range
     * Yellow = bluetooth device is on range
     */
    @IBAction func press_ledBtn(_ sender: Any) {
        if ledBtn.backgroundColor == UIColor.yellow {
            BLEManager.shared().ChangeLED()
            
            if BLEManager.shared().ledIndex == 1 {
                let alertVC = UIAlertController(title: "LED Status", message: "ON", preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
                alertVC.addAction(action)
                self.present(alertVC, animated: true, completion: nil)
            }
            else{
                let alertVC = UIAlertController(title: "LED Status", message: "OFF", preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
                alertVC.addAction(action)
                self.present(alertVC, animated: true, completion: nil)
            }
        }
        else{
            if BLEManager.shared().isConnected == true {
                let alertVC = UIAlertController(title: "Device Status", message: "Out Of Range", preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
                alertVC.addAction(action)
                self.present(alertVC, animated: true, completion: nil)
            }
            else{
                let alertVC = UIAlertController(title: "Device Status", message: "Disconnected", preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
                alertVC.addAction(action)
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    /** Define action when user press AR button */
    @IBAction func press_arBtn(_ sender: Any) {
    }
}
