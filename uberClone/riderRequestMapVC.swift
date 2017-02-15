//
//  riderRequestMapVC.swift
//  uberClone
//
//  Created by Doug Wells on 2/15/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse
import CoreLocation

class riderRequestMapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var requestUsernames = [String]()
    var requestObjectIds = [String]()
    var requestPFGeopoints = [PFGeoPoint]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createAnnotation (title: String, subTitle: String) {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subTitle
        annotation.coordinate = map.convert(touchPoint, toCoordinateFrom: self.map)
        map.addAnnotation(annotation)
    }
    
    func updateRideRequestsMap() {
        
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if let driverGeoPoint = geopoint {
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("location", nearGeoPoint: driverGeoPoint )
                query.limit = 10
                
                self.requestUsernames.removeAll()
                self.requestObjectIds.removeAll()
                self.requestPFGeopoints.removeAll()
                
                query.findObjectsInBackground(block: { (objects, error) in
                    if let riderRequests = objects {
                        for riderRequest in riderRequests {
                            
                            let requestId = riderRequest.objectId
                            let riderName = riderRequest["username"]
                            let riderId = riderRequest["userId"]
                            let riderLocation = riderRequest["location"] as? PFGeoPoint
                            let distance = riderLocation?.distanceInMiles(to: driverGeoPoint)
                            self.requestUsernames.append(riderName as! String)
                            self.requestObjectIds.append(requestId! as String)
                            //print("Username", riderName)
                            
                        }
                    }
                    //self.tableView.reloadData()
                })
                
            }
        }
    } //end updateRideRequestsMap
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
