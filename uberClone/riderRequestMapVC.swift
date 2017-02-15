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
    var locationManager = CLLocationManager()
    var requestUsernames = [String]()
    var requestObjectIds = [String]()
    var requestPFGeopoints = [PFGeoPoint]()
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView Id")
        if view == nil{
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView Id")
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        
        view?.leftCalloutAccessoryView = nil
        view?.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        //swift 1.2
        //view?.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType == UIButtonType.detailDisclosure {
            mapView.deselectAnnotation(view.annotation, animated: false)
            performSegue(withIdentifier: "segue Id to detail vc", sender: view)
        }
    }

//Your function to load the annotations in viewDidLoad


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
