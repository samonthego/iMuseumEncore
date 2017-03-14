//
//  ViewController.swift
//  iMueseum
//
//  Created by Samuel MCDONALD on 2/12/17.
//  Copyright © 2017 Samuel MCDONALD. All rights reserved.
//
import UIKit
import MapKit

class MyPointAnnotation: MKPointAnnotation{
    
    var pinIndex :Int!
    
}


class ViewController: UIViewController,MKMapViewDelegate{
   // class ViewController: UIViewController,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource{
    var allMuseums = [ThisMuseum]()
    var mySearchString:String = ""
    
    
    //@IBOutlet var tableView    :UITableView!
    @IBOutlet var museMap        :MKMapView!
    let hostName = "itunes.apple.com/"
    var reachability : Reachability?
    
    @IBOutlet var networkStatusLabel :UILabel!
    
    
    
    /*@IBAction func myArtistPick(_ sender: UITextField) {
     guard let textFieldString = myMuseum.text else {
     return
     }
     
     
     
     let myMuseumString = textFieldString.replacingOccurrences(of: " ", with: "+")
     print("\(myMuseumString)")
     mySearchString = "/search?term=\(myMuseumString)"
     print("mySearchString \(mySearchString)")
     }*/
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - Core Methods
    
    func parseJson(data: Data){
        do {
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String:Any]]
            // print ("JSON:\(jsonResult)")
            
            for resultsDict in jsonResult {
                
                //  print ("Results:\(resultsDict)")
                let name =    resultsDict["legalname"] as? String ?? "no museum name"
                let address = resultsDict["location_1_address"] as? String ?? "no street address"
                let city =    resultsDict["location_1_city"] as? String ?? "no city"
                let state =   resultsDict["location_1_state"] as? String ?? "no state"
                let zip =     resultsDict["location_1_zip"] as? String ?? "no Zip"
                
                let addr = address + ", " + city + ", " + state + ", " + zip
                var locLong = 0.0
                var locLat = 0.0
                
                if let nestedDictionary = resultsDict["location_1"] as? [String: Any] {
                    // access nested dictionary values by key
                    let coord = nestedDictionary["coordinates"] as? [Double] ?? [0.0,0.0]
                    locLat = coord[1]
                    locLong = coord[0]
                }
                
                let stateZip = state + ", " + zip
                
                print("\(name)")
                print("        \(address)")
                print("        \(city)")
                print("        \(stateZip)")
                print("        \(locLat),\(locLong)")
                
                let newThisMuseum = ThisMuseum(name: name, address: addr, lat: locLat, long: locLong)
                
                allMuseums.append(newThisMuseum)
                let index = allMuseums.index(of: newThisMuseum)!
                museMap.addAnnotation(pinFor(loc: newThisMuseum, index : index))            }
            
        }catch { print("JSON Parsing Error")}
        print("Here!")
        //allMuseums.sort{$0.locationStateZip < $1.locationStateZip}
        DispatchQueue.main.async {
            // need to write a function to sort in the class
            // for equivalence? ==
            //allMuseums.sort()
           // self.tableView.reloadData()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.annotateMapLocations()
        }
    }
    
    
    
    func getFile(){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        //let urlString = "https://\(hostName)\(filename)"
        let urlString = "https://data.imls.gov/resource/et8i-mnha.json"
        let url = URL(string: urlString)!
        var request = URLRequest(url:url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let recvData = data else {
                print("No Data")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            if recvData.count > 0 && error == nil {
                //print("Got Data:\(recvData)")
                //print("Got Data!")
                let dataString = String.init(data: recvData, encoding: .utf8)
                print("Got Data String:\(dataString)")
                self.parseJson(data: recvData)
            }else{
                print("Got Data of Length 0")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
        task.resume()
    }
    
    
    //MARK: - Geocoding Methods
    
    func addLocAndPinFor(placemarks: [CLPlacemark]?, title: String){
        guard let placemarks = placemarks, let placemark = placemarks.first else { return }
        let city = placemark.locality
        let state = placemark.administrativeArea
        let address = placemark.subThoroughfare! + " " + placemark.thoroughfare!
        let fullAddress = "\(address), \(city!), \(state!)"
        
        let newLoc = ThisMuseum(name: title, address: fullAddress, lat: placemark.location!.coordinate.latitude, long: placemark.location!.coordinate.longitude)
        allMuseums.append(newLoc)
        let index = allMuseums.index(of: newLoc)!
        museMap.addAnnotation(pinFor(loc: newLoc, index : index))
        zoomToPins()
    }
    
    
    
    //MARK: - Map View Delegate Methods
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = .green
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)->MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as?MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation,  reuseIdentifier: "Pin")
            }
            pinView!.annotation = annotation
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .orange
            let pinButton = UIButton(type: .detailDisclosure)
            pinView!.rightCalloutAccessoryView = pinButton
            return pinView
            
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("Pressed Callout Button")
        let annotation = view.annotation as! MyPointAnnotation
        let selectedLoc = allMuseums[annotation.pinIndex]
        print("Pressed Callout Button \(selectedLoc.name)")
    }
    
    //MARK: - Map View Methods
    
    func pinFor(loc: ThisMuseum, index: Int) -> MKPointAnnotation{
        let pa = MyPointAnnotation()
        pa.pinIndex = index
        print(" setIndex \(index)")
        pa.title = loc.name
        pa.subtitle = loc.address
        pa.coordinate = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long)
        return pa
    }
    
    
    func zoomToPins() {
        museMap.showAnnotations(museMap.annotations, animated: true)
    }
    
    func zoomToLocation(lat: Double, lon: Double, radius: Double) {
        if lat == 0 && lon == 0 {
            print("Invalid Data")
        } else {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let viewRegion = MKCoordinateRegionMakeWithDistance(coord, radius, radius)
            let adjustedRegion = museMap.regionThatFits(viewRegion)
            museMap.setRegion(adjustedRegion, animated: true)
        }
    }
    
    func annotateMapLocations() {
        var pinsToRemove = [MKPointAnnotation]()
        for annotation in museMap.annotations {
            if annotation is MKPointAnnotation {
                pinsToRemove.append(annotation as! MKPointAnnotation)
            }
        }
        museMap.removeAnnotations(pinsToRemove)
        
        for(index, loc) in allMuseums.enumerated(){
            print("loc \(loc)")
            print("index \(index)")
            museMap.addAnnotation(pinFor(loc: loc, index: index))
        }
    }
    
    //MARK: - Initialize data Methods
    
    func getFileCheck(){
        guard let reach = reachability else {return}
        if reach.isReachable{
            //getFile(filename: "/classfiles/iOS_URL_Class_Get_File.txt")
            //getFile(filename: "/classfiles/flavors.json")
            getFile()
            annotateMapLocations()
        }else{
            print("Host Not Reachable. Turn on the Internet")
        }
    }
    
    
    
    //MARK: - tableView methods
