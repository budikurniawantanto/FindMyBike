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
    @IBOutlet weak var bleStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkConnection()
        print("---BLEStatusVC--- BLE status = \(String(describing: bleStatus))")
        bleStatusLabel.text = bleStatus
    }

    /** callback function when BLEStatusVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkConnection()
        print("---BLEStatusVC--- BLE status = \(String(describing: bleStatus))")
        bleStatusLabel.text = bleStatus
    }
    
    /** function to check current connected device */
    func checkConnection(){
        // Do any additional setup after loading the view.
        if BLEManager.shared().isConnected == false {
            bleStatus = "Disconnected"
        }
        else{
            bleStatus = "Connected to "
            print("---BLEStatusVC--- connected peripheral = \(BLEManager.shared().discoveredPeripheral!)")
            bleStatus.append((BLEManager.shared().discoveredPeripheral?.name)!)
        }
    }
}
