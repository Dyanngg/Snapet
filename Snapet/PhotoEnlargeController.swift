//
//  PhotoEnlargeController.swift
//  Snapet
//
//  Created by Yang Ding on 5/1/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import Foundation
import UIKit

class PhotoEnlargeController: UIViewController {
    
    var photo: UIImage?
    @IBOutlet weak var imageView: UIImageView!
    
    // Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        if let photo = photo {
            imageView.image = photo
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
