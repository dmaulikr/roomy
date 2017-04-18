//
//  HomeViewController.swift
//  roomy
//
//  Created by Ryan Liszewski on 4/4/17.
//  Copyright © 2017 Poojan Dave. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery
import MBProgressHUD

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let locationManager = CLLocationManager()
    
    @IBOutlet weak var homeTableView: UITableView!

    var region: CLCircularRegion!
    
    var roomiesHome: [Roomy]? = []
    var roomiesNotHome: [Roomy]? = []
    var roomies: [Roomy]? = []
    var hud = MBProgressHUD()
    
    private var subscription: Subscription<Roomy>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        LocationService.shared.setUpHouseFence()
        LocationService.shared.isRoomyHome()
        
        homeTableView.dataSource = self
        homeTableView.delegate = self
        homeTableView.sizeToFit()
        
        addRoomiesToHome()
        let roomyQuery = getRoomyQuery()
        subscription = ParseLiveQuery.Client.shared.subscribe(roomyQuery).handle(Event.updated) { (query, roomy) in
            self.roomyChangedHomeStatus(roomy: roomy)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        showProgressHud()
        updateRoomies()
    }
    
    //Logout button for test purposeses.
    @IBAction func onLogoutButtonTapped(_ sender: Any) {
        
        PFUser.logOutInBackground { (error: Error?) in
            if error == nil {
                House._currentHouse = nil
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let loginViewController = mainStoryboard.instantiateViewController(withIdentifier: "UserLoginViewController") as! UserLoginViewController
                self.present(loginViewController, animated: true, completion: nil)
            }
        }
    }
    
    func showProgressHud(){
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.indeterminate
        hud.animationType = .zoomIn
    }
    
    func reloadTableView(){
        hud.hide(animated: true, afterDelay: 1)
        homeTableView.reloadData()
    }
    
    func hideProgressHud(){
        hud.hide(animated: true, afterDelay: 1)
    }
    
    //MARK: TABLE VIEW FUNCTIONS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.Identifier.Cell.homeTableViewCell, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath){
        
        guard let tableViewCell = cell as? RoomyTableViewCell else {return}
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30))
        
        let homeTextLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        homeTextLabel.adjustsFontSizeToFitWidth = true
        
        if(section == 0){
            homeTextLabel.text = R.Header.home
        } else {
            homeTextLabel.text = R.Header.notHome
        }
        headerView.addSubview(homeTextLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    //MARK: PARSE QUERYING TO GET ROOMIES
    
    func getRoomyQuery() -> PFQuery<Roomy>{
    
        let query: PFQuery<Roomy> = PFQuery(className: "_User")
        query.whereKey("house", equalTo: House._currentHouse!)
        
        do {
            let roomies = try query.findObjects()
            self.roomies = roomies
        } catch let error as Error? {
            print(error?.localizedDescription ?? "ERROR")
        }
        return query
    }
    
    func addRoomiesToHome() {
        addCurrentRoomyToHome()
        for roomy in self.roomies! {
            if(roomy.objectId != Roomy.current()?.objectId){
                if(self.checkIfRoomyIsHome(roomy: roomy)){
                    self.roomiesHome?.append(roomy)
                } else {
                    
                    self.roomiesNotHome?.append(roomy)
                }
            }
        }
        hideProgressHud()
        print(roomiesNotHome!.count)
        self.homeTableView.reloadData()
    }
    
    func addCurrentRoomyToHome(){
        print(Roomy.current()?["is_home"])
        if(checkIfRoomyIsHome(roomy: Roomy.current()!)){
            roomiesHome?.append(Roomy.current()!)
        }else {
            roomiesNotHome?.append(Roomy.current()!)
        }
        homeTableView.reloadData()
    }

    func checkIfRoomyIsHome(roomy: Roomy) -> Bool{
        return roomy["is_home"] as! Bool
    }
    
    func updateRoomies(){
        roomiesHome = []
        roomiesNotHome = []
        for roomy in self.roomies! {
            do {
                try roomy.fetch()
            } catch let error as Error? {
                print(error?.localizedDescription ?? "ERROR")
            }
        }
        addRoomiesToHome()
    }
    
    func roomyChangedHomeStatus(roomy: Roomy){
        let isRoomyHome = roomy["is_home"] as! Bool
        
        if(isRoomyHome){
            roomiesNotHome = roomiesNotHome?.filter({$0.username != roomy.username})
            roomiesHome?.append(roomy)
        } else {
            roomiesHome = roomiesHome?.filter({$0.username != roomy.username})
            roomiesNotHome?.append(roomy)
        }
        reloadTableView()
    }
    
    @IBAction func onDirectionsHomeButtonTapped(_ sender: Any) {
        
        
        //LocationService.shared.locationManager.location
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            UIApplication.shared.openURL(URL(string:
                "comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic")!)
        } else {
            print("Can't use comgooglemaps://");
        }
        
        
    }
    
    
    
    
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return (roomiesHome?.count)!
        } else {
            return roomiesNotHome!.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.Identifier.Cell.homeCollectionViewCell, for: indexPath) as! RoomyCollectionViewCell
        
        if(collectionView.tag == 0) {
            cell.roomyUserNameLabel.text = roomiesHome?[indexPath.row].username
        } else {
            cell.roomyUserNameLabel.text = roomiesNotHome?[indexPath.row].username
        }
        return cell
    }
}
