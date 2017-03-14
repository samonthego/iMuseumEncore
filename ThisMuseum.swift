//
//  ThisMuseum.swift
//  iMuseumEncore
//
//  Created by Samuel MCDONALD on 3/12/17.
//  Copyright © 2017 Samuel MCDONALD. All rights reserved.
//

//
//  thisMuseum.swift
//  iMueseum
//
//  Created by Samuel MCDONALD on 2/25/17.
//  Copyright © 2017 Samuel MCDONALD. All rights reserved.
//

import UIKit

class ThisMuseum: UITableViewCell {
    
    /*
    @IBOutlet var showMuseum    :UILabel!
    @IBOutlet var showAddress   :UILabel!
    @IBOutlet var showCity      :UILabel!
    @IBOutlet var showStateZip  :UILabel!
    */
 
    
    var name:String = ""
    var address:String = ""
    //var locationCity:String = ""
    //var locationStateZip:String = ""

    
    var lat:Double = 0.0
    var long:Double = 0.0
    
}


extension ThisMuseum{
    
    convenience init(name:String, address: String, lat:Double, long:Double ){
        self.init()
        
        self.name = name
        self.address = address
        //self.locationCity = locationCity
        //self.locationStateZip = locationStateZip
        self.lat = lat
        self.long = long
        
    }
}
