//
//  ARVC.swift
//  team5ui
//
//  Created by V.Lab on 2018/11/27.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreLocation

class ARVC: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var steps: [MKRoute.Step] = []
    var anchors: [ARAnchor] = []
    var startingLocation: CLLocation!
    var nodes: [BaseNode] = []
    var destinationLocation: CLLocationCoordinate2D!
    var myLocationManager = CLLocationManager()
    
    var modelNode:SCNNode!
    let rootNodeName = "Car"
    var originalTransform:SCNMatrix4!
    @IBOutlet weak var statusTextView: UITextView!
    var distance : Float! = 0.0{
        didSet {
            setStatusText()
        }
    }
    
    var status: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
//        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//        // Set the scene to the view
//        sceneView.scene = scene
        let scene = SCNScene()
        sceneView.scene = scene
            
        //get user location
        myLocationManager.delegate = self
        myLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        myLocationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            // 開始定位自身位置
            myLocationManager.startUpdatingLocation()
        }
        
//        NSLog("---ARVC--- current location= (\(String(describing: myLocationManager.location?.coordinate.latitude)), \(String(describing: myLocationManager.location?.coordinate.longitude))")
//        startingLocation = myLocationManager.location;
//        let navService = NavigationService()
//
//        self.destinationLocation = CLLocationCoordinate2D(latitude: 25.061543, longitude: 121.549696)
//        let request = MKDirections.Request()
//
//        NSLog("---ARVC--- getting steps")
//        if destinationLocation != nil {
//            navService.getDirections(destinationLocation: destinationLocation, request: request)
//            {
//                steps in
//                for step in steps {
//                    self.steps.append(step)
//                    NSLog("---ARVC--- step instruction = \(step.instructions), distance = \(step.distance), location = (\(step.getLocation().coordinate.latitude), \(step.getLocation().coordinate.longitude))")
//                    self.addSphere(for: step)
//                }
//            }
//        }
        //NSLog("---ARVC--- add sphere test")
        //self.addSphere(for: CLLocation.init(latitude: 25.061543, longitude: 121.549696))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        NSLog("---ARVC--- CLAuthorizationStatus change to = \(status)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("---ARVC--- inside didUpdateLocations")
        if let userlocation = locations.last{
            NSLog("---ARVC--- arlocation: (\(userlocation.coordinate.latitude), \(userlocation.coordinate.longitude))")
            updateLocation(Float(bikelocation!.coordinate.latitude),Float(bikelocation!.coordinate.longitude))
        }
        //let locValue: CLLocationCoordinate2D = (manager.location?.coordinate)!
        //NSLog("---ARVC--- my locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
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
            
        } else {
            // Begin animation
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            
            // Position the model in the correct place
            //positionModel(location)
            let scale = max( min( Float(1000/distance), 1.5 ), 3 )
            modelNode.position = position
            modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            
            // End animation
            SCNTransaction.commit()
        }
    }
    // For navigation route step add sphere node
    
    func addSphere(for step: MKRoute.Step) {
        let stepLocation = step.getLocation()
        NSLog("---ARVC--- stepLocation = \(stepLocation.coordinate)")
        let locationTransform = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: startingLocation, location: stepLocation)
        let position = SCNVector3.positionFromTransform(locationTransform)
        let stepAnchor = ARAnchor(transform: locationTransform)
        
        anchors.append(stepAnchor)
        
        let sphere = BaseNode(title: step.instructions, location: stepLocation)
        if step.instructions.isEmpty {
            sphere.addNode(with: 0.5, and: .yellow, and: "Start")
        }
        else{
            sphere.addNode(with: 0.5, and: .yellow, and: step.instructions)
        }
        sphere.location = stepLocation
        let distance = sphere.location.distance(from: startingLocation)
        let scale = 20 / Float(distance)
        sphere.scale = SCNVector3(x: scale, y: scale, z: scale)
        sphere.position = position
        sphere.anchor = stepAnchor
        
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(sphere)
        
        NSLog("---ARVC--- starting location = \(startingLocation.coordinate)")
        NSLog("---ARVC--- destination = \(sphere.location.coordinate)")
        NSLog("---ARVC--- distance = \(distance)")
        NSLog("---ARVC--- sphere position = \(sphere.position)")
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
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
