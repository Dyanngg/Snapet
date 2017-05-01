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
    
    @IBOutlet weak var homeCell: UITableViewCell!
    @IBOutlet weak var historyCell: UITableViewCell!
    @IBOutlet weak var settingsCell: UITableViewCell!
    
    
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
                let img = UIImage(data: photoinData)!
                profileImage.maskCircle(anyImage: img)
//                profileImage.image = UIImage(data: photoinData)
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
        let avatarImage:UIImage = UIImage(named: "blank-user")!
        profileImage.maskCircle(anyImage: avatarImage)
        fetchAndDisplay()
        
        self.navigationController?.isNavigationBarHidden =  true
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = Palette.statusbarColor

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        selectedCell.contentView.backgroundColor = Palette.selectedMenuColor
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        selectedCell.contentView.backgroundColor = Palette.menuColor
    }
    
    

}
