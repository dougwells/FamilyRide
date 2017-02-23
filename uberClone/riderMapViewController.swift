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
    let annotation = MKPointAnnotation()
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    
    @IBAction func callAnUber(_ sender: UIButton) {
        
        if latitude == 0.0 && longitude == 0.0 {
            self.createAlert(title: "Uber", message: "Unable to access your location. Please allow app to access location.")
        }
        
        if !existingUberRequest {
            
            self.makeNewUberRequest()
            
        } else {
            
            self.cancelExistingUberRequest()
            
        }
    }
    

    @IBAction func logoutButton(_ sender: UIBarButtonItem) {
        
        print("Logging out \(PFUser.current()?.username).")
        
        self.locationManager.stopUpdatingLocation()
        
        existingUberRequest = false
        
        if map.annotations.count != 0 {
            map.removeAnnotations(map.annotations)
        }
        
        
        
        
        //Did not use this function as gives user alert but no way to respond
            //self.cancelExistingUberRequest()
        
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
        
        PFUser.logOutInBackground(block: { (error) in
            
            if error != nil {
                
                print("error logging out user \(PFUser.current()?.username)")
                
            } else {
                
                print("logged out user \(PFUser.current()?.username)")
                
                self.performSegue(withIdentifier: "riderMapToLogin", sender: self)
                
            }
        })
    } //end logoutButton
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.callAnUberButton.isHidden = true
        
        locationManager.delegate = self  //sets delegate to VC so VC can control it
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //several accuracies avail.
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true  //shows user location
        
        /*
         if user closes app w/o cancelling Uber, there is an outstanding
         Uber request when app re-opens.  Therefore, force user to cancel
         existing Uber before ordering a new one
        */
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("riderId", equalTo: PFUser.current()?.objectId)
        
        query.findObjectsInBackground(block: { (objects, error) in
            if objects?.count != 0 {
                self.existingUberRequest = true
                self.callAnUberButton.setTitle("Cancel Uber", for: [])
            }
            self.callAnUberButton.isHidden = false
        })
        
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

        let latDelta: CLLocationDegrees = 0.01
        let lonDelta: CLLocationDegrees = 0.01
        
        //Sets "zoom" level
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        //Sets location
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //Sets initial "region" (location and zoom level with vars "location" & "span")
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        
        //Finally, time to tell iOS where in map to set initial location and zoom level
        self.map.setRegion(region, animated: true)
        
        
    }
    
    func createAlert(title: String, message: String ) {
        //creat alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //add button to alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert
    
    func showAnnotation() {
        if map.annotations.count != 0 {
            map.removeAnnotations(map.annotations)
        }
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        annotation.title = "Pickup location"
        map.addAnnotation(annotation)
    }
    
    func makeNewUberRequest() {
        existingUberRequest = true
        callAnUberButton.setTitle("Cancel Uber", for: [])
        
        /*  Could also have made a PFGeopoint
            riderRequest["location"] = PFGeopoint(latitude: latitude, longitude: longitude)
        */
    
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            self.createAlert(title: "Uber", message: "Your pickup request has been made.")
            print("Uber requested. PFGeopoint =", geopoint)
            if let geopoint = geopoint {
                
                self.showAnnotation()
                let riderRequest = PFObject(className: "RiderRequest")
                riderRequest["location"] = geopoint as? PFGeoPoint
                riderRequest["username"] = PFUser.current()?.username
                riderRequest["riderId"] = PFUser.current()?.objectId
                riderRequest["driverAccepted"] = "Not yet accepted"
                riderRequest.saveInBackground()
            }
        }
    }
    
    @IBAction func updatePickupLocation(_ sender: UIBarButtonItem) {
        
        self.updateUberPickupLocation()
    }
    
    func cancelExistingUberRequest() {
        existingUberRequest = false
        
        if map.annotations.count != 0 {
            map.removeAnnotations(map.annotations)
        }
        
        callAnUberButton.setTitle("Call an Uber", for: [])
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
    
    
    
    func updateUberPickupLocation() {
        
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if let geopoint = geopoint {
                
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("riderId", equalTo: PFUser.current()?.objectId)
                
                query.findObjectsInBackground(block: { (objects, error) in
                    if let requests = objects {
                        if  requests.count == 0 {
                            self.createAlert(title: "Unable to update pickup location.", message: "You do not have an existing Uber pickup request.  Please call an Uber.")
                            print("Update Pickup error:", error)
                        } else {
                            for object in requests {
                                if let request = object as? PFObject {
                                    request["location"] = geopoint as? PFGeoPoint
                                    self.showAnnotation()
                                    print("Pickup location updated")
                                    request.saveInBackground()
                                }
                            }
                        }

                    }
                })
            }
        }
    } //end updateUberPickupLocation
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
