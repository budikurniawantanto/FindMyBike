//
//  BLEListVC.swift
//  team5ui
//
//  Created by budi on 2018/12/2.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import CoreBluetooth
import Bean_iOS_OSX_SDK

class BLEListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var bleStatusText: UIView!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var bleList: UITableView!
    
    var vc: UIViewController?
    var BLEList: Array<PTDBean> = []
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //NSLog("---BLEListVC--- viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    /** callback function when MapVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        NSLog("---BLEListVC--- viewDidAppear")
        super.viewDidAppear(animated)
        
        addNotificationObserver()
        
        //load data to list
        BLEList = BLEManager.shared().beanList
        bleList.reloadData()
        
        //start scan
        BLEManager.shared().startScan()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //NSLog("---BLEListVC--- viewWillDisappear")
        super.viewWillDisappear(animated)
        BLEManager.shared().stopScan()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //NSLog("---BLEListVC--- viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    /** connect to selected peripheral when user press Connect button*/
    @IBAction func press_connectBtn(_ sender: Any) {
        if selectedCell != nil {
            for bean in BLEList {
                if (BLEManager.shared().isConnected == true && BLEManager.shared().myBean != bean) || bean.name == selectedCell?.textLabel!.text {
                    NSLog("---BLEListVC--- found selected bean = \(bean)")
                    BLEManager.shared().connectToBean(bean: bean)
                }
            }
        }
        else{
            let alertVC = UIAlertController(
                title: "No Bluetooth Device Selected",
                message: "Please select bluetooth device that you want to connect!!!",
                preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(
                title: "OK",
                style: UIAlertAction.Style.default,
                handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    /** Get total available BLE device list */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("---BLEListVC--- total list = \(BLEList.count)")
        return BLEList.count
    }
    
    /** update BLE device list on tableView */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = bleList.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let bean = BLEList[indexPath.row]
        NSLog("---BLEListVC--- bean = \(bean)")
        if bean != BLEManager.shared().myBean {
            cell.textLabel?.text = bean.name
        }
        else{
            cell.textLabel?.text = nil
        }
        
        return cell
    }
    
    /** called when user click on specific row on tableView */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCell = (bleList.cellForRow(at: indexPath) as! UITableViewCell)
        NSLog("---BLEListVC--- selected cell = \(String(describing: selectedCell!.textLabel!.text))")
    }
    
    /** add notification observer */
    func addNotificationObserver(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadBLEList),
            name: NSNotification.Name(rawValue: "LoadBLEList"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ConnectionSuccess),
            name: NSNotification.Name(rawValue: "BLEConnectSuccess"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ConnectionFailed),
            name: NSNotification.Name(rawValue: "BLEFailToConnect"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(BLEDisconnected),
            name: NSNotification.Name(rawValue: "BLEDisconnected"),
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
    
    /** callback function when BLEManager success get new bluetooth devices */
    @objc func loadBLEList(){
        NSLog("---BLEListVC--- reload BLE list")
        BLEList = BLEManager.shared().beanList
        bleList.reloadData()
    }
    
    /** callback function when BLEManager success connect to selected devices */
    @objc func ConnectionSuccess(){
        NSLog("---BLEListVC--- connection success")
        let alertVC = UIAlertController(
            title: "Connection Result",
            message: "Connected!!!",
            preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
        
        //load data to list
        BLEList = BLEManager.shared().beanList
        bleList.reloadData()
    }
    
    /** callback function when BLEManager failed connect to selected devices */
    @objc func ConnectionFailed(){
        NSLog("---BLEListVC--- BLE connection failed")
        let alertVC = UIAlertController(
            title: "Connection Result",
            message: "Failed!!! Please try again or select another device",
            preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @objc func BLEDisconnected(){
        NSLog("---BLEStatusVC--- BLE disconnect")
        //load data to list
        BLEList = BLEManager.shared().beanList
        bleList.reloadData()
    }
    
    @objc func AppGoToForeground(){
        NSLog("---MapVC--- App go to foreground")
        
        //load data to list
        BLEList = BLEManager.shared().beanList
        bleList.reloadData()
        
        //start scan
        BLEManager.shared().startScan()
    }
    
    @objc func AppGoToBackground(){
        NSLog("---MapVC--- App go to background")
        BLEManager.shared().stopScan()
    }
}
