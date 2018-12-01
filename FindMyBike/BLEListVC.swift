//
//  BLEListVC.swift
//  team5ui
//
//  Created by budi on 2018/12/2.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var bleStatusText: UIView!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var bleList: UITableView!
    
    var vc: UIViewController?
    var BLEList: Array<CBPeripheral> = []
    var selectedCell: UITableViewCell?
    
    /** called when first time create BLEListVC layout
     * Set callback for:
     * 1. reload BLE device list -> loadList
     * 2. notification when success connect to BLE device -> ConnectionSuccess
     * 3. notification when failed connect to BLE device -> ConnectionFailed
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        bleList.delegate = self
        bleList.dataSource = self
        selectedCell = nil
        
        BLEManager.shared().scan()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionSuccess), name: NSNotification.Name(rawValue: "success"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionFailed), name: NSNotification.Name(rawValue: "failed"), object: nil)
    }
    
    /** callback function when MapVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BLEManager.shared().scan()
    }
    
    /** callback function when BLEManager success get new bluetooth devices */
    @objc func loadList(){
        print("---BLEListVC--- reload BLE list")
        BLEList = BLEManager.shared().peripheralList
        bleList.reloadData()
    }
    
    /** callback function when BLEManager success connect to selected devices */
    @objc func ConnectionSuccess(){
        print("---BLEListVC--- connection success")
        let alertVC = UIAlertController(title: "Connection Result", message: "Connected!!!", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    /** callback function when BLEManager failed connect to selected devices */
    @objc func ConnectionFailed(){
        print("---BLEListVC--- reload BLE list")
        let alertVC = UIAlertController(title: "Connection Result", message: "Failed!!! Please try again or select another device", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    /** connect to selected peripheral when user press Connect button*/
    @IBAction func press_connectBtn(_ sender: Any) {
        if selectedCell != nil {
            for peripheral in BLEList {
                if (BLEManager.shared().isConnected == true && BLEManager.shared().discoveredPeripheral != peripheral) || peripheral.name == selectedCell?.textLabel!.text {
                    print("---BLEListVC--- found selected peripheral = \(peripheral)")
                    BLEManager.shared().connect(peripheral: peripheral)
                }
            }
        }
        else{
            let alertVC = UIAlertController(title: "No Bluetooth Device Selected", message: "Please select bluetooth device that you want to connect!!!", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    /** Get total available BLE device list */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("---BLEListVC--- total list = \(BLEList.count)")
        return BLEList.count
    }
    
    /** update BLE device list on tableView */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = bleList.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let peripheral = BLEList[indexPath.row]
        print("---BLEListVC--- peripheral = \(peripheral)")
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
    
    /** called when user click on specific row on tableView */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCell = bleList.cellForRow(at: indexPath) as! UITableViewCell
        print("---BLEListVC--- selected cell = \(String(describing: selectedCell!.textLabel!.text))")
    }
}
