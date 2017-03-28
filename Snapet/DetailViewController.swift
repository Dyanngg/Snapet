//
//  DetailViewController.swift
//  Snapet
//
//  Created by Duan Li on 3/26/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var merchantField: UITextField!
    @IBOutlet weak var accountField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    
    var amount: Double = 0.0
    var merchant = ""
    var account = 0
    var date: Date? = nil
    var category = ""
    var expenses: [NSManagedObject] = []
//    var savedAmount = Double(-1.0)
//    var savedDate: Date? = nil
//    var savedMerchant = ""
    
    @IBAction func saveData(_ sender: Any) {
        let amountToSave = amount
        self.save(amount: Double(amountToSave))
    }
    /*
     Saving to Core Data
     */
    func save(amount: Double) {
        
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
        if (date != nil) {
            expense.setValue(date, forKeyPath: "date")
        }
        if (merchant != "") {
            expense.setValue(merchant, forKeyPath: "merchant")
        }
        if (account != 0) {
            expense.setValue(account, forKeyPath: "account")
        }
        if (category != "") {
            expense.setValue(category, forKeyPath: "category")
        }
        
        // 4
        do {
            try managedContext.save()
            expenses.append(expense)
//            savedAmount = (expense.value(forKeyPath: "amount") as? Double)!
//            print("saved amount = \(savedAmount)")
//            if (date != nil) {
//                savedDate = (expense.value(forKeyPath: "date") as? Date)!
//                print("saved date = \(savedDate)")
//            }
//            if (merchant != nil) {
//                savedMerchant = (expense.value(forKeyPath: "merchant") as? String)!
//                print("saved merchant = \(savedMerchant)")
//            }
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        amountField.resignFirstResponder()
        merchantField.resignFirstResponder()
        accountField.resignFirstResponder()
        dateField.resignFirstResponder()
        categoryField.resignFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        amountField.resignFirstResponder()
        merchantField.resignFirstResponder()
        accountField.resignFirstResponder()
        dateField.resignFirstResponder()
        categoryField.resignFirstResponder()
        if let temp = amountField.text{
            amount = Double(temp)!
        }
        if let temp = merchantField.text{
            merchant = temp
        }
        if let temp = accountField.text{
            account = Int(temp)!
        }
        if let temp = dateField.text{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let d = dateFormatter.date(from:temp)!
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: d)
            let finalDate = calendar.date(from:components)
            date = finalDate
        }
        if let temp = categoryField.text {
            category = temp
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        amountField.delegate = self
        dateField.delegate = self
        merchantField.delegate = self
        accountField.delegate = self
        categoryField.delegate = self
        amountField.text = String(amount)
        dateField.text = date?.description
        merchantField.text = merchant
        accountField.text = String(account)
        categoryField.text = category
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
