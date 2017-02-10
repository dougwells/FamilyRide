//
//  riderMapViewController.swift
//  uberClone
//
//  Created by Doug Wells on 2/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class riderMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!

    @IBAction func logoutButton(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "riderMapToLogin", sender: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set vars to make code cleaner.  Note: CL stands for "Call Location"
        let latitude: CLLocationDegrees = 40.6461
        let longitude: CLLocationDegrees = -111.4980
        let latDelta: CLLocationDegrees = 0.03	//amnt of lat/lon in set amount of space
        let lonDelta: CLLocationDegrees = 0.03	//lower = less distance so more “zoom”
        
        //Sets "zoom" level
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        //Sets location
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //Sets initial "region" (location and zoom level with vars "location" & "span")
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        
        //Finally, time to tell iOS where in map to set initial location and zoom level
        //Technically, could simply use this line but code would not be clear ...
        map.setRegion(region, animated: true)


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
