/**
* Copyright (c) 2015-present, Parse, LLC.
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
    
    var signupMode = true
    
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
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            print("=== Alert OK pressed")
            self.dismiss(animated: true, completion: nil)
            return
            
        }))
        
        //present alert
        self.present(alert, animated: true, completion: nil)
    }  //End createAlert

    
    @IBAction func signupOrLogin(_ sender: Any) {
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            
            createAlert(title: "Error in form", message: "Please enter both username and password")
            
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
