//
//  MapVC.swift
//  team5ui
//
//  Created by budi on 2018/11/30.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import MapKit
import CoreBluetooth
import CoreLocation

var userlocation :CLLocation?
var bikelocation :CLLocation?

class MapVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var ledBtn: UIButton!
    @IBOutlet weak var arBtn: UIButton!
    
    var peripheral: CBPeripheral?
    var RSSI: NSNumber?
    var myLocationManager = CLLocationManager()
    var bikeAnnotation = MKPointAnnotation()
    var initial = false
    var updated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addNotificationObserver()
        initializeBLE()
        myLocationManager.delegate = self
        
        // 距離篩選器 用來設置移動多遠距離才觸發委任方法更新位置
        myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        
        // 取得自身定位位置的精確度
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        myMapView.delegate = self
        myMapView.showsUserLocation = true
        myMapView.userTrackingMode = .followWithHeading
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //NSLog("---MapVC--- viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    /** callback function when MapVC is re-appear */
    override func viewDidAppear(_ animated: Bool) {
        NSLog("---MapVC--- viewDidAppear")
        super.viewDidAppear(animated)
        
        addNotificationObserver()
        
        //setup BLE connection
        if BLEManager.shared().isConnected == false {
            ledBtn.backgroundColor = UIColor.white
            BLEManager.shared().startScan()
        }
        else{
            GetRSSI()
        }
        
        checkGPSPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //NSLog("---MapVC--- viewWillDisappear")
        super.viewWillDisappear(animated)
        BLEManager.shared().stopScan()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //NSLog("---MapVC--- viewDidDisappear")
        super.viewDidDisappear(animated)
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
                let alertVC = UIAlertController(title: "Connection Status", message: "Out Of Range", preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                    self.dismiss(animated: true, completion: nil)
                })
                alertVC.addAction(action)
                self.present(alertVC, animated: true, completion: nil)
            }
            else{
                let alertVC = UIAlertController(title: "Connection Status", message: "Disconnected", preferredStyle: UIAlertController.Style.alert)
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 印出目前所在位置座標
        userlocation = locations.last
        NSLog("---MapVC--- didUpdateLocations called, userLocation = (\(userlocation!.coordinate.latitude), \(userlocation!.coordinate.longitude))")
        
        if !initial {
            getBikelocation()
            
            let latDelta = abs(userlocation!.coordinate.latitude - bikelocation!.coordinate.latitude) + 0.01
            let longDelta = abs(userlocation!.coordinate.longitude - bikelocation!.coordinate.longitude) + 0.01
            
            let latcen = (userlocation!.coordinate.latitude + bikelocation!.coordinate.latitude)/2
            let longcen = (userlocation!.coordinate.longitude + bikelocation!.coordinate.longitude)/2
            
            let currentLocationSpan:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            
            let center:CLLocation = CLLocation(latitude: latcen, longitude: longcen)
            let currentRegion:MKCoordinateRegion = MKCoordinateRegion(center: center.coordinate,span: currentLocationSpan)
            
            bikeAnnotation.coordinate = CLLocation(latitude: bikelocation!.coordinate.latitude, longitude: bikelocation!.coordinate.longitude).coordinate
            bikeAnnotation.title = "Bike location"
            bikeAnnotation.subtitle = "updated time: "
            
            myMapView.setRegion(currentRegion, animated: true)
            myMapView.addAnnotation(bikeAnnotation)
            
            initial = true
        }
        else{
            routing()
        }
    }
    
    func getBikelocation(){
        let lastbikelocation = UserDefaults.standard.dictionary(forKey: "lastbikelocation")
        if(lastbikelocation != nil){
            NSLog("---MapVC--- loading last bike location")
            let locationinfo = UserDefaults.standard.dictionary(forKey: "lastbikelocation")
            bikelocation = CLLocation(latitude: locationinfo!["latitude"] as! Double, longitude: locationinfo!["longtitude"] as! Double)
            
            //testing
            setBikelocation(userlocation!.coordinate.latitude + 0.001, userlocation!.coordinate.longitude + 0.0006)
        }
            
        else{
            //first use
            NSLog("---MapVC--- first use bike location")
            let bikelat = userlocation!.coordinate.latitude + 0.001
            let bikelong = userlocation!.coordinate.longitude + 0.001
            bikelocation = CLLocation(latitude: bikelat, longitude: bikelong)
            setBikelocation(bikelat,bikelong)
        }
    }
    
    func setBikelocation(_ latitude: Double, _ longtitude: Double){
        let newlocation = ["latitude" : latitude, "longtitude" : longtitude]
        UserDefaults.standard.set(newlocation, forKey: "lastbikelocation")
    }
    
    func routing(){
        NSLog("---MapVC--- routing start")
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: userlocation!.coordinate, addressDictionary: nil))
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: bikelocation!.coordinate, addressDictionary: nil))
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            NSLog("---MapVC--- route distance = \(route.distance)")
            self.myMapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    /** GPS Permission */
    func checkGPSPermission(){
        //setup location permission
        if CLLocationManager.authorizationStatus() == .notDetermined { // 首次使用 向使用者詢問定位自身位置權限
            NSLog("---MapVC--- authorization = notDetermined")
            // 取得定位服務授權
            NSLog("---MapVC--- requestWhenInUseAuthorization")
            myLocationManager.requestWhenInUseAuthorization()
            
            // 開始定位自身位置
            NSLog("---MapVC--- startUpdatingLocation")
            myLocationManager.startUpdatingLocation()
        }
        else if CLLocationManager.authorizationStatus() == .denied { // 使用者已經拒絕定位自身位置權限
            // 提示可至[設定]中開啟權限
            NSLog("---MapVC--- authorization = notDetermined")
            let alertController = UIAlertController(
                title: "GPS Location Permission",
                message: "Please open GPS permission in order to use GPS service",
                preferredStyle: .alert)
            
            let okAction = UIAlertAction(
                title: "Go to Settings",
                style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            NSLog("Settings opened: \(success)") // Prints true
                        })
                    }
            }
            let cancelAction = UIAlertAction(
                title: "Cancel",
                style: .default,
                handler: nil)
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true, completion: nil)
        }
        else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse  || CLLocationManager.authorizationStatus() == .authorizedAlways
        { // 使用者已經同意定位自身位置權限
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
                NSLog("---MapVC--- authorization = authorizedWhenInUse")
            }
            else{
                NSLog("---MapVC--- authorization = authorizedAlways")
            }
            // 開始定位自身位置
            myLocationManager.startUpdatingLocation()
        }
    }
    
    /** initialize BLEManager */
    func initializeBLE(){
        NSLog("---MapVC--- initialize BLE : start BLE")
        BLEManager.shared().startBLE()
    }
    
    /** add notification observer */
    func addNotificationObserver(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(BLEdisconnected),
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
    
    /** Notification Handler */
    @objc func GetRSSI(){
        RSSI = BLEManager.shared().myBean?.rssi
        NSLog("---MapVC--- getRSSI = \(RSSI!), int value = \(RSSI!.intValue)")
        
        if  RSSI!.intValue > -15 || RSSI!.intValue < -60 {
            NSLog("---MapVC--- Device is not at correct range, RSSI = \(RSSI!)")
            ledBtn.backgroundColor = UIColor.white
        }
        else{
            NSLog("---MapVC--- Device is at correct range, RSSI = \(RSSI!)")
            ledBtn.backgroundColor = UIColor.yellow
        }
    }
    
    @objc func AppGoToForeground(){
        NSLog("---MapVC--- App go to foreground")
        checkGPSPermission()
        BLEManager.shared().startScan()
        addNotificationObserver()
    }
    
    @objc func AppGoToBackground(){
        NSLog("---MapVC--- App go to background")
        BLEManager.shared().stopScan()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func BLEdisconnected(){
        NSLog("---MapVC--- BLE disconnected")
        let alertVC = UIAlertController(
            title: "Connection Status",
            message: "Device Disconnected. Please check your device state or try to move closer",
            preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
        ledBtn.backgroundColor = UIColor.white
    }
    
    @objc func BLEFailToConnect(){
        NSLog("---BLEListVC--- BLE connection failed")
        let alertVC = UIAlertController(
            title: "Connection Result",
            message: "Failed. Please try to connect other device",
            preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
        ledBtn.backgroundColor = UIColor.white
    }
}
