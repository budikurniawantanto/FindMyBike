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
    @IBOutlet var disconnectBtn: UIButton!
    
    var defaultColor: UIColor?
    var vc: UIViewController?
    var discoverBLEList: Array<PTDBean> = []
    var existingBLEList: Array<PTDBean> = []
    var selectedCell: UITableViewCell?
    var lastdiscoverIndex:Int?
    var indicatorBtn:UIActivityIndicatorView?
    
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
        
        indicatorBtn = UIActivityIndicatorView(style: .whiteLarge)
        indicatorBtn?.frame = CGRect(x: 0.0, y: 0.0, width: 70.0, height: 70.0)
        indicatorBtn?.backgroundColor = UIColor.black
        indicatorBtn?.layer.cornerRadius = 35.0
        indicatorBtn?.layer.masksToBounds = true
        indicatorBtn?.center = self.view.center
        self.view.addSubview(indicatorBtn!)
        indicatorBtn?.bringSubviewToFront(self.view)
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
        discoverBLEList = BLEManager.shared().discoverBeanList
        existingBLEList = BLEManager.shared().existingBeanList
        lastdiscoverIndex = -1
        bleList.reloadData()
        
        //start scan
        BLEManager.shared().startScan()
        defaultColor = connectBtn.backgroundColor
        checkConnection()
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
        indicatorBtn?.startAnimating()
        if selectedCell != nil {
            for bean in discoverBLEList {
                if (BLEManager.shared().isConnected == true && BLEManager.shared().myBean != bean) || bean.name == selectedCell?.textLabel!.text {
                    NSLog("---BLEListVC--- found selected bean = \(bean)")
                    BLEManager.shared().connectToBean(bean: bean)
                }
            }
        }
        else {
            if BLEManager.shared().isConnected{
                let alertVC = UIAlertController(
                    title: "Bluetooth Connection",
                    message: "You already connect to bluetooth " + (BLEManager.shared().myBean?.name)!,
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
            indicatorBtn?.stopAnimating()
        }
    }
    
    @IBAction func press_disconnectBtn(_ sender: Any) {
        indicatorBtn?.startAnimating()
        BLEManager.shared().disconnectFromBean(bean: BLEManager.shared().myBean!)
    }
    
    /** function to check current connected device */
    func checkConnection(){
        // Do any additional setup after loading the view.
        if !BLEManager.shared().isConnected {
            disconnectBtn.isEnabled = false
            disconnectBtn.backgroundColor = UIColor.lightGray
        }
        else{
            disconnectBtn.isEnabled = true
            disconnectBtn.backgroundColor = defaultColor
        }
    }
    
    /** Get total available BLE device list */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let total = discoverBLEList.count + existingBLEList.count
        NSLog("---BLEListVC--- total list = \(total)")
        return total
    }
    
    /** update BLE device list on tableView */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = bleList.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        if indexPath.row < existingBLEList.count {
            let bean = existingBLEList[indexPath.row]
            NSLog("---BLEListVC--- existing bean = \(bean), index row = \(indexPath.row)")
            cell.textLabel?.text = bean.name
            
            if bean != BLEManager.shared().myBean {
                //if had already connected, but this BLE not in discoverBLEList, then this BLE is not available
                if !discoverBLEList.contains(bean) {
                    cell.detailTextLabel?.text = "Unavailable"
                    cell.selectionStyle = UITableViewCell.SelectionStyle.none;
                }
                else{
                    cell.detailTextLabel?.text = "Available"
                    cell.selectionStyle = UITableViewCell.SelectionStyle.default
                }
            }
            else{
                cell.detailTextLabel?.text = "Connected"
                cell.selectionStyle = UITableViewCell.SelectionStyle.none;
            }
        }
        else{
            let start = existingBLEList.count
            var index:Int! = indexPath.row - start
            if lastdiscoverIndex != -1 {
                index = lastdiscoverIndex! + 1
            }
            var bean:PTDBean! = discoverBLEList[index]
            var found:Bool! = false
            
            //find first bean that not exist in existingBLEList to avoid the same ble show in list
            while true {
                if existingBLEList.contains(bean) {
                    index = index + 1
                    if index == discoverBLEList.count {
                        break
                    }
                    else {
                        bean = discoverBLEList[index]
                    }
                }
                else{
                    found = true
                    lastdiscoverIndex = index
                    break
                }
            }
            
            if found {
                NSLog("---BLEListVC--- discover bean = \(String(describing: bean)), index row = \(indexPath.row)")
                cell.textLabel?.text = bean.name
                if bean != BLEManager.shared().myBean {
                    cell.detailTextLabel?.text = "Available"
                    cell.selectionStyle = UITableViewCell.SelectionStyle.default
                }
                else{
                    cell.detailTextLabel?.text = "Connected"
                    cell.selectionStyle = UITableViewCell.SelectionStyle.none;
                }
            }
            else{
                cell.textLabel?.text = nil
                cell.detailTextLabel?.text = nil
                cell.selectionStyle = UITableViewCell.SelectionStyle.none;
            }
        }
        
        return cell
    }
    
    /** called when user click on specific row on tableView */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if bleList.cellForRow(at: indexPath)?.detailTextLabel!.text == "Available" {
            selectedCell = (bleList.cellForRow(at: indexPath) as! UITableViewCell)
            NSLog("---BLEListVC--- selected cell = \(String(describing: selectedCell!.textLabel!.text)), background color = \(String(describing: selectedCell?.backgroundColor))")
        }
        else{
            selectedCell = nil
        }
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
            selector: #selector(UpdateBikeLocation),
            name: NSNotification.Name(rawValue: "UpdateBikeLocation"),
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
        discoverBLEList = BLEManager.shared().discoverBeanList
        existingBLEList = BLEManager.shared().existingBeanList
        lastdiscoverIndex = -1
        bleList.reloadData()
    }
    
    /** callback function when BLEManager success connect to selected devices */
    @objc func ConnectionSuccess(){
        NSLog("---BLEListVC--- connection success")
        indicatorBtn?.stopAnimating()
        let alertVC = UIAlertController(
            title: "Connection Result",
            message: "Connected!!!",
            preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: { (action: UIAlertAction) -> Void in
                self.navigationController?.popViewController(animated: true)
                //let mapVC = self.storyboard?.instantiateViewController(withIdentifier: "MapVC")
                //self.present(mapVC!, animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
        
        //load data to list
//        discoverBLEList = BLEManager.shared().discoverBeanList
//        existingBLEList = BLEManager.shared().existingBeanList
//        lastdiscoverIndex = -1
//        bleList.reloadData()
//        checkConnection()
//        selectedCell = nil
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
        NSLog("---BLEListVC--- BLE disconnect")
        indicatorBtn?.stopAnimating()
        //load data to list
        discoverBLEList = BLEManager.shared().discoverBeanList
        existingBLEList = BLEManager.shared().existingBeanList
        lastdiscoverIndex = -1
        bleList.reloadData()
        
        disconnectBtn.isEnabled = false
        disconnectBtn.backgroundColor = UIColor.lightGray
        
        selectedCell = nil
    }
    
    @objc func UpdateBikeLocation(){
        NSLog("---BLEListVC--- update bike location")
        DataMgr.setBikelocation((userlocation?.coordinate.latitude)!, (userlocation?.coordinate.longitude)!)
        //needUpdateBikeLocation = true
    }
    
    @objc func AppGoToForeground(){
        NSLog("---BLEListVC--- App go to foreground")
        
        //load data to list
        discoverBLEList = BLEManager.shared().discoverBeanList
        existingBLEList = BLEManager.shared().existingBeanList
        lastdiscoverIndex = -1
        bleList.reloadData()
        
        //start scan
        BLEManager.shared().startScan()
    }
    
    @objc func AppGoToBackground(){
        NSLog("---BLEListVC--- App go to background")
        BLEManager.shared().stopScan()
    }
}
