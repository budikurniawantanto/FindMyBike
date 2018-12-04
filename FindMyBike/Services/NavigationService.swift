//
//  NavigationService.swift
//  ARKitDemoApp
//
//  Created by Christopher Webb-Orenstein on 8/27/17.
//  Copyright © 2017 Christopher Webb-Orenstein. All rights reserved.
//

import MapKit
import CoreLocation

struct NavigationService{
    
    func getDirections(destinationLocation: CLLocationCoordinate2D, request: MKDirections.Request, completion: @escaping ([MKRoute.Step]) -> Void) {
        var steps: [MKRoute.Step] = []
        
        let placeMark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude))
        //print("---NavigationService--- placeMark = \(placeMark)")
        
        request.destination = MKMapItem.init(placemark: placeMark)
        request.source = MKMapItem.forCurrentLocation()
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        //print("---NavigationService--- request = \(request), source = ())")
        
        let directions = MKDirections(request: request)
        //print("---NavigationService--- directions = \(directions)")
        
        directions.calculate { response, error in
            if error != nil {
                print("Error getting directions")
            } else {
                guard let response = response else { return }
                for route in response.routes {
                    print("---NavigationService--- route distance = \(route.expectedTravelTime)")
                    steps.append(contentsOf: route.steps)
                }
                completion(steps)
                print("---NavigationService--- steps done")
            }
        }
    }
}
