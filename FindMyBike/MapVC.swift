//
//  MapVC.swift
//  team5ui
//
//  Created by budi on 2018/11/30.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreBluetooth
import CoreLocation

var userlocation :CLLocation?
var bikelocation :CLLocation?
var DataMgr = DataManager()

class MapVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ARSCNViewDelegate, ARSessionDelegate{
    /** MAP VARIABLE **/
    @IBOutlet var myMapView: MKMapView!
    @IBOutlet var myMapView_H: NSLayoutConstraint!
    
    var headingImageView: UIImageView?
    @IBOutlet var ledBtn: UIButton!
    
    var peripheral: CBPeripheral?
    var RSSI: NSNumber?
    var myLocationManager = CLLocationManager()
    var bikeAnnotation = MKPointAnnotation()
    var initial = false
    var updated = false
    
    /** AR VARIABLE **/
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var sceneView_H: NSLayoutConstraint!
    
    var steps: [MKRoute.Step] = []
    var anchors: [ARAnchor] = []
    var startingLocation: CLLocation!
    var nodes: [BaseNode] = []
    var destinationLocation: CLLocationCoordinate2D!
    
    var modelNode:SCNNode!
    let rootNodeName = "Car"
    var originalTransform:SCNMatrix4!
    var distance : Float! = 0.0{
        didSet {
            setStatusText()
        }
    }
    var status: String!
    var configuration: ARWorldTrackingConfiguration!
    
    @IBOutlet var arBtn: UIButton!
    @IBOutlet var mapBtn: UIButton!
    @IBOutlet var normalBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeBLE()
        
        /*** MAP FUNCTION ***/
        myMapView.delegate = self
        myMapView.showsUserLocation = true
        myMapView.userTrackingMode = .followWithHeading
        
        myLocationManager.delegate = self
        // 距離篩選器 用來設置移動多遠距離才觸發委任方法更新位置
        myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        // 取得自身定位位置的精確度
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        /*** AR FUNCTION ***/
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        print("UIScreen.main.bounds.size.height = \(UIScreen.main.bounds.size.height)")
        screenH = UIScreen.main.bounds.size.height - 44
        if isFetch {
            screenH = screenH - 44 - 43
        }
        print("UIScreen.main.bounds.size.height = \(String(describing: screenH))")
        myMapView_H.constant = screenH/2
        sceneView_H.constant = screenH/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //NSLog("---MapVC--- viewWillAppear")
        super.viewWillAppear(animated)
        
        // Create a session configuration
        if configuration == nil{
            configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            
            // Run the view's session
            sceneView.session.run(configuration)
        }
        else{
            sceneView.session.run(configuration)
        }
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
        
        // Pause the view's session
        sceneView.session.pause()
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
    
    @IBAction func press_arBtn(_ sender: Any) {
        changeLayout(h1: screenH, h2: 0)
    }
    
    @IBAction func press_mapBtn(_ sender: Any) {
        changeLayout(h1: 0, h2: screenH)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func press_normalBtn(_ sender: Any) {
        changeLayout(h1: screenH/2, h2: screenH/2)
        
        sceneView.session.run(configuration)
    }
    
    func changeLayout(h1:CGFloat, h2:CGFloat) {
        sceneView_H.constant = h1
        myMapView_H.constant = h2
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }) { (result) in
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 印出目前所在位置座標
        userlocation = locations.last
        //NSLog("---MapVC--- didUpdateLocations called, userLocation = (\(userlocation!.coordinate.latitude), \(userlocation!.coordinate.longitude))")
        
        if !initial {
            bikelocation = DataMgr.getBikelocation()

            bikeAnnotation.coordinate = CLLocation(latitude: bikelocation!.coordinate.latitude, longitude: bikelocation!.coordinate.longitude).coordinate
            bikeAnnotation.title = "Bike location"
            bikeAnnotation.subtitle = "updated time: "
            myMapView.addAnnotation(bikeAnnotation)
            setMapCamera()
            initial = true
        }
        
        //routing()
        //setMapCamera()
        
        /*** AR FUNCTION ***/
        updateLocation(Float(bikelocation!.coordinate.latitude),Float(bikelocation!.coordinate.longitude))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        
        //NSLog("---MapVC--- inside didUpdateHeading, frame = \(String(describing: headingImageView?.frame))")
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading: newHeading.magneticHeading
        headingImageView?.isHidden = false
        let rotation = CGFloat(Double.pi * (heading/180))
        headingImageView?.transform = CGAffineTransform(rotationAngle: rotation)
        
        //myMapView.camera.heading = heading
        //myMapView.setCamera(myMapView.camera, animated: true)
    }
    
