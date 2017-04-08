
//
//  HouseLoginViewController.swift
//  roomy
//
//  Created by Poojan Dave on 3/18/17.
//  Copyright © 2017 Poojan Dave. All rights reserved.
//

import UIKit
import Parse


// Add an alert to let the user know that their houseID is not found


// HouseLoginViewController: Logs the user into a house and authenitcates their username and password
class HouseLoginViewController: UIViewController {
    
    @IBOutlet weak var houseIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        houseIDTextField.becomeFirstResponder()
    }


    // logInButtonPressed Action: 
    // Extract the houseID and password
    // Creates a query that retrieves the House based upon "houseID"
    // The query returns an array of PFObjects, we confirm houses are not nil, 
    // then we have a for loop where we traverse each house and confirm that each houseID equals the houseID the user entered
    // If the houseID is a match, we then look to see if the password is a match
    // Then, upon authentication, we set the current house to the authenticaed house
    // update the House["userIDs"] and the PFUser["HouseID"]
    // Finally we segue
    @IBAction func logInButtonPressed(_ sender: Any) {
        
        // Extract the proper values
        let houseID = houseIDTextField.text!
        let password = passwordTextField.text!
        
        // Makes the query and specifies the class
        let query = PFQuery(className: "House")
        // orders the houses where the houseID mataches the key
        query.whereKey("houseID", equalTo: houseID)
        
        // send query through built-in Parse method
        // Returns the an array of Houses as PFObjects
        query.findObjectsInBackground { (housesReturned: [PFObject]?, error: Error?) in
            
            print(housesReturned?.count ?? "housesReturned.count failed")
            
            // If houses are not nil
            if let houses = housesReturned {
                
                // Go through each house
                for house in houses {
                    
                    // if houseID entered matches houseID in database
                    if house["houseID"] as? String == houseID {
                        
                        print("HouseID match")
                        
                        // If password entered matches the password of the House object
                        if house["password"] as? String == password {

                            print("Password match")

                            // Extract the userIDs array from current house
                            var userIDs = house["userIDs"] as! [PFUser]
                            // Add the current user
                            userIDs.append(PFUser.current()!)
                            // update the house object
                            house["userIDs"] = userIDs
                            house.saveInBackground()
                            
                            // Update the HouseID in the current user
                            PFUser.current()?["house"] = house
                            PFUser.current()?.saveInBackground()
                            
                            // Sets the curret house
                            House.setCurrentHouse(house: house)
                            
                            // Segues to the tabBar
                            self.performSegue(withIdentifier: "houseLoginToTabBar", sender: nil)
                            
                        // If houseID matches, but the password doesn't
                        } else {
                            print("Password failed")
                        }
                        
                    // If more than one house with same ID (Checking if query is returning more than 1 house)
                    } else {
                        print("HouseID failed")
                    }
                }
                
            // Error
            } else {
                print("HouseLoginViewController/logInButtonPressed() Error: \(String(describing: error?.localizedDescription))")
            }
            
        }

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

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