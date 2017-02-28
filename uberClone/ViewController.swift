/**
* Copyright (c) 2017-present, Doug Wells
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController {
    
    //spinner
    let activityIndicator = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    var signupMode = false
    
    @IBOutlet weak var isDriverSwitch: UISwitch!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupOrLoginButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var changeSignupModeButton: UIButton!

    @IBAction func changeSignupMode(_ sender: Any) {
        if signupMode {
            //Change layout to login
            
            signupOrLoginButton.setTitle("Log In", for: [])
            messageLabel.text = "Don't have an account?"
            changeSignupModeButton.setTitle("Sign Up", for: [])
            
        } else {
            signupOrLoginButton.setTitle("Sign Up", for: [])
            messageLabel.text = "Already have an account?"
            changeSignupModeButton.setTitle("Log In", for: [])
        }
        signupMode = !signupMode
    } //end function changeSignupMode
    
    func startSpinner(){
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
    }  //End startSpinner
    
    func stopSpinner(){
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func createAlert(title: String, message: String ) {
        //creat alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //add button to alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert

    
    @IBAction func signupOrLogin(_ sender: Any) {
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            
            createAlert(title: "Error in form", message: "Please enter both username and password")
            
        } else {    //Signup Mode
            startSpinner()
            if signupMode {  //signup Mode
                // Save user in Parse
                let user = PFUser()
                user.password = passwordTextField.text
                user["isDriver"] = isDriverSwitch.isOn
                user["appName"] = "uberClone"
                
                //Append "Driver" or "Rider" to username
                if isDriverSwitch.isOn {
                    user.username = "Driver-" + emailTextField.text!
                } else {
                    user.username = "Rider-" + emailTextField.text!
                }
                
                print("== username, password & isDriver ==", user.username, user.password, user["isDriver"])
                
                
                //Let public write to User field (ACL)
                let acl = PFACL()
                acl.getPublicWriteAccess = true
                user.acl = acl
                
                
                user.signUpInBackground { (success, error) -> Void in
                    self.stopSpinner()
                    if success {
                        print("New user \(user.username!) saved")
                        
                        if self.isDriverSwitch.isOn {
                            
                            self.performSegue(withIdentifier: "showActiveRideRequests", sender: self)
                            
                        } else {
                            self.performSegue(withIdentifier: "showRiderMap", sender: self)
                        }
                        
                        
                        return
                        
                    } else {
                        if error != nil {
                            print("Error saving user")
                            var displayErrorMessage = "Please try again later ..."
                            if let errorMessage = error as NSError? {
                                displayErrorMessage = errorMessage.userInfo["error"] as! String
                            }
                            print("== Signup Error Alert ==", displayErrorMessage)
                            self.createAlert(title: "Signup Error", message: displayErrorMessage)
                        }
                        return
                    }
                }
            } else {    // Login mode
                
                //append Driver or Rider to username
                var loginName: String
                
                if isDriverSwitch.isOn {
                    
                    loginName = "Driver-" + emailTextField.text!
                
                } else {
                    
                    loginName = "Rider-" + emailTextField.text!
                }
                
                PFUser.logInWithUsername(inBackground: loginName, password: passwordTextField.text!, block: { (user, error) in
                    self.stopSpinner()
                    
                    if error != nil {
                        print("== Error logging in existing user  ", user?.username, error)
                        var displayErrorMessage = "Please try again later ..."
                        if let errorMessage = error as NSError? {
                            displayErrorMessage = errorMessage.userInfo["error"] as! String
                        }
                        print("== Alert ==", displayErrorMessage)
                        
                        //Comment out createAlert to avoid login bug
                            self.createAlert(title: "Login Error(s)", message: displayErrorMessage)
                        return
                        
                    } else if self.isDriverSwitch.isOn {
                        self.performSegue(withIdentifier: "showActiveRideRequests", sender: self)

                        
                    } else {
                        
                        self.performSegue(withIdentifier: "showRiderMap", sender: self)
                    }
                    return
                    
                })
            }
        }
        
    } //end func signupOrLogin
    
    

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
