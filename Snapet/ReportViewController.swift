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

class ReportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,UISearchResultsUpdating, UISearchControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var greaterButton: UIButton!
    @IBOutlet weak var equalButton: UIButton!
    @IBOutlet weak var lessButton: UIButton!
    @IBOutlet weak var ascendingButton: UIButton!
    @IBOutlet weak var descendingButton: UIButton!
    @IBOutlet weak var allDataButton: UIButton!
    
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
    
    var resultSearchController = UISearchController()
    var searchActive : Bool = false
    var addNewData = true
    var row = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 84;
        
//        greaterButton.isHidden = true
//        equalButton.isHidden = true
//        lessButton.isHidden = true
//        ascendingButton.isHidden = true
//        descendingButton.isHidden = true
//        allDataButton.isHidden = true
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        let barColor = UIColor(red:87/255, green:97/255, blue:112/255, alpha:1.0)
        self.navigationController?.navigationBar.barTintColor = barColor
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AppleGothic", size: 20)!]
        
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.hidesNavigationBarDuringPresentation = false
            controller.dimsBackgroundDuringPresentation = true
            controller.searchBar.searchBarStyle = UISearchBarStyle.minimal
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            self.tableView.tableHeaderView = controller.searchBar
            self.tableView.contentOffset = CGPoint(x: 0, y: controller.searchBar.frame.height)
            return controller
        })()
        resultSearchController.delegate = self
        resultSearchController.searchBar.delegate = self
        
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
        let expense = expenses[indexPath.row]
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
            let searchText = resultSearchController.searchBar.text
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
    
    @IBAction func displaySearchBar(_ sender: Any) {
        resultSearchController.isActive = true
        resultSearchController.searchBar.isHidden = false
    }

    func didPresentSearchController(_ resultSearchController: UISearchController) {
        searchActive = true;
//        greaterButton.isHidden = false
//        equalButton.isHidden = false
//        lessButton.isHidden = false
//        ascendingButton.isHidden = false
//        descendingButton.isHidden = false
//        allDataButton.isHidden = false
        print("BeginEditing = \(searchActive)")
    }
    
    func didDismissSearchController(_ resultSearchBar: UISearchController) {
//        searchActive = true;
        print("EndEditing = \(searchActive)")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        searchBar.endEditing(true)
        print("CancelButtonClicked = \(searchActive)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = true;
        print("SearchButtonClicked = \(searchActive)")
        searchBar.resignFirstResponder()
        
        let searchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        if (searchActive) {
            if let searchText = searchBar.text {
                if (searchText.characters.first == ">") {
                    let amount = searchText.substring(from: searchText.index((searchText.startIndex), offsetBy: 2))
                    searchRequest.predicate = NSPredicate(format: "amount > %@", amount)
                }
                else if (searchText.characters.first == "=") {
                    let amount = searchText.substring(from: searchText.index((searchText.startIndex), offsetBy: 2))
                    searchRequest.predicate = NSPredicate(format: "amount = %@", amount)
                }
                else if (searchText.characters.first == "<") {
                    let amount = searchText.substring(from: searchText.index((searchText.startIndex), offsetBy: 2))
                    searchRequest.predicate = NSPredicate(format: "amount < %@", amount)
                }
                else {
                    searchRequest.predicate = NSPredicate(format: "category CONTAINS[c] %@ OR merchant CONTAINS[c] %@", searchText, searchText)
                }
            }
        }
        
        updateTableView(searchActive, searchRequest)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        /*** TODO: Re-write this !!!! ***/
        
//        filteredData.removeAll(keepingCapacity: false)
//        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
//        let array = (tableData as NSArray).filtered(using: searchPredicate)
//        filteredData = array as! [String]
//        tableView.reloadData()
        
    }


    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ReportToDetail"{
            if !addNewData {
                let secondViewController = segue.destination as! DetailViewController
                let expense = expenses[row]
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
                secondViewController.expenses = expenses
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
    
    @IBAction func greaterAmountSearch(_ sender: Any) {
//        let searchRequest =
//            NSFetchRequest<NSManagedObject>(entityName: "Expense")
//        searchRequest.predicate = NSPredicate(format: "amount > %@", "5")
//        updateTableView(searchActive, searchRequest)
        resultSearchController.searchBar.text = "> "
        didPresentSearchController(resultSearchController)
    }
    
    @IBAction func equalAmountSearch(_ sender: Any) {
        resultSearchController.searchBar.text = "= "
    }
    
    @IBAction func lessAmountSearch(_ sender: Any) {
        resultSearchController.searchBar.text = "< "
    }
    
    
    @IBAction func ascendingDateSearch(_ sender: Any) {
        let searchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        let dateSort = NSSortDescriptor(key: "date", ascending: true)
        searchRequest.sortDescriptors = [dateSort]
//        searchBar.endEditing(true)
        updateTableView(searchActive, searchRequest)
//        // Get the current calendar with local time zone
//        var calendar = Calendar.current
//        calendar.timeZone = NSTimeZone.local
//        
//        // Get today's beginning & end
//        let date = calendar.startOfDay(for: Date()) // eg. 2016-10-10 00:00:00
//        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute],from: date)
//        components.day! += 1
//        let dateTo = calendar.date(from: components)!
//        components.day! -= 30
//        let dateFrom = calendar.date(from: components)! // eg. 2016-10-11 00:00:00
//        // Note: Times are printed in UTC. Depending on where you live it won't print 00:00:00 but it will work with UTC times which can be converted to local time
//        // Set predicate as date being today's date
//        let datePredicate = NSPredicate(format: "(%@ <= date) AND (date < %@)", argumentArray: [dateFrom, dateTo])
    }
    
    
    @IBAction func descendingDateSearch(_ sender: Any) {
        let searchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        let dateSort = NSSortDescriptor(key: "date", ascending: false)
        searchRequest.sortDescriptors = [dateSort]
        updateTableView(searchActive, searchRequest)
    }
    
    @IBAction func allDataSearch(_ sender: Any) {
        let searchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        updateTableView(searchActive, searchRequest)
    }
    
    func updateTableView(_ searchActive: Bool, _ searchRequest: NSFetchRequest<NSManagedObject>) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        do {
            expenses = try managedContext.fetch(searchRequest)
            print("expenses: \(expenses)")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        self.tableView.reloadData()
    }
}
