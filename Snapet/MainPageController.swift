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
import Charts
import Foundation
import Photos
import AVKit
import DKImagePickerController


class MainPageController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, KCFloatingActionButtonDelegate{
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var pieChartView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var analyzeTextLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressBar: UIImageView!
    
    
    var chart = PieChartView()
    var fab = KCFloatingActionButton()
    var imageInProcess = UIImage()
    var isOCR = false
    var batchAnalyzed = false
    var amount = [Double]()
    static var budgetNum = ""
    static var colorMap = [UIColor]()
    static var category = [String]()
    
    var expenses: [NSManagedObject] = []
    var results: [NSManagedObject] = []
    var total = 0.0
    var row = 0
    
    var fetchedAmount = Double(-1.0)
    var fetchedDate: Date? = nil
    var fetchedAccount: Int? = nil
    var fetchedMerchant: String? = nil
    var fetchedCategory: String? = nil
    
    var uploadedImages: [UIImage] = []

    var useCamera = false
    var analyzeInProgress = false
    var addNewData = true
    
    let cellImage = UIImageView(image: UIImage(named: "cellDesign.png")!)
    let session = URLSession.shared
    let imagePicker = UIImagePickerController()
    let pickerController = DKImagePickerController()
    // multi-pick
    var assets: [DKAsset]?
    
