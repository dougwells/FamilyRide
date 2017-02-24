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
import Foundation
import CoreLocation

class riderRequestMapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var locationManager = CLLocationManager()
    var timer = Timer()
    var requestUsernames = [String]()
    var requestObjectIds = [String]()
    var requestPFGeopoints = [PFGeoPoint]()
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0
    
    override func viewDidAppear(_ animated: Bool) {
        self.map.removeAnnotations(self.map.annotations)
        self.updateRideRequestsMap()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateRideRequestsMap), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer.invalidate()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.map.delegate = self
        locationManager.delegate = self  //sets delegate to VC so VC can control it
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //several accuracies avail.
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true  //shows user location
        self.updateRideRequestsMap()

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //set lat, lon and deltas
        
        if let driverLocation = manager.location?.coordinate {
            latitude = driverLocation.latitude
            longitude = driverLocation.longitude
            //print("user location =", latitude, longitude)

        }
        
        let latDelta: CLLocationDegrees = 0.10
        let lonDelta: CLLocationDegrees = 0.10
        
        //Sets "zoom" level
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        //Sets location
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //Sets initial "region" (location and zoom level with vars "location" & "span")
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        
        //Finally, time to tell iOS where in map to set initial location and zoom level
        self.map.setRegion(region, animated: true)
        
        
    }
    
    func createAnnotation (title: String, subTitle: String, point: PFGeoPoint) {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subTitle
        annotation.coordinate = CLLocationCoordinate2DMake(point.latitude, point.longitude)
        map.addAnnotation(annotation)
    }
    
    func updateRideRequestsMap() {
        
        
        
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if let driverGeoPoint = geopoint {
                
                print("== Driver username: \(PFUser.current()?.username) ==")
                let driverQuery = PFQuery(className: "DriverLocation")
                driverQuery.whereKey("username", equalTo: (PFUser.current()?.username!)! as String)
                driverQuery.findObjectsInBackground(block: { (objects, error) in
                    if let driverLocations = objects {
                        
                        if driverLocations.count > 0 {
                            for driverLocation in driverLocations {
                                driverLocation.deleteInBackground()
                                print("old driver locations deleted")
                            }
                        }
                        
                        let driverLocation = PFObject(className: "DriverLocation")
                        driverLocation["username"] = PFUser.current()?.username
                        driverLocation["location"] = driverGeoPoint
                        driverLocation.saveInBackground()
                        print ("driver location saved")
                            
                    }
                })
                
                
                
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("driverAccepted", equalTo: "Not yet accepted")
                query.whereKey("location", nearGeoPoint: driverGeoPoint )
                query.limit = 10
                
                self.requestUsernames.removeAll()
                self.requestObjectIds.removeAll()
                self.requestPFGeopoints.removeAll()
                
                query.findObjectsInBackground(block: { (objects, error) in
                    if let riderRequests = objects {
                        for riderRequest in riderRequests {
                            
                            let requestId = riderRequest.objectId
                            let riderName = riderRequest["username"] as! String
                            let riderNameArr = riderName.components(separatedBy: "-")
                            let riderId = riderRequest["userId"] as? String
                            let riderLocation = riderRequest["location"] as? PFGeoPoint
                            let distance = riderLocation?.distanceInMiles(to: driverGeoPoint)
                            let distanceMessage = String(format: "Distance: %.2f miles", distance!)
                            let riderMessage = "\(riderNameArr[1]) | Distance: \(distanceMessage)"
                            
                            self.requestUsernames.append(riderNameArr[1])
                            self.requestObjectIds.append(requestId!)
                            self.requestPFGeopoints.append(riderLocation!)
                            self.createAnnotation(title: riderNameArr[1], subTitle: distanceMessage, point: riderLocation!)
                            
                        }
                    }
                })
                
            }
        }
    } //end updateRideRequestsMap
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "") {
            annotationView.annotation = annotation
            return annotationView
            
        } else {
            let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:"pin")
            annotationView.isEnabled = true
            annotationView.canShowCallout = true
            annotationView.pinColor = .purple
            
            let acceptButton = UIButton(type: UIButtonType.custom) as UIButton
            acceptButton.frame.size.width = 30
            acceptButton.frame.size.height = 30
            acceptButton.setImage(#imageLiteral(resourceName: "acceptIcon.png"), for: .normal)
            
            let rejectButton = UIButton(type: UIButtonType.custom) as UIButton
            rejectButton.frame.size.width = 30
            rejectButton.frame.size.height = 30
            rejectButton.setImage(#imageLiteral(resourceName: "rejectIcon.png"), for: .normal)
            
            annotationView.rightCalloutAccessoryView = acceptButton
            annotationView.leftCalloutAccessoryView = rejectButton
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        
        if (control == view.leftCalloutAccessoryView) {
            
            let rejectRideAlert = UIAlertController(title: "Ride request rejected", message: "Press OK to continue", preferredStyle: UIAlertControllerStyle.alert)
            
            rejectRideAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

            present(rejectRideAlert, animated: true, completion: nil)
        }
        
        else if (control == view.rightCalloutAccessoryView) {
            let acceptRideAlert = UIAlertController(title: "Ride request accepted", message: "Press OK to confirm & to obtain directions to pickup location", preferredStyle: UIAlertControllerStyle.alert)
            
            acceptRideAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            
            acceptRideAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action) in
                
                let latitude = view.annotation?.coordinate.latitude
                let longitude = view.annotation?.coordinate.longitude
                self.updateRideRequestsMap()
                

                
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("username", contains: (view.annotation?.title)!)
                query.findObjectsInBackground(block: { (objects, error) in
                    if let riderRequests = objects {
                        
                        for riderRequest in riderRequests {
                            if riderRequest["driverAccepted"] as! String == "Not yet accepted" {
                                
                                riderRequest["driverAccepted"] = PFUser.current()?.username
                                riderRequest.saveInBackground()
                                self.getDirections(latitude: latitude!, longitude: longitude!, name: ((view.annotation?.title)!)!)
                                
                            } else {
                                
                                let missedItAlert = UIAlertController(title: "Sorry, another driver has already selected this rider.", message: "Please select another rider", preferredStyle: UIAlertControllerStyle.alert)
                                
                                missedItAlert.addAction(UIAlertAction(title: "Bummer", style: .default, handler: nil))
                                
                                self.present(missedItAlert, animated: true, completion: nil)
                                self.map.removeAnnotations(self.map.annotations)
                                self.updateRideRequestsMap()

                            }
                        }
                    }
                })
                
                print("Accept Ride.  OK pressed.\(view.annotation?.title))")
                acceptRideAlert.dismiss(animated: true, completion: nil)
                
            
            }))
            
            present(acceptRideAlert, animated: true, completion: nil)
        }
    }
    
    func getDirections (latitude: CLLocationDegrees, longitude: CLLocationDegrees, name: String) {
        
        let requestCLLocation = CLLocation(latitude: latitude, longitude: longitude)
            CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) in
                
                if let placemarks = placemarks {
                    if placemarks.count > 0 {
                        let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                        let mapItem = MKMapItem(placemark: mKPlacemark)
                        
                        mapItem.name = name
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        mapItem.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            })
    }
    
    func createAlert(title: String, message: String ) {
        //creat alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //add button to alert
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default , handler: { (action) in
            
        //print("OK Pressed")
        }))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert
    
/*
    func mapView(_ mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            
            pinAnnotationView.pinColor = .purple
            pinAnnotationView.isDraggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            
        let deleteButton = UIButton(type:UIButtonType.custom) as UIButton
            deleteButton.frame.size.width = 44
            deleteButton.frame.size.height = 44
            deleteButton.backgroundColor = UIColor.red
            deleteButton.setImage(UIImage(named: "trash"), for: .normal)
            
            pinAnnotationView.leftCalloutAccessoryView = deleteButton
            
            return pinAnnotationView
    }
 
 */
    
/*
     func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        mapView.removeAnnotation(annotation)
    }
 */

    
   /*
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "mapToDirections", sender: view)
            print("annotation clicked")
        }
    }
    */
    
    /*
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        if #available(iOS 9.0, *) {
            pinView?.pinTintColor = UIColor.orange
        } else {
            // Fallback on earlier versions
        }
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: "getDirections", for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
     */


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
