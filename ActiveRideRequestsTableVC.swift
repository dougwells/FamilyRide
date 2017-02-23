//
//  ActiveRideRequestsTableVC.swift
//  uberClone
//
//  Created by Doug Wells on 2/13/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import Foundation

class ActiveRideRequestsTableVC: UITableViewController, CLLocationManagerDelegate {
    
    
    let locationManager = CLLocationManager()
    var requestUsernames = [String]()
    var requestObjectIds = [String]()
    var requestLocations = [PFGeoPoint]()
    
    
    
    @IBAction func tableToMap(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "tableToMap", sender: self)
    }

    
    @IBAction func updateTable(_ sender: UIBarButtonItem) {
        updateActiveRideRequestsTable()
    }
    
    @IBAction func logout(_ sender: Any) {
        
        print("Logging out \(PFUser.current()?.username).")
        
        PFUser.logOutInBackground(block: { (error) in
            
            if error != nil {
                
                print("error logging out user \(PFUser.current()?.username)")
                
            } else {
                
                print("logged out user \(PFUser.current()?.username)")
                
                self.navigationController?.navigationBar.isHidden = true
                //self.navigationController?.toolbar.isHidden = true
                self.navigationController?.setToolbarHidden(true, animated: false)
                
                self.locationManager.stopUpdatingLocation()
                self.performSegue(withIdentifier: "activeRideReqTableToLogin", sender: self)
                
            }
        })
    }
    

    
    func createAlert(title: String, message: String ) {
        //creat alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //add button to alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert

    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        updateActiveRideRequestsTable()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        locationManager.delegate = self  //sets delegate to VC so VC can control it
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //several accuracies avail.
        locationManager.requestWhenInUseAuthorization()
        
        // Uncomment if want auto-update of table (~ every 2 seconds)
            //locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        updateActiveRideRequestsTable()
        
        /*  Using CLLocation to find driver's position
         
        if let location = manager.location?.coordinate {
            
            let driverGeoPoint = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
            
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("location", nearGeoPoint: driverGeoPoint )
            query.limit = 10
            
            requestUsernames.removeAll()
            requestObjectIds.removeAll()
            
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
                        print("Username", riderName)
    
                    }
                }
                self.tableView.reloadData()
            })
            
        }
    */
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {   //activate Segue to secondView
        print("indexPath = ", indexPath.row)
        //performSegue(withIdentifier: "tableToDirections", sender: nil)
        
        let message = self.requestUsernames[indexPath.row]
        let messageArr = message.components(separatedBy: "|")
        let name = messageArr[0]
        let geopoint = self.requestLocations[indexPath.row]
        
        let latitude = geopoint.latitude
        let longitude = geopoint.longitude
        
        let acceptRideAlert = UIAlertController(title: "Accept ride request from \(name)?", message: "Press OK to accept & to obtain directions to pickup location", preferredStyle: UIAlertControllerStyle.alert)
        
        acceptRideAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        acceptRideAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action) in
            
            self.getDirections(latitude: latitude, longitude: longitude, name: name )
            
            print("Accept Ride.  OK pressed.\(name))")
            acceptRideAlert.dismiss(animated: true, completion: nil)
            
            
        }))
        
        present(acceptRideAlert, animated: true, completion: nil)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateActiveRideRequestsTable() {
        
        PFGeoPoint.geoPointForCurrentLocation { (geopoint, error) in
            
            if let driverGeoPoint = geopoint {
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("location", nearGeoPoint: driverGeoPoint )
                query.limit = 10
                
                self.requestUsernames.removeAll()
                self.requestObjectIds.removeAll()
                self.requestLocations.removeAll()
                
                query.findObjectsInBackground(block: { (objects, error) in
                        if let riderRequests = objects {
                            if riderRequests.count > 0 {
                                for riderRequest in riderRequests {
                            
                                    let requestId = riderRequest.objectId
                                    let riderId = riderRequest["userId"]
                                    let riderLocation = riderRequest["location"] as? PFGeoPoint
                                    let distance = riderLocation!.distanceInMiles(to: driverGeoPoint)
                                    let distanceString = String(format: "%.2f miles", distance)
                                    let riderName = riderRequest["username"]! as! String
                                    let riderNameArr = riderName.components(separatedBy: "-")
                                    
                                    let riderMessage = "\(riderNameArr[1]) | Distance: \(distanceString)"
                                    self.requestUsernames.append(riderMessage)
                                    self.requestObjectIds.append(requestId! as String)
                                    self.requestLocations.append(riderLocation!)
                                    //print("Username", riderName)
                                }
                            }
                        }
                    
                    self.tableView.reloadData()
                })

            }
        }
    } //end updateUberPickupLocation

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestUsernames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        

        // Configure the cell...
        cell.textLabel?.text = requestUsernames[indexPath.row]

        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
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
