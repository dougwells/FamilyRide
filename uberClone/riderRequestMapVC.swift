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
    var requestUsernames = [String]()
    var requestObjectIds = [String]()
    var requestPFGeopoints = [PFGeoPoint]()
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //set lat, lon and deltas
        
        if let riderLocation = manager.location?.coordinate {
            latitude = riderLocation.latitude
            longitude = riderLocation.longitude
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
                            let riderName = riderRequest["username"] as? String
                            let riderId = riderRequest["userId"] as? String
                            let riderLocation = riderRequest["location"] as? PFGeoPoint
                            let distance = riderLocation?.distanceInMiles(to: driverGeoPoint)
                            let distanceMessage = "Miles Away: \(String(describing: distance))"
                            self.requestUsernames.append(riderName!)
                            self.requestObjectIds.append(requestId!)
                            self.requestPFGeopoints.append(riderLocation!)
                            self.createAnnotation(title: riderName!, subTitle: distanceMessage, point: riderLocation!)
                            //print("Username", riderName)
                            
                        }
                    }
                    //self.tableView.reloadData()
                })
                
            }
        }
    } //end updateRideRequestsMap
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
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
    
    func getDirections(){
        print("Hello World")
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
