//
//  MainPageController.swift
//  Snapet
//
//  Created by Yang Ding on 4/16/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import MobileCoreServices
import KCFloatingActionButton


// helper extension for string manipulation
extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

class MainPageController: UIViewController, UITableViewDelegate, UITableViewDataSource, KCFloatingActionButtonDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var fab = KCFloatingActionButton()
    
    var expenses: [NSManagedObject] = []
    
    var fetchedAmount = Double(-1.0)
    var fetchedDate: Date? = nil
    var fetchedAccount: Int? = nil
    var fetchedMerchant: String? = nil
    var fetchedCategory: String? = nil
    
    var detectedAmount: Double? = nil
    var detectedDate: Date? = nil
    var detectedMerchant: String? = nil
    var detectedCategory: String? = nil
    var detectedAccount: Int? = nil
    
    var useCamera = false
    
    let session = URLSession.shared
    let imagePicker = UIImagePickerController()
    let googleAPIKey = "AIzaSyBmcPFpapjEug_lKki4qnuiN-XYvE3xVYQ"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    let googleKGURL = "https://kgsearch.googleapis.com/v1/entities:search"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the floating action button
        // layoutFAB()
        
        // DeleteAllData()
        // imagePicker.delegate = self

        //self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    /*****   Table View Stuff  ******/
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("printing expenses: ")
        print(expenses)
        let expense = expenses[indexPath.row]
        print("printing expense: ")
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let cell = dequeued as! ExpenseTableViewCell
        let amountLabel = expense.value(forKeyPath: "amount") as? Double
        let dateLabel = expense.value(forKeyPath: "date") as? Date
        let categoryLabel = expense.value(forKeyPath: "category") as? String
        let merchantLabel = expense.value(forKeyPath: "merchant") as? String
        if (categoryLabel != nil) {
            cell.categoryLabel?.text = categoryLabel
        }
        if (merchantLabel != nil) {
            cell.merchantLabel.text = merchantLabel
        }
        if (amountLabel != nil) {
            cell.amountLabel?.text = "$\(String(amountLabel!))"
        }
        if (dateLabel != nil) {
            let date = dateLabel!.description
            cell.dateLabel?.text = date.substring(to: date.index(date.startIndex, offsetBy: 10))
        }
        return cell
    }
    
    
    
    /****   Floating action button stuff  ****/
    func layoutFAB() {
        let item = KCFloatingActionButtonItem()
        item.buttonColor = UIColor.blue
        item.circleShadowColor = UIColor.black
        item.titleShadowColor = UIColor.yellow
        item.title = "Custom item"
        
        fab.addItem(item: item)
        fab.fabDelegate = self
        fab.sticky = true
        
        self.view.addSubview(fab)
    }


    
}
