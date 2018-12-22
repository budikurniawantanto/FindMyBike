//
//  DataManager.swift
//  FindMyBike
//
//  Created by budi on 2018/12/22.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import Foundation
import CoreLocation

class DataManager{
    func getBleconnectionName()->String?{
        //
        let LastBeanName = UserDefaults.standard.dictionary(forKey: "BeanName")
        NSLog("---DataManager--- LastBeanName:\(String(describing: LastBeanName))")
        if (LastBeanName != nil){
            return (LastBeanName as! String)
        }
        else{
            //first use
            return nil
        }
    }
    
    func getBikelocation()->CLLocation?{
        let lastbikelocation = UserDefaults.standard.dictionary(forKey: "lastbikelocation")
        if(lastbikelocation != nil){
            NSLog("---DataManager--- loading last bike location")
            let locationinfo = UserDefaults.standard.dictionary(forKey: "lastbikelocation")
            //bikelocation = CLLocation(latitude: locationinfo!["latitude"] as! Double, longitude: locationinfo!["longtitude"] as! Double)
            NSLog("---DataManager--- true bike location")
            return CLLocation(latitude: locationinfo!["latitude"] as! Double, longitude: locationinfo!["longtitude"] as! Double)
            //testing
            //setBikelocation(userlocation!.coordinate.latitude + 0.001, userlocation!.coordinate.longitude + 0.0006)
        }
            
        else{
            //first use
            NSLog("---DataManager--- first use bike location")
            let bikelat = userlocation!.coordinate.latitude
            let bikelong = userlocation!.coordinate.longitude
            bikelocation = CLLocation(latitude: bikelat, longitude: bikelong)
            NSLog("---DataManager--- nil bike location")
            return nil
            //setBikelocation(bikelat,bikelong)
        }
    }
    
    func setBikelocation(_ latitude: Double, _ longtitude: Double){
        let newlocation = ["latitude" : latitude, "longtitude" : longtitude]
        UserDefaults.standard.set(newlocation, forKey: "lastbikelocation")
    }
    
    func setBeanname(_ beanName: String){
        UserDefaults.standard.set(beanName, forKey: "BeanName")
    }
}
