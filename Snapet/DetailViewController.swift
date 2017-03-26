//
//  DetailViewController.swift
//  Snapet
//
//  Created by Duan Li on 3/26/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var merchantField: UITextField!
    @IBOutlet weak var accountField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    
    var amount = 2.0
    var merchant = ""
    var account = ""
    var date = "2017-01-27"
    var category = "Food"
    var expenses: [NSManagedObject] = []
    var savedAmount = Float(-1.0)
    var fetchedAmount = Float(-1.0)
    
    @IBAction func saveData(_ sender: Any) {
        let amountToSave = amount
        self.save(amount: Float(amountToSave))
    }
    /*
     Saving to Core Data
     */
    func save(amount: Float) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Expense",
                                       in: managedContext)!
        
        let expense = NSManagedObject(entity: entity,
                                      insertInto: managedContext)
        
        // 3
        expense.setValue(amount, forKeyPath: "amount")
        
        // 4
        do {
            try managedContext.save()
            expenses.append(expense)
            savedAmount = (expense.value(forKeyPath: "amount") as? Float)!
            print("saved amount = \(savedAmount)")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
