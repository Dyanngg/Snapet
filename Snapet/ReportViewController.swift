//
//  ReportViewController.swift
//  Snapet
//
//  Created by Duan Li on 4/23/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData

extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

class ReportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,UISearchResultsUpdating, UISearchControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var expenses: [NSManagedObject] = []
    var filtered: [NSManagedObject] = []
    
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
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive : Bool = false
    var addNewData = true
    var row = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 84;
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        // I REALLY WANT TO CHANGE THIS TO MINIMAL BUT IT DOESN'T WORK
        searchController.searchBar.searchBarStyle = UISearchBarStyle.default
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        
        // Setup the Scope Bar
        let barColor = UIColor(red:87/255, green:97/255, blue:112/255, alpha:1.0)
        let opaqueBarColor = UIColor(red:100/255, green:107/255, blue:118/255, alpha:1.0)
        let backgroundColor = UIColor(red:72/255, green:81/255, blue:94/255, alpha:1.0)
        searchController.searchBar.scopeButtonTitles = ["All", ">", "=", "<", "↑", "↓"]
        searchController.searchBar.barTintColor = opaqueBarColor
        let searchTextField = searchController.searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = backgroundColor
        searchTextField?.textColor = UIColor.white
        searchController.searchBar.tintColor = UIColor.white
        definesPresentationContext = true
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar

        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        self.navigationController?.navigationBar.barTintColor = barColor
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AppleGothic", size: 20)!]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /*****   Table View Stuff  ******/
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filtered.count
        }
        return expenses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let expense: NSManagedObject
        if searchController.isActive && searchController.searchBar.text != "" {
            expense = filtered[indexPath.row]
        } else {
            expense = expenses[indexPath.row]
        }
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "newCell", for: indexPath)
        let cell = dequeued as! ReportTableViewCell
        
        let amountLabel = expense.value(forKeyPath: "amount") as? Double
        let dateLabel = expense.value(forKeyPath: "date") as? Date
        let categoryLabel = expense.value(forKeyPath: "category") as? String
        let merchantLabel = expense.value(forKeyPath: "merchant") as? String
        if (categoryLabel != nil) {
            cell.categoryLabel?.text = categoryLabel
        }
        if (merchantLabel != nil) {
            cell.merchantLabel?.text = merchantLabel
        }
        if (amountLabel != nil) {
            cell.amountLabel?.text = "$\(String(amountLabel!))"
        }
        if (dateLabel != nil) {
            let date = dateLabel!.description
            cell.dateLabel?.text = date.substring(to: date.index(date.startIndex, offsetBy: 10))
        }
        cell.backgroundColor = UIColor.clear
        cell.backgroundView = UIImageView(image: UIImage(named: "cellDesign.png")!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        row = indexPath.row
        addNewData = false
        self.performSegue(withIdentifier: "ReportToDetail", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let merchant = expenses[indexPath.row].value(forKey: "merchant")
            let amt = expenses[indexPath.row].value(forKey: "amount")
            let cat = expenses[indexPath.row].value(forKey: "category")
            let dat = expenses[indexPath.row].value(forKey: "date")
            // delete local data
            expenses.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // delete core data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
            req.predicate = NSPredicate(format: "merchant == %@ AND amount = %@ AND category = %@ AND date = %@", merchant as! CVarArg, amt as! CVarArg, cat as! CVarArg, dat as! Date as CVarArg)
            let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: req)
            do {
                try managedContext.execute(DelAllReqVar)
            }
            catch {
                print(error)
            }
            // reload table view
            viewWillAppear(true)
        }
    }

    /****     Fetching from Core Data   ****/
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("will appear")
        
        // 1 set context
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2 send query requests
        
        // 2.1 all data request
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        
        // 2.2 distinct categories request
        let distinctCategoryReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
        distinctCategoryReq.propertiesToFetch = ["category"]
        distinctCategoryReq.returnsDistinctResults = true
        distinctCategoryReq.resultType = NSFetchRequestResultType.dictionaryResultType
        
        // 2.3 category query request
        let categoryRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        if searchActive {
            let searchText = searchController.searchBar.text
            categoryRequest.predicate = NSPredicate(format: "category CONTAINS[c] %@ OR merchant CONTAINS[c] %@" , searchText!, searchText!)
        }
        
        // 3 fetch core data based on request
        
        // 3.1 fetch all data
        if (searchActive) {
            do {
                expenses = try managedContext.fetch(categoryRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        } else {
        do {
            expenses = try managedContext.fetch(fetchRequest)
            if !expenses.isEmpty{
                let expense = expenses[expenses.count - 1]
                fetchedAmount = (expense.value(forKeyPath: "amount") as? Double)!
                print("fetched amount = \(fetchedAmount)")
                fetchedDate = (expense.value(forKeyPath: "date") as? Date)
                if (fetchedDate != nil) {
                    print("fetched Date = \(String(describing: fetchedDate))")
                }
                fetchedAccount = (expense.value(forKeyPath: "account") as? Int)
                fetchedMerchant = (expense.value(forKeyPath: "merchant") as? String)
                fetchedCategory = (expense.value(forKeyPath: "category") as? String)
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        }
        self.tableView.reloadData()
    }

    
    func DeleteAllData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Expense"))
        do {
            try managedContext.execute(DelAllReqVar)
        }
        catch {
            print(error)
        }
    }
    
    /*********** Search Bar **************/
    
    func didPresentSearchController(_ resultSearchController: UISearchController) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
        
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
//        if (scope == "Category") {
//            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
//                let category = (expense.value(forKeyPath: "category") as? String)
//                return category!.lowercased().contains(searchText.lowercased())
//            })
//        } else if (scope == "Merchant") {
//            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
//                let merchant = (expense.value(forKeyPath: "merchant") as? String)
//                return merchant!.lowercased().contains(searchText.lowercased())
//            })
//        } else
        if (scope == ">") {
            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
                var result = false
                if let amount = (expense.value(forKeyPath: "amount") as? Double) {
                if let amountEntered = searchText.toDouble() {
                    if (amount > amountEntered) {
                        result = true
                    }
                }
                }
                return result
            })
        } else if (scope == "=") {
            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
                var result = false
                if let amount = (expense.value(forKeyPath: "amount") as? Double) {
                if let amountEntered = searchText.toDouble() {
                    if (amount == amountEntered) {
                        result = true
                    }
                }
                }
                return result
            })
        } else if (scope == "<") {
            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
                var result = false
                if let amount = (expense.value(forKeyPath: "amount") as? Double) {
                if let amountEntered = searchText.toDouble() {
                    if (amount < amountEntered) {
                        result = true
                    }
                }
                }
                return result
            })
        } else if (scope == "↑" || scope == "↓") {
            let searchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Expense")
            var order = true
            if scope == "↓" {
                order = false
            }
            let sort: NSSortDescriptor
            if (searchText.lowercased().contains("merchant")) {
                sort = NSSortDescriptor(key: "merchant", ascending: order)
            } else if (searchText.lowercased().contains("category")) {
                sort = NSSortDescriptor(key: "category", ascending: order)
            } else if (searchText.lowercased().contains("amount")) {
                sort = NSSortDescriptor(key: "amount", ascending: order)
            } else { // default sort descriptor is date
                sort = NSSortDescriptor(key: "date", ascending: order)
            }
            searchRequest.sortDescriptors = [sort]
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let managedContext =
                appDelegate.persistentContainer.viewContext
            do {
                filtered = try managedContext.fetch(searchRequest)
                print("expenses: \(expenses)")
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        } else {
            filtered = expenses.filter({(expense: NSManagedObject) -> Bool in
                var categoryMatch = false
                var merchantMatch = false
                var amountMatch = false
                var dateMatch = false
                if let category = (expense.value(forKeyPath: "category") as? String) {
                    categoryMatch = category.lowercased().contains(searchText.lowercased())
                }
                if let merchant = (expense.value(forKeyPath: "merchant") as? String) {
                    merchantMatch = merchant.lowercased().contains(searchText.lowercased())
                }
                if let amount = (expense.value(forKeyPath: "amount") as? Double) {
                    amountMatch = amount.description.contains(searchText)
                }
                if let date = (expense.value(forKeyPath: "date") as? Date) {
                    dateMatch = date.description.contains(searchText)
                }
                return categoryMatch || merchantMatch || amountMatch || dateMatch
            })
        }
        tableView.reloadData()
    }
    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ReportToDetail"{
            if !addNewData {
                let secondViewController = segue.destination as! DetailViewController
                let expense: NSManagedObject
                if searchController.isActive && searchController.searchBar.text != "" {
                    expense = filtered[row]
                } else {
                    expense = expenses[row]
                }
                if let amount = (expense.value(forKeyPath: "amount") as? Double) {
                    secondViewController.amount = amount
                }
                if let date = (expense.value(forKeyPath: "date") as? Date) {
                    secondViewController.date = date
                }
                if let merchant = (expense.value(forKeyPath: "merchant") as? String) {
                    secondViewController.merchant = merchant
                }
                if let category = (expense.value(forKeyPath: "category") as? String) {
                    secondViewController.category = category
                }
                secondViewController.isEdit = true
                secondViewController.row = row
                if searchController.isActive && searchController.searchBar.text != "" {
                    secondViewController.expenses = filtered
                } else {
                    secondViewController.expenses = expenses
                }
                addNewData = true
            }
        }
    }

    // display the constraints obtained from setting page
    @IBAction func myUnwindAction(_ unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.source as? DetailViewController {
            if !svc.isEdit {
                expenses = svc.expenses
            }
            print("expenses is assigned")
        }
    }
}