/*
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("allMuseums count is \(allMuseums.count)")
        
        return allMuseums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ThisMuseum
        
        cell.showMuseum?.text = allMuseums[indexPath.row].museumName
        cell.showAddress?.text = allMuseums[indexPath.row].locationAddress
        cell.showCity?.text = allMuseums[indexPath.row].locationCity
        cell.showStateZip?.text = allMuseums[indexPath.row].locationStateZip
        
        return cell
    }
    */
    //MARK: - Reachability Methods
    
    func setupReachability(hostName: String)  {
        reachability = Reachability(hostname: hostName)
        reachability!.whenReachable = { reachability in
            DispatchQueue.main.async {
                self.updateLabel(reachable: true, reachability: reachability)
            }
            
        }
        reachability!.whenUnreachable = {reachability in
            self.updateLabel(reachable: false, reachability: reachability)        }
    }
    
    func startReachability() {
        do{
            try reachability!.startNotifier()
        }catch{
            networkStatusLabel.text = "Unable to Start Notifier"
            networkStatusLabel.textColor = .red
            return
        }
    }
    
    func updateLabel(reachable: Bool, reachability: Reachability){
        if reachable {
            if reachability.isReachableViaWiFi{
                networkStatusLabel.textColor = .green}
            else {
                networkStatusLabel.textColor = .blue
            }
        }else{
            networkStatusLabel.textColor = .red
        }
        networkStatusLabel.text = reachability.currentReachabilityString
    }
    
    //Mark: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupReachability(hostName: hostName)
        startReachability()

        getFileCheck()
        //annotateMapLocations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //setupLocationMonitoring()
        //buildArray()
        annotateMapLocations()
    }
 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
}
