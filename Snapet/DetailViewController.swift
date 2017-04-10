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
    
    @IBAction func dateFieldEditing(_ sender: UITextField) {
        let datePickerView:UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.date
        
        sender.inputView = datePickerView
        
        datePickerView.addTarget(self, action: #selector(DetailViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }

    
    func datePickerValueChanged(sender:UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        
        dateFormatter.timeStyle = DateFormatter.Style.none
        
        dateField.text = dateFormatter.string(from: sender.date)
    }
    
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
        accountField.text = nil
        dateField.text = nil
        print("date is nil now")
        merchantField.text = nil
        categoryField.text = nil
        amountField.text = nil
    }
    
    func donePressed(_ sender: UIBarButtonItem) {
        
        dateField.resignFirstResponder()
        
    }
    
    func tappedToolBarBtn(_ sender: UIBarButtonItem) {
        
        let dateformatter = DateFormatter()
        
        dateformatter.dateStyle = DateFormatter.Style.medium
        
        dateformatter.timeStyle = DateFormatter.Style.none
        
        dateField.text = dateformatter.string(from: Date())
        
        dateField.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        amountField.resignFirstResponder()
        merchantField.resignFirstResponder()
        accountField.resignFirstResponder()
        dateField.resignFirstResponder()
        categoryField.resignFirstResponder()
        if let temp = amountField.text{
            if (temp.characters.count > 0) {
                amount = Double(temp)!
            }
        }
        if let temp = merchantField.text{
            merchant = temp
            if (temp.characters.count > 0) {
                merchant = temp
            }
        }
        if let temp = accountField.text{
            if (temp.characters.count > 0) {
                account = Int(temp)!
            }
        }
        if let temp = dateField.text{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            if (temp.characters.count >= 11) {
                date = dateFormatter.date(from: temp)
            }
//            dateFormatter.dateFormat = "yyyy-MM-dd"
//            var d: Date
//            if (temp.characters.count >= 10) {
//                let temp1 = temp.substring(to: temp.index((temp.startIndex), offsetBy: 10))
//                d = dateFormatter.date(from:temp1)!
//                let calendar = Calendar.current
//                let components = calendar.dateComponents([.year, .month, .day], from: d)
//                let finalDate = calendar.date(from:components)
//                date = finalDate
//            }
        }
        if let temp = categoryField.text {
            category = temp
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.blackTranslucent
        toolBar.tintColor = UIColor.white
        toolBar.backgroundColor = UIColor.black
        let todayBtn = UIBarButtonItem(title: "Today", style: UIBarButtonItemStyle.plain, target: self, action: #selector(DetailViewController.tappedToolBarBtn))
        let okBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(DetailViewController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        label.font = UIFont(name: "Helvetica", size: 12)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = "Select a due date"
        label.textAlignment = NSTextAlignment.center
        let textBtn = UIBarButtonItem(customView: label)
        toolBar.setItems([todayBtn,flexSpace,textBtn,flexSpace,okBarBtn], animated: true)
        dateField.inputAccessoryView = toolBar
        
        amountField.text = String(amount)
        dateField.text = date?.description
        merchantField.text = merchant
        accountField.text = String(account)
        categoryField.text = category
        amountField.delegate = self
        dateField.delegate = self
        merchantField.delegate = self
        accountField.delegate = self
        categoryField.delegate = self
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
