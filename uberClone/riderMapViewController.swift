//
//  riderMapViewController.swift
//  uberClone
//
//  Created by Doug Wells on 2/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Parse

class riderMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var existingUberRequest = false
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    func createAlert(title: String, message: String ) {
        //creat alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //add button to alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert
    
    
    @IBAction func callAnUber(_ sender: UIButton) {
        
        if !existingUberRequest {
            existingUberRequest = true
            sender.setTitle("Cancel Uber", for: [])
            
            PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
                self.createAlert(title: "Uber", message: "Your pickup request has been made.")
                print("Uber requested. PFGeopoint =", geopoint)
                if let geopoint = geopoint {
                    
                    let riderRequest = PFObject(className: "RiderRequest")
                    
                    riderRequest["location"] = geopoint as? PFGeoPoint
                    riderRequest["username"] = PFUser.current()?.username
                    riderRequest["riderId"] = PFUser.current()?.objectId
                    riderRequest.saveInBackground()
                }
            }
        } else {
            existingUberRequest = false
            sender.setTitle("Call an Uber", for: [])
            self.createAlert(title: "Uber", message: "Your Uber request has been cancelled.")
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("riderId", equalTo: PFUser.current()?.objectId)
            query.findObjectsInBackground(block: { (objects, error) in
                if let requests = objects {
                    for object in requests {
                        if let request = object as? PFObject {
                            request.deleteInBackground()
                        }
                    }
                }
            })
        }
        
        
        
    }
    

    @IBAction func logoutButton(_ sender: UIBarButtonItem) {
        print("Logging out \(PFUser.current()?.username).")
        self.locationManager.stopUpdatingLocation()
        self.performSegue(withIdentifier: "riderMapToLogin", sender: self)
        PFUser.logOutInBackground(block: { (error) in
            if error != nil {
                print("error logging out user \(PFUser.current()?.username)")
            } else {
                print("logged out user \(PFUser.current()?.username)")
            }
        })
    } //end logoutButton
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self  //sets delegate to VC so VC can control it
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //several accuracies avail.
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true  //shows user location
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //set lat, lon and deltas
        
        if let riderLocation = manager.location?.coordinate {
            latitude = riderLocation.latitude
            longitude = riderLocation.longitude
            print("user location =", latitude, longitude)
        }

        let latDelta: CLLocationDegrees = 0.02
        let lonDelta: CLLocationDegrees = 0.02
        
        //Sets "zoom" level
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        //Sets location
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //Sets initial "region" (location and zoom level with vars "location" & "span")
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        
        //Finally, time to tell iOS where in map to set initial location and zoom level
        self.map.setRegion(region, animated: true)
        //saveCurrUserLocation()
        
        //set annotation (delete prev annot & create new one)
        if map.annotations.count != 0 {
            map.removeAnnotations(map.annotations)
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        annotation.title = "Rider location"
        self.map.addAnnotation(annotation)
    }
    
    
    
    func saveCurrUserLocation() {
        //find user location (need to add "Privacy - Location when in use in plist for PFGeopoint to work
        
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            print("saveCurrUserLocation returned. PFGeopoint =", geopoint)
            if let geopoint = geopoint {
                
                let riderRequest = PFObject(className: "RiderRequest")
                
                riderRequest["location"] = geopoint as? PFGeoPoint
                riderRequest["username"] = PFUser.current()?.username
                riderRequest["riderId"] = PFUser.current()?.objectId
                riderRequest.saveInBackground()
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
