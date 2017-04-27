//
//  MenuController.swift
//  SidebarMenu
//
//  Created by Simon Ng on 2/2/15.
//  Copyright (c) 2015 AppCoda. All rights reserved.
//

import UIKit
import CoreData

extension UIImageView {
    public func maskCircle(anyImage: UIImage) {
        self.contentMode = UIViewContentMode.scaleAspectFill
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        // make square(* must to make circle),
        // resize(reduce the kilobyte) and
        // fix rotation.
        self.image = anyImage
    }
}

class MenuController: UITableViewController {
    
    @IBOutlet weak var profileImage: UIImageView!
    var images: [NSManagedObject] = []
    
    func fetchAndDisplay() {
        // fetch image from core data and display it
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "User")
        do {
            images = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        if !images.isEmpty {
            if let photoinData = images[images.count - 1].value(forKey: "image") as? Data{
                profileImage.image = UIImage(data: photoinData)
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchAndDisplay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        let avatarImage:UIImage = UIImage(named: "testProfile")!
//        profileImage.maskCircle(anyImage: avatarImage)
        fetchAndDisplay()
        
        self.navigationController?.isNavigationBarHidden =  true
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        let statusbarColor = UIColor(red:99/255, green:106/255, blue:118/255, alpha:1.0)
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = statusbarColor

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