    func setMapCamera(){
        let latcen = (userlocation!.coordinate.latitude + bikelocation!.coordinate.latitude)/2
        let longcen = (userlocation!.coordinate.longitude + bikelocation!.coordinate.longitude)/2
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: latcen, longitude: longcen)
        let distance = Double((userlocation?.distance(from: bikelocation!))!)
        let altitude = distance / tan(Double.pi * (15/180.0));
        
        myMapView.camera.centerCoordinate = centerCoordinate
        myMapView.camera.altitude = altitude
        myMapView.setCamera(myMapView.camera, animated: true)
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
//        let renderer = MKPolylineRenderer(overlay: overlay)
//        renderer.strokeColor = UIColor.red
//        renderer.lineWidth = 4.0
//
//        return renderer
        
        let render = MKOverlayRenderer()
        // 折线
        if overlay.isKind(of: MKPolyline.self) {
            let polylineRender = MKPolylineRenderer(overlay: overlay)// 折线
            polylineRender.lineWidth = 2 // 线宽
            polylineRender.strokeColor = UIColor.red // 颜色
            return polylineRender
        }
        
        // 圆形
        if overlay.isKind(of: MKCircle.self) {
            let circleRender = MKCircleRenderer(overlay: overlay)
            circleRender.fillColor = UIColor.cyan
            circleRender.alpha = 0.5
            return circleRender
        }
        