    let googleAPIKey = "AIzaSyBmcPFpapjEug_lKki4qnuiN-XYvE3xVYQ"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    let googleKGURL = "https://kgsearch.googleapis.com/v1/entities:search"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the floating action button
        layoutFAB()
        
//        DeleteAllData()
        imagePicker.delegate = self
        pickerController.assetType = .allPhotos
        pickerController.showsCancelButton = true
        //dpickerController.defaultSelectedAssets?.removeAll()
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 0. Fetch data to prepare for pie chart display
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let distinctCategoryReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
        distinctCategoryReq.propertiesToFetch = ["category"]
        distinctCategoryReq.returnsDistinctResults = true
        distinctCategoryReq.resultType = NSFetchRequestResultType.dictionaryResultType
        // array for storing category displayed in the pie chart
        MainPageController.category = [String]()
        // array for storing total amount of each category
        amount = [Double]()
        do {
            let results = try managedContext.fetch(distinctCategoryReq)
            if !results.isEmpty {
            let resultsDict = results as! [[String: String]]
            // set category array values
            for r in resultsDict {
                if let temp = r["category"] {
                    MainPageController.category.append(temp) }
                }
            }
        } catch let err as NSError {
            print(err.debugDescription)
        }
        for i in MainPageController.category {
            let categoryReq =
                NSFetchRequest<NSManagedObject>(entityName: "Expense")
            categoryReq.predicate = NSPredicate(format: "category == %@", i)
            var sum = 0.0;
            // set amount array values
            do {
                results = try managedContext.fetch(categoryReq)
                if !results.isEmpty{
                    for result in results {
                        let amt = (result.value(forKeyPath: "amount") as? Double)!
                        sum += amt
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
            amount.append(sum)
        }
        
        // 1. create chart view
        chart = PieChartView( frame: self.pieChartView.frame)
        self.reloadPieChart()

        // 3a. set style
        chart.holeColor = nil
        chart.legend.textColor = Palette.InfoText
        
        // size
        chart.center = CGPoint(x: pieChartView.frame.size.width  / 2, y: pieChartView.frame.size.height / 2);
        
        // description
        let d = Description()
        var budgetText = ""
        let budgetAmount = "Budget: $"

        if let budget = Double(MainPageController.budgetNum) {
            budgetText = budgetAmount.appending(MainPageController.budgetNum)
            if budget < total {
                budgetText = budgetText.appending("\nExceeds budget!")
            }
        }
        d.text = budgetText
        d.font = UIFont(name: "HelveticaNeue-Bold", size: 11.0)!
        d.textColor = Palette.budgetTextColor
        chart.chartDescription = d
        
        // 4. add chart to UI
        self.pieChartView.addSubview(chart)


        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 84;
        
        self.navigationController?.navigationBar.barTintColor = Palette.mainPageBarColor
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AppleGothic", size: 20)!]
        
        /** Not working yet */
        let height: CGFloat = 50
        let bounds = self.navigationController!.navigationBar.bounds
        self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + height)
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //pickerController.defaultSelectedAssets?.removeAll()
    }
    
    
    func reloadPieChart(){
        // Generate chart data entries
        var entries = [ChartDataEntry]()
        for (i, v) in amount.enumerated() {
            let entry = PieChartDataEntry()
            entry.y = v
            entry.label = MainPageController.category[i]
            entries.append( entry)
        }
        
        // Chart setup
        let set = PieChartDataSet( values: entries, label: "")
        set.colors = UIColor.random(ofCount: entries.count)
        MainPageController.colorMap = set.colors
        let data = PieChartData( dataSet: set)
        chart.data = data
        chart.noDataText = "No data available"
        chart.isUserInteractionEnabled = false
        let totalAmount = "$\(total)"
        let centerTxt: NSMutableAttributedString = NSMutableAttributedString(string: totalAmount)
        centerTxt.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 30.0)!,NSForegroundColorAttributeName:UIColor.white], range: NSMakeRange(0, centerTxt.length))
        chart.centerAttributedText = centerTxt
    }
    
    
    
    
    /*****   Table View Stuff  ******/
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if expenses.count < 5 {
            return expenses.count
//        } else {
//            return 5
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let expense = expenses[indexPath.row]
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "newCell", for: indexPath)
        let cell = dequeued as! ExpenseTableViewCell
        
        let amountLabel = expense.value(forKeyPath: "amount") as? Double
        let dateLabel = expense.value(forKeyPath: "date") as? Date
        let categoryLabel = expense.value(forKeyPath: "category") as? String
        let merchantLabel = expense.value(forKeyPath: "merchant") as? String
        if (categoryLabel != nil) {
            cell.categoryLabel?.text = categoryLabel
            
        /*** Uncomment the following line if want category label to match current  color palette ***/
            //let labelColor = self.getCategoryColor(category: categoryLabel!)
            //cell.categoryLabel?.textColor = labelColor
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
        cell.backgroundColor = UIColor.clear
        cell.backgroundView = UIImageView(image: UIImage(named: "cellDesign.png")!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        row = indexPath.row
        print("select row is \(indexPath.row)")
        addNewData = false
        self.performSegue(withIdentifier: "toDetail", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print("delete row is \(indexPath.row)")
        if editingStyle == .delete {
            let merchant = expenses[indexPath.row].value(forKey: "merchant")
            let amt = expenses[indexPath.row].value(forKey: "amount")
            let cat = expenses[indexPath.row].value(forKey: "category")
            // delete local data
            var count = 0
            var index = 0
            print("test1 \(expenses)")
            for (i, v) in MainPageController.category.enumerated() {
                if v == (cat as! String) {
                    index = i
                    
                }
            }
            for (_, v) in expenses.enumerated() {
                if (v.value(forKey: "category") as! String) == (cat as! String) {
                    count = count + 1
                    print(count)
                }
            }
            if (count > 1) {
                amount[index] = amount[index] - (amt as! Double)
                total = total - (amt as! Double)
            }
            if (count == 1) {
                MainPageController.category.remove(at: index)
                amount.remove(at: index)
                total = total - (amt as! Double)
            }
            expenses.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // delete core data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
            req.predicate = NSPredicate(format: "merchant == %@ AND amount = %@ AND category = %@", merchant as! CVarArg, amt as! CVarArg, cat as! CVarArg)
            let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: req)
            do {
                try managedContext.execute(DelAllReqVar)
            }
            catch {
                print(error)
            }
            // reload pie chart and table view
            self.reloadPieChart()
            self.pieChartView.reloadInputViews()
            OperationQueue.main.addOperation(){
                self.tableView.reloadData()
            }
        }
    }
    
    
    func getCategoryColor(category: String) -> UIColor{
        for (i, v) in MainPageController.category.enumerated(){
            if v == category && MainPageController.colorMap != []{
                return MainPageController.colorMap[i]
            }
        }
        return Palette.amountTint
    }
    
    
    
    /****   Floating action button stuff  ****/
    func layoutFAB() {
        
        fab.plusColor = UIColor.white
        
        let item = KCFloatingActionButtonItem()
        item.buttonColor = Palette.uploadButtonColor
        item.circleShadowColor = UIColor.black
        item.titleShadowColor = UIColor.black
        item.title = "Upload image"
        item.icon = UIImage(named: "upload.png")
        item.handler = { item in
            self.analyzeInProgress = true
            self.showImagePicker()
            self.fab.close()
        }
        
        let item2 = KCFloatingActionButtonItem()
        item2.buttonColor = Palette.cameraButtonColor
        item2.circleShadowColor = UIColor.black
        item2.titleShadowColor = UIColor.black
        item2.title = "Camera"
        item2.icon = UIImage(named: "camera.png")
        item2.handler = { item in
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
            self.useCamera = true
        }
        
        let item3 = KCFloatingActionButtonItem()
        item3.buttonColor = Palette.manualButtonColor
        item3.circleShadowColor = UIColor.black
        item3.titleShadowColor = UIColor.black
        item3.title = "Manual"
        item3.icon = UIImage(named: "manual.png")
        item3.handler = { item in
            self.isOCR = false
            self.performSegue(withIdentifier: "toDetail", sender: nil)
        }
        
        fab.addItem(item: item2)
        fab.addItem(item: item)
        fab.addItem(item: item3)
        fab.fabDelegate = self
        fab.sticky = true
        
        self.view.addSubview(fab)
    }
    
    
    /****     Fetching from Core Data   ****/
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.uploadedImages = []
        //pickerController.defaultSelectedAssets?.removeAll()
        
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
        let sort1 = NSSortDescriptor(key: "date", ascending: false)
        let sort2 = NSSortDescriptor(key: "merchant", ascending: false)
        let sort3 = NSSortDescriptor(key: "amount", ascending: true)
        fetchRequest.sortDescriptors = [sort1, sort2, sort3]
        
        // 2.2 distinct categories request
        let distinctCategoryReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
        distinctCategoryReq.propertiesToFetch = ["category"]
        distinctCategoryReq.returnsDistinctResults = true
        distinctCategoryReq.resultType = NSFetchRequestResultType.dictionaryResultType
        // 2.5 amount query request
        let amountRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        amountRequest.predicate = NSPredicate(format: "amount > %@", "5")
        
        // 3 fetch core data based on request
        
        // 3.1 fetch all data
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
        
        // 3.2 fetch distinct categories data
        MainPageController.category = [String]()
        amount = [Double]()
        total = 0.0
        do {
            let results = try managedContext.fetch(distinctCategoryReq)
            if !results.isEmpty {
                let resultsDict = results as! [[String: String]]
                // set category array values
                for r in resultsDict {
                    if let temp = r["category"] {
                        MainPageController.category.append(temp) }
                }
            }
        } catch let err as NSError {
            print(err.debugDescription)
        }
        for i in MainPageController.category {
            let categoryReq =
                NSFetchRequest<NSManagedObject>(entityName: "Expense")
            categoryReq.predicate = NSPredicate(format: "category == %@", i)
            var sum = 0.0;
            // set amount array values
            do {
                results = try managedContext.fetch(categoryReq)
                if !results.isEmpty{
                    for result in results {
                        let amt = (result.value(forKeyPath: "amount") as? Double)!
                        sum += amt
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
            total += sum
            amount.append(sum)
        }
        
        self.reloadPieChart()
        
        // description
        let d = Description()
        var budgetText = ""
        let budgetAmount = "Budget: $"
        if MainPageController.budgetNum == "" {
            budgetText = "Budget not set"
        }
        if let budget = Double(MainPageController.budgetNum) {
            budgetText = budgetAmount.appending(MainPageController.budgetNum)
            if budget < total {
                budgetText = budgetText.appending("\nExceeds budget!")
            }
        }
        d.text = budgetText
        d.font = UIFont(name: "HelveticaNeue-Bold", size: 11.0)!
        d.textColor = UIColor(red:114/255, green:127/255, blue:141/255, alpha:1.0)
        chart.chartDescription = d

        // 4 update table view and pie chart view
        self.tableView.reloadData()
        self.pieChartView.reloadInputViews()
        if !analyzeInProgress{
            self.chart.animate(xAxisDuration: 0.0, yAxisDuration: 1.0)
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
        self.analyzeInProgress = false
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
    
 
    
    /****    Sending requests to Google Vision API  ****/
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageInProcess = pickedImage
            isOCR = true
            // Base64 encode the image and create the request
            self.uploadedImages.append(pickedImage)
            self.analyzeInProgress = true
            self.performSegue(withIdentifier: "toDetail", sender: nil)
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    /****     Imagepicker Stuff     ****/
    func showImagePicker() {
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            print("didSelectAssets")
            self.isOCR = true
            self.assets = assets
            for (_, item) in assets.enumerated(){
                let asset = item
                asset.fetchFullScreenImage(true, completeBlock:{ image, info in
                    self.uploadedImages.append(image!)
                })
            }
            self.performSegue(withIdentifier: "toDetail", sender: nil)
        }
        self.present(pickerController, animated: true) {
            self.pickerController.defaultSelectedAssets?.removeAll()
        }
    }


//    
//    
//    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
//        UIGraphicsBeginImageContext(imageSize)
//        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        let resizedImage = UIImagePNGRepresentation(newImage!)
//        UIGraphicsEndImageContext()
//        return resizedImage!
//    }
//    
//    
//    func base64EncodeImage(_ image: UIImage) -> String {
//        var imagedata = UIImagePNGRepresentation(image)
//        
//        // Resize the image if it exceeds the 2MB Google vision API limit
//        if (imagedata!.count > 2097152) {
//            let oldSize: CGSize = image.size
//            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
//            imagedata = resizeImage(newSize, image: image)
//        }
//        
//        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
//    }
//    
//    func createRequest(with imageBase64: String) {
//        // Create our request URL
//        var request = URLRequest(url: googleURL)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
//        
//        // Build our API request
//        let jsonRequest = [
//            "requests": [
//                "image": [
//                    "content": imageBase64
//                ],
//                "features": [
//                    [
//                        "type": "TEXT_DETECTION",
//                        ],
//                    [
//                        "type": "LOGO_DETECTION",
//                        "maxResults": 3
//                    ],
//                    [
//                        "type": "WEB_DETECTION",
//                        "maxResults": 5
//                    ],
//                ]
//            ]
//        ]
//        let jsonObject = JSON(jsonDictionary: jsonRequest)
//        
//        // Serialize the JSON
//        guard let data = try? jsonObject.rawData() else {
//            return
//        }
//        request.httpBody = data
//        self.progressView.setProgress(0.2, animated: true)
//        // Run the request on a background thread
//        //DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
//    }
//    
//    
//    
//    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail"{
            if addNewData {
                // get a reference to the second view controller
                let secondViewController = segue.destination as! DetailViewController
                secondViewController.imagesProcessing = self.uploadedImages
                secondViewController.isOCR = self.isOCR
            }
            else {
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
    
    
    func checkExistingCategory(_ detectedMerchant: String) -> String {
        var category = ""
        let categoryReqest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
        categoryReqest.predicate = NSPredicate(format: "merchant == %@", detectedMerchant)
        print("detectedMerchant is = \(detectedMerchant)")
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let results = try managedContext.fetch(categoryReqest)
            if !results.isEmpty {
                let result = results[results.count - 1]
                category = (result.value(forKeyPath: "category") as? String)!
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return category
    }
//
//    
//    
//    /**
//     *Analyze Web
//     */
//    func analyzeWeb(json: JSON) -> [String]? {
//        var results: [String]? = nil
//        var temp:[String] = []
//        if let responseArray = json["responses"].array{
//            for responseDict in responseArray {
//                if let webArray = responseDict["webDetection"]["webEntities"].array {
//                    for webDict in webArray{
//                        if let webResult = webDict["description"].string{
//                            temp.append(webResult)
//                        }
//                    }
//                }
//            }
//        }
//        if !temp.isEmpty{
//            results = temp
//        }
//        return results
//    }
//    
//    
//    /**
//     *Analyze Logo
//     */
//    func analyzeLogo(json: JSON) -> String? {
//        var result: String? = nil
//        if let responseArray = json["responses"].array{
//            for responseDict in responseArray {
//                if let logo: String = responseDict["logoAnnotations"][0]["description"].string{
//                    result = logo
//                }
//            }
//        }
//        return result
//    }
//    
//    
//    
//    /**
//     *Analyze Date
//     */
//    func analyzeDate(json: JSON) -> Date? {
//        var date: Date? = nil
//        if let responseArray = json["responses"].array{
//            for responseDict in responseArray {
//                let ocrTxt: String! = responseDict["textAnnotations"][0]["description"].string
//                //print("ocrtext is")
//                //print(ocrTxt)
//                date = retrieveDate(input: ocrTxt)
//                
//            }
//        }
//        print("final date is")
//        if let theDate = date {
//            print(theDate)
//        }
//        return date
//    }
//    
//    
//    func retrieveDate(input: String) -> Date? {
//        var results = [Date]()
//        var returnDate:Date? = nil
//        let chrono = Chrono.shared
//        var components = input.characters.split(separator: "\n").map(String.init)
//        for i in 0..<components.count {
//            if let date = chrono.dateFrom(naturalLanguageString: components[i]){
//                results.append(date)
//            }
//        }
//        if let min = results.min(){
//            returnDate = min
//        }
//        return returnDate
//    }
//    
//    
//    /**
//     *Analyze Amount
//     */
//    func analyzeAmount(json: JSON) -> Double {
//
//        let finalAmount = analyzeAmountByLocation(json: json)
//
//        print("final amount is")
//        print (finalAmount)
//        return finalAmount
//    }
//    
//    
//    func analyzeAmountByLocation(json: JSON) -> Double{
//        var returnAmount:Double = -1.0
//        var results = [Double]()
//        
//        if let responseArray = json["responses"].array{
//            for responseDict in responseArray {
//                if let textArray = responseDict["textAnnotations"].array{
//                    for (index, _) in textArray.enumerated() {
//                        let descriptionText = textArray[index]["description"].string
//                        if descriptionText?.lowercased().range(of:"total") != nil
//                            && (descriptionText?.characters.count)! < 50
//                            && descriptionText?.lowercased().range(of:"subtotal") == nil{
//                            
//                            let yfloor = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
//                            let yceiling = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
//                            let yrightEdge = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
//                            let result = retrieveAmountByLocation(yfloor: yfloor!, yceiling: yceiling!, yrightEdge: yrightEdge!, json: json)
//                            results.append(result)
//                        }
//                    }
//                }}}
//        if let max = results.max(){
//            returnAmount = max
//        }
//        return returnAmount
//    }
//    
//    
//    func retrieveAmountByLocation(yfloor: Int, yceiling: Int, yrightEdge: Int, json: JSON) -> Double {
//        var returnAmount:Double = -1.0
//        var candidateText = ""
//        
//        if let responseArray = json["responses"].array{
//            for responseDict in responseArray {
//                if let textArray = responseDict["textAnnotations"].array{
//                    for (index, _) in textArray.enumerated() {
//                        let yfloorCandidate = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
//                        let yceilingCandidate = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
//                        let yrightEdgeCandidate = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
//                        if abs(yfloor - yfloorCandidate!) < 20 && abs(yceiling - yceilingCandidate!) < 20 && yrightEdge < yrightEdgeCandidate!{
//                            candidateText = candidateText + textArray[index]["description"].string! + " "
//                        }
//                    }
//                }}}
//
//        returnAmount = retrieveAmount(input: candidateText)
//        if returnAmount == -1{
//            candidateText = candidateText.removingWhitespaces()
//            returnAmount = retrieveAmount(input: candidateText)
//        }
//        return returnAmount
//    }
//    
//    
//    
//    func analyzePureTextAmount(ocrTxt: String) -> Double {
//        
//        var returnAmount:Double = -1.0
//        
//        // break the ocr text in lines
//        var ocrTextByLines:[String] = []
//        ocrTxt.enumerateLines { (line, stop) -> () in
//            ocrTextByLines.append(line)
//        }
//        
//        for (index, item) in ocrTextByLines.enumerated(){
//            if item.lowercased().range(of:"total") != nil &&
//                item.lowercased().range(of:"subtotal") == nil {
//                // get the amount that correspond to total
//                let amount = self.retrieveAmount(input: item)
//                if amount != -1 {
//                    print("detected amount: \(amount)")
//                    returnAmount = amount
//                }
//                else {
//                    //print("index is: \(index)")
//                    let element = ocrTextByLines[index + 1]
//                    //print(element)
//                    let newAmount = self.retrieveAmount(input: element)
//                    print("detected amount: \(newAmount)")
//                    returnAmount = newAmount
//                }
//            }
//        }
//        return returnAmount
//    }
//    
//    func retrieveAmount(input: String) -> Double {
//        // split the line in words
//        var components = input.characters.split(separator: " ").map(String.init)
//        for i in 0..<components.count {
//            if let doubleValue = Double(components[i]){
//                return doubleValue
//            }
//                // Remove the currency sign that hinders the amount to be parsed
//            else {
//                components[i].remove(at: components[i].startIndex)
//                if let doubleValue = Double(components[i]){
//                    return doubleValue
//                }
//            }
//        }
//        //No legit amount detected
//        return -1
//
//    }
    
    
    
}