        return render
    }
    
    /** ADD BLUEW ARROW **/
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if views.last?.annotation is MKUserLocation{
            //NSLog("---MapVC--- inside didAdd views,  addHeadingView start")
            addHeadingView(toAnnotationView: views.last!)
        }
    }
    
    func addHeadingView(toAnnotationView annotationView: MKAnnotationView){
        let blueArrow = UIImage(named: "arrow")
        headingImageView = UIImageView(image: blueArrow)
        headingImageView!.frame = CGRect(x: (annotationView.frame.size.width - blueArrow!.size.width)/2, y: (annotationView.frame.size.height - blueArrow!.size.height)/2, width: blueArrow!.size.width, height: blueArrow!.size.height)
        annotationView.insertSubview(headingImageView!, at: 0)
        headingImageView!.isHidden = true
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
            myLocationManager.startUpdatingHeading()
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
            myLocationManager.startUpdatingHeading()
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
        
        sceneView.session.run(configuration)
    }
    
    @objc func AppGoToBackground(){
        NSLog("---MapVC--- App go to background")
        BLEManager.shared().stopScan()
        //NotificationCenter.default.removeObserver(self)
        
        // Pause the view's session
        sceneView.session.pause()
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
        NSLog("---MapVC--- BLE connection failed")
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
    
    @objc func UpdateBikeLocation(){
        NSLog("---MapVC--- update bike location")
        DataMgr.setBikelocation((userlocation?.coordinate.latitude)!, (userlocation?.coordinate.longitude)!)
        
        if bikeAnnotation != nil{
            myMapView.removeAnnotation(bikeAnnotation)
            
            bikelocation = DataMgr.getBikelocation()
            bikeAnnotation.coordinate = CLLocation(latitude: bikelocation!.coordinate.latitude, longitude: bikelocation!.coordinate.longitude).coordinate
            bikeAnnotation.title = "Bike location"
            bikeAnnotation.subtitle = "updated time: "
            
            myMapView.addAnnotation(bikeAnnotation)
        }
    }
    
    /****** AR FUNCTION ******/
    func updateLocation(_ latitude : Float, _ longitude : Float) {
        let location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        let locationTransform = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: userlocation!, location: location)
        let position = SCNVector3.positionFromTransform(locationTransform)
        self.distance = Float(location.distance(from: userlocation!))
        NSLog("---ARVC--- user location = \(userlocation!.coordinate)")
        NSLog("---ARVC--- bike location = \(bikelocation!.coordinate)")
        
        if self.modelNode == nil {
            let modelScene = SCNScene(named: "art.scnassets/Car.scn")!
            self.modelNode = modelScene.rootNode.childNode(withName: rootNodeName, recursively: true)!
            // Move model's pivot to its center in the Y axis
            let (minBox, maxBox) = self.modelNode.boundingBox
            self.modelNode.pivot = SCNMatrix4MakeTranslation(0, (maxBox.y - minBox.y)/2, 0)
            
            // Save original transform to calculate future rotations
            self.originalTransform = self.modelNode.transform
            
            // Position the model in the correct place
            //positionModel(location)
            let scale = max( min( Float(1000/distance), 1.5 ), 3 )
            modelNode.position = position
            modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            
            // Add the model to the scene
            sceneView.scene.rootNode.addChildNode(self.modelNode)
            
            //add navigation service
            let navService = NavigationService()
            let request = MKDirections.Request()
            self.destinationLocation = CLLocationCoordinate2D(latitude: (bikelocation?.coordinate.latitude)!, longitude: (bikelocation?.coordinate.longitude)!)
            
            NSLog("---ARVC--- getting steps")
            if destinationLocation != nil {
                navService.getDirections(destinationLocation: destinationLocation, request: request)
                {
                    steps in
                    for step in steps {
                        self.steps.append(step)
                        //NSLog("---ARVC--- step instruction = \(step.instructions), distance = \(step.distance), location = (\(step.getLocation().coordinate.latitude), \(step.getLocation().coordinate.longitude))")
                        self.addSphere(for: step)
                    }
                }
            }
        } else {
            // Begin animation
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            
            // Position the model in the correct place
            //positionModel(location)
            let scale = max( min( Float(1000/distance), 1.5 ), 3 )
            modelNode.position = position
            modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            
            //re-place nodes
            for baseNode in nodes {
                let translation = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: userlocation!, location: baseNode.location)
                let position = SCNVector3.positionFromTransform(translation)
                let distance = baseNode.location.distance(from: userlocation!)
                DispatchQueue.main.async {
                    let scale = 100 / Float(distance)
                    baseNode.scale = SCNVector3(x: scale, y: scale, z: scale)
                    baseNode.anchor = ARAnchor(transform: translation)
                    baseNode.position = position
                }
            }
            
            // End animation
            SCNTransaction.commit()
        }
    }
    // For navigation route step add sphere node
    
    func addSphere(for step: MKRoute.Step) {
        let stepLocation = step.getLocation()
        NSLog("---ARVC--- stepLocation = \(stepLocation.coordinate), stepInstruction = \(step.instructions)")
        let locationTransform = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: userlocation!, location: stepLocation)
        let position = SCNVector3.positionFromTransform(locationTransform)
        let stepAnchor = ARAnchor(transform: locationTransform)
        
        anchors.append(stepAnchor)
        
        let sphere = BaseNode(title: step.instructions, location: stepLocation)
        if step.instructions.isEmpty {
            //NSLog("---ARVC--- step instruction is empty")
            //sphere.addNode(with: 0.5, and: .blue, and: "Start")
        }
        else{
            sphere.addNode(with: 0.5, and: .blue, and: step.instructions)
        }
        sphere.location = stepLocation
        let distance = sphere.location.distance(from: userlocation!)
        let scale = 20 / Float(distance)
        sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
        sphere.position = position
        sphere.anchor = stepAnchor
        
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(sphere)
        
        //        NSLog("---ARVC--- starting location = \(userlocation!.coordinate)")
        //        NSLog("---ARVC--- destination = \(sphere.location.coordinate)")
        //        NSLog("---ARVC--- distance = \(distance)")
        //        NSLog("---ARVC--- sphere position = \(sphere.position)")
        nodes.append(sphere)
    }
    
    // For intermediary locations - CLLocation - add sphere
    private func addSphere(for location: CLLocation) {
        let locationTransform = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: startingLocation, location: location)
        let position = SCNVector3.positionFromTransform(locationTransform)
        let stepAnchor = ARAnchor(transform: locationTransform)
        anchors.append(stepAnchor)
        
        let sphere = BaseNode(title: "Title", location: location)
        sphere.addSphere(with: 0.5, and: .blue)
        sphere.location = location
        let distance = sphere.location.distance(from: startingLocation)
        let scale = 10 / Float(distance)
        sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
        sphere.position = position
        sphere.anchor = stepAnchor
        sceneView.scene.rootNode.addChildNode(sphere)
        sceneView.session.add(anchor: stepAnchor)
        nodes.append(sphere)
        
        NSLog("---ARVC--- starting location = \(startingLocation.coordinate)")
        NSLog("---ARVC--- destination = \(sphere.location.coordinate)")
        NSLog("---ARVC--- distance = \(distance)")
        NSLog("---ARVC--- sphere position = \(sphere.position)")
    }
    
    func setStatusText() {
        statusTextView.text = "Distance: \(String(format: "%.2f m", distance))"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
