//
//  DetailViewController.swift
//  Snapet
//
//  Created by Duan Li on 3/26/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import Foundation
import MobileCoreServices

extension Dictionary {
    func sortedKeys(isOrderedBefore:(Key,Key) -> Bool) -> [Key] {
        return Array(self.keys).sorted(by: isOrderedBefore)
    }
    
    // Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
    func sortedKeysByValue(isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        return sortedKeys {
            isOrderedBefore(self[$0]!, self[$1]!)
        }
    }
    
    // Faster because of no lookups, may take more memory because of duplicating contents
    func keysSortedByValue(isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        return Array(self)
            .sorted() {
                let (_, lv) = $0
                let (_, rv) = $1
                return isOrderedBefore(lv, rv)
            }
            .map {
                let (k, _) = $0
                return k
        }
    }
}

class DetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var merchantField: UITextField!
    @IBOutlet weak var accountField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    @IBOutlet weak var confirmImage: UIImageView!
    @IBOutlet weak var categoryButton1: UIButton!
    @IBOutlet weak var categoryButton2: UIButton!
    @IBOutlet weak var categoryButton3: UIButton!
    @IBOutlet weak var categoryRecommend: UILabel!
    
    @IBOutlet weak var hideTopBar: UIImageView!
    @IBOutlet weak var hideBottomBar: UIImageView!
    @IBOutlet weak var analyzing: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var amount: Double = 0.0
    var merchant = ""
    var account = 0
    var date: Date? = nil
    var category = ""
    var isEdit = false
    var row = 0
    var expenses: [NSManagedObject] = []
    var results: [NSManagedObject] = []
    var currentImage = UIImage()
    var fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
    var message = ""
    var categoryButtons = ["Food", "Transportation", "Groceries"]
    
    let session = URLSession.shared
    let googleAPIKey = "AIzaSyBmcPFpapjEug_lKki4qnuiN-XYvE3xVYQ"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    let googleKGURL = "https://kgsearch.googleapis.com/v1/entities:search"
    
    var imagesProcessing: [UIImage] = []
    var amounts: [Double] = []
    var merchants: [String] = []
    var dates: [Date] = []
    var categories: [String] = []
    var globalIndex = 0
    
    var isOCR = false
    var processed = 0
    
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
    
    @IBAction func setCategory1(_ sender: Any) {
        categoryButton1.setTitle(categoryButtons[0], for: UIControlState.normal)
        categoryField.text = categoryButtons[0]
        category = categoryButtons[0]
    }
    
    @IBAction func setCategory2(_ sender: Any) {
        categoryField.text = categoryButtons[1]
        category = categoryButtons[1]
    }
    
    @IBAction func setCategory3(_ sender: Any) {
        categoryField.text = categoryButtons[2]
        category = categoryButtons[2]
    }
    
    @IBAction func saveData(_ sender: Any) {
        let amountToSave = amount
        self.save(amount: Double(amountToSave))
    }
    
    @IBAction func toNext(_ sender: Any) {
        self.globalIndex += 1
        self.reInitializeData(index: globalIndex)
    }
    
    
    /*
     Saving to Core Data
     */
    func save(amount: Double) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        // edit existing data
        if isEdit {
            // 1
            let managedContext =
                appDelegate.persistentContainer.viewContext
            // 2
            let expense = expenses[row]
            // 3
            expense.setValue(amount, forKeyPath: "amount")
            
            if (merchant != "") {
                expense.setValue(merchant, forKeyPath: "merchant")
                fetchRequest.predicate = NSPredicate(format: "merchant == %@" , merchant)
            }
            if (account != 0) {
                expense.setValue(account, forKeyPath: "account")
            }
            if (date != nil) {
                expense.setValue(date, forKeyPath: "date")
            } else {
                message.append("\n Please enter a date.")
            }
            if (category != "") {
                expense.setValue(category, forKeyPath: "category")
                // update the category field for the entry with the same merchant name in core data
                do {
                    results = try managedContext.fetch(fetchRequest)
                    if !results.isEmpty {
                        for result in results {
                            result.setValue(category, forKeyPath: "category")
                            do {
                                try managedContext.save()
                            } catch let error as NSError {
                                print("Could not save. \(error), \(error.userInfo)")
                            }
                        }
                    }
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            
//                // update the category field for the entry with the same merchant name in local copy
//                if !expenses.isEmpty {
//                    for result in expenses {
//                        if (result.value(forKeyPath: "merchant") as? String == merchant) {
//                            result.setValue(category, forKeyPath: "category")
//                            do {
//                                try managedContext.save()
//                            } catch let error as NSError {
//                                print("Could not save. \(error), \(error.userInfo)")
//                            }
//                        }
//                    }
//                }
            }
            // 4
            do {
                expenses[row] = expense
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        // add new data
        } else {
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Expense", in: managedContext)!
            
            if isOCR {
                for (i, _) in imagesProcessing.enumerated(){
                    let expense = NSManagedObject(entity: entity, insertInto: managedContext)
                    self.conditionedSave(context: managedContext, expense: expense, amount: amounts[i],
                                         date: dates[i], merchant: merchants[i], category: categories[i])
                }
            }
            // Manual expense entry
            else {
                let expense = NSManagedObject(entity: entity, insertInto: managedContext)
                self.conditionedSave(context: managedContext, expense: expense, amount: amount,
                                     date: date!, merchant: merchant, category: category)
            }
        }
        accountField.text = nil
        dateField.text = nil
        print("date is nil now")
        merchantField.text = nil
        categoryField.text = nil
        amountField.text = nil
    }
    
    func conditionedSave(context: NSManagedObjectContext, expense: NSManagedObject, amount: Double,
                         date: Date, merchant: String, category: String){
        
        expense.setValue(amount, forKeyPath: "amount")
        expense.setValue(date, forKeyPath: "date")
        expense.setValue(merchant, forKeyPath: "merchant")
        expense.setValue(category, forKeyPath: "category")
        do {
            try context.save()
            expenses.append(expense)
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        // update the category field for the entry with the same merchant name in core data
        do {
            fetchRequest.predicate = NSPredicate(format: "merchant == %@" , merchant)
            results = try context.fetch(fetchRequest)
            if !results.isEmpty {
                for result in results {
                    result.setValue(category, forKeyPath: "category")
                    do {
                        try context.save()
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
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
                if imagesProcessing != [] {
                    amounts[globalIndex] = amount
                }
            }
        }
        if let temp = merchantField.text{
            if (temp.characters.count > 0) {
                merchant = temp
                if imagesProcessing != [] {
                    merchants[globalIndex] = merchant
                }
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
                if let temp2 = dateFormatter.date(from: temp) {
                    date = temp2
                    if imagesProcessing != [] {
                        dates[globalIndex] = date!
                    }
                } else {
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let temp1 = temp.substring(to: temp.index((temp.startIndex), offsetBy: 10))
                    date = dateFormatter.date(from: temp1)
                    if imagesProcessing != [] {
                        dates[globalIndex] = date!
                    }
                }
            }
        }
        if let temp = categoryField.text {
            if (temp.characters.count > 0) {
                category = temp
                if imagesProcessing != [] {
                    categories[globalIndex] = category
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // re-initialize fields
        self.amounts = []
        self.dates = []
        self.merchants = []
        self.categories = []
        self.globalIndex = 0
        self.processed = 0
        
        if imagesProcessing != [] {
            self.amounts = [Double](repeatElement(0, count: imagesProcessing.count))
            self.dates = [Date](repeatElement(Date(), count: imagesProcessing.count))
            self.merchants = [String](repeatElement("", count: imagesProcessing.count))
            self.categories = [String](repeatElement("", count: imagesProcessing.count))
            categoryRecommend.isHidden = true
            categoryButton1.isHidden = true
            categoryButton2.isHidden = true
            categoryButton3.isHidden = true
            activityIndicator.startAnimating()
            for (i, item) in imagesProcessing.enumerated(){
                let binaryImageData = self.base64EncodeImage(item)
                self.createRequest(with: binaryImageData, index: i)
            }
        } else {
            hideTopBar.isHidden = true
            hideBottomBar.isHidden = true
            analyzing.isHidden = true
            activityIndicator.isHidden = true
            self.nextButton.isHidden = true
        }
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let recommendCat = categoryRecommendation()
        if recommendCat.count == 3 {
            categoryButtons = recommendCat
        } else if recommendCat.count == 2 {
            categoryButtons[0] = recommendCat[0]
            categoryButtons[1] = recommendCat[1]
            categoryButtons[2] = "Transportation"
        } else if recommendCat.count == 1 {
            if recommendCat[0] != "" {
                categoryButtons[0] = recommendCat[0]
                categoryButtons[1] = "Transportation"
                categoryButtons[2] = "Groceries"
            }
        }
        categoryButton1.setTitle(categoryButtons[0], for: UIControlState.normal)
        categoryButton2.setTitle(categoryButtons[1], for: UIControlState.normal)
        categoryButton3.setTitle(categoryButtons[2], for: UIControlState.normal)

         /** -----    drop down toolbar for date picker    ----- **/
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6,
                                              width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.blackTranslucent
        toolBar.tintColor = UIColor.white
        toolBar.backgroundColor = UIColor.black
        
        let todayBtn = UIBarButtonItem(title: "Today", style: UIBarButtonItemStyle.plain, target: self,
                                       action: #selector(DetailViewController.tappedToolBarBtn))
        let okBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self,
                                       action: #selector(DetailViewController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
                                        target: self, action: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3,
                                          height: self.view.frame.size.height))
        label.font = UIFont(name: "Helvetica", size: 12)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = "Select the associated date"
        label.textAlignment = NSTextAlignment.center
        let textBtn = UIBarButtonItem(customView: label)
        toolBar.setItems([todayBtn,flexSpace,textBtn,flexSpace,okBarBtn], animated: true)
        dateField.inputAccessoryView = toolBar
        /** -----    drop down toolbar for date picker    ----- **/
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func categoryRecommendation() -> [String]{
        var result = [""]
        var top3Counts = [Int]()
        var top3Categories = [String]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
        
        let categoryExpr = NSExpression(forKeyPath: "category")
        let countExpr = NSExpressionDescription()
        
        countExpr.name = "count"
        countExpr.expression = NSExpression(forFunction: "count:", arguments: [ categoryExpr ])
        countExpr.expressionResultType = .integer64AttributeType
        
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        fetchRequest.propertiesToGroupBy = ["category"]
        fetchRequest.propertiesToFetch = [countExpr]

        do {
            let results = try managedContext.fetch(fetchRequest)
            for result in results as! [[String: Int]]{
                if let temp = result["count"] {
                    top3Counts.append(temp)
                }
            }
        } catch let err as NSError {
            print(err)
        }
        
        do {
            fetchRequest.propertiesToFetch = ["category"]
            let results = try managedContext.fetch(fetchRequest)
            for result in results as! [[String: String]]{
                if let temp = result["category"] {
                    top3Categories.append(temp)
                }
            }
        } catch let err as NSError {
            print(err)
        }
        
        var dic:[String: Int] = ["":0]
        var index = 0
        for (_, v) in top3Categories.enumerated() {
            dic[v] = top3Counts[index]
            index += 1
        }
        let sorted = dic.keysSortedByValue(isOrderedBefore: >)
        if sorted.count >= 4 {
            result.removeAll()
            result.append(sorted[0])
            result.append(sorted[1])
            result.append(sorted[2])
            print("sorted\(result)")
        } else if sorted.count == 3 {
            result.removeAll()
            result.append(sorted[0])
            result.append(sorted[1])
        } else if sorted.count == 2 {
            result.removeAll()
            result.append(sorted[0])
        }
        return result
        
        
//        do {
//            let cats = try managedContext.fetch(fetchRequest)
//            if !cats.isEmpty {
//                let resultsDict = cats as! [[String: String]]
//                // set category array values
//                for r in resultsDict {
//                    print("r is \(r)")
//                    if let temp = r["category"] {
//                        top3Categories.append(temp)
//                        print("\(temp)")
//                    }
//                    if let temp1 = r["count"] {
//                        top3Categories.append(temp1)
//                        print("\(temp1)")
//                    }
//                }
//            }
//        } catch let err as NSError {
//            print(err.debugDescription)
//        }
//        return result
    }
    
    
    /** present analyzed results for user uploads **/
    func reloadView(){
        DispatchQueue.main.async {
            print("all done")
            print(self.amounts)
            print(self.merchants)
            print(self.dates)
            print(self.categories)
            self.activityIndicator.stopAnimating()
            self.hideTopBar.isHidden = true
            self.hideBottomBar.isHidden = true
            self.analyzing.isHidden = true
            self.activityIndicator.isHidden = true
            self.reInitializeData(index: 0)
        }
    }
    
    /** preventing view to be reloaded before all images processed **/
    func checkedReloadView(){
        self.processed += 1
        if self.processed == self.imagesProcessing.count{
            self.reloadView()
        }
    }
    
    
    func reInitializeData(index: Int){
        DispatchQueue.main.async {
            self.title = (self.globalIndex + 1).description + "/" + self.imagesProcessing.count.description
            self.amountField.text = self.amounts[index].description
            self.dateField.text = self.dates[index].description
            self.merchantField.text = self.merchants[index]
            self.categoryField.text = self.categories[index]
            self.confirmImage.image = self.imagesProcessing[index]
            if self.globalIndex + 1 < self.imagesProcessing.count{
                self.saveButton.isHidden = true
                self.nextButton.isHidden = false
            }
            else{
                self.saveButton.isHidden = false
                self.nextButton.isHidden = true
            }
        }
    }
    

    
    /** -----  Google Vision and Knoweledge Graph methods  ----- **/
    
    // Encode the image
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        if (imagedata!.count > 2097152) {       // 2MB size limit
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    // Resize the image if it exceeds the 2MB Google vision API limit
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func createRequest(with imageBase64: String, index: Int) {
        // Create our request URL
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "TEXT_DETECTION",
                        ],
                    [
                        "type": "LOGO_DETECTION",
                        "maxResults": 3
                    ],
                    [
                        "type": "WEB_DETECTION",
                        "maxResults": 5
                    ],
                ]
            ]
        ]
        let jsonObject = JSON(jsonDictionary: jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        request.httpBody = data
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request, index: index) }
    }
    
    
    func runRequestOnBackgroundThread(_ request: URLRequest, index: Int) {
        // run the request
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            self.analyzeResults(data, index: index)
        }
        task.resume()
    }
    
    // Create Knowledge graph requests for the input string
    func createKGRequest(input:String, index: Int) {
        var finalURLString = googleKGURL + "?query=" + input + "&key=" + googleAPIKey + "&limit=5"
        finalURLString = NSString(string: finalURLString).addingPercentEncoding(
            withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let urlComponents = URLComponents(string: finalURLString)
        if let finalURL = urlComponents?.url{
            print("url is")
            print(finalURL)
            var request = URLRequest(url: finalURL)
            request.httpMethod = "GET"
            DispatchQueue.global().sync { self.runKGRequest(request, index: index) }
        }
        
    }
    
    func runKGRequest(_ request: URLRequest, index: Int) {
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            let KGjson = JSON(data: data)
            let errorObj: JSON = KGjson["error"]
            if (errorObj.dictionaryValue != [:]) {
                print( "Error code \(errorObj["code"]): \(errorObj["message"])")
            } else {
                print(KGjson)
                self.analyzeCategory(json: KGjson, index: index)
            }
        }
        task.resume()
    }
    
    
    
    
    /** -----  JSON interpretation algorithm  ----- **/
    
    func analyzeResults(_ dataToParse: Data, index: Int) {
        
        var isMerchantDetected = false
        var isCategoryDetected = false
        
        // Update UI on the main thread, and use SwiftyJSON to parse results
        let json = JSON(data: dataToParse)
        let errorObj: JSON = json["error"]
        
        if (errorObj.dictionaryValue != [:]) {
            print( "Error code \(errorObj["code"]): \(errorObj["message"])")
        } else {      // Parse the response
                      // print(json)
            
            self.amounts[index] = self.analyzeAmount(json: json)   // get the amount in receipt
            if let dateDetected = self.analyzeDate(json: json){    // get the date from receipt
                self.dates[index] = dateDetected
            }
        
            if let merchantDetected = self.analyzeLogo(json: json){  // if merchant detected based on logo
                self.merchants[index] = merchantDetected
                isMerchantDetected = true
                
                let categoryInferred = checkExistingCategory(merchants[index])
                if !categoryInferred.isEmpty{                      // we already have a category for the merchant
                    self.categories[index] = categoryInferred
                    isCategoryDetected = true
                    self.checkedReloadView()
                } else {                                            // we need to use knowledge graph
                    self.createKGRequest(input: merchants[index], index: index)
                }
            }
            if !isMerchantDetected {                                // merchant not detected based on logo
                if let webResults = self.analyzeWeb(json: json){
                    merchants[index] = webResults[0]
                    isMerchantDetected = true
                    let categoryInferred = checkExistingCategory(merchants[index])
                    self.categories[index] = categoryInferred
                    if categories[index].isEmpty {
                        self.createKGRequest(input: webResults[0], index: index)
                    } else{
                        checkedReloadView()
                    }
                }
            }
        }
        if !isMerchantDetected{    // no merchant detected, hence no category
            checkedReloadView()
        }
    }
    
    
    // For a merchant name, check if there is already a category associated with it
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
    
    
    
    /**
     *Analyze Web
     */
    func analyzeWeb(json: JSON) -> [String]? {
        var results: [String]? = nil
        var temp:[String] = []
        if let responseArray = json["responses"].array{
            for responseDict in responseArray {
                if let webArray = responseDict["webDetection"]["webEntities"].array {
                    for webDict in webArray{
                        if let webResult = webDict["description"].string{
                            temp.append(webResult)
                        }
                    }
                }
            }
        }
        if !temp.isEmpty{
            results = temp
        }
        return results
    }
    
    
    /**
     *Analyze Logo
     */
    func analyzeLogo(json: JSON) -> String? {
        var result: String? = nil
        if let responseArray = json["responses"].array{
            for responseDict in responseArray {
                if let logo: String = responseDict["logoAnnotations"][0]["description"].string{
                    result = logo
                }
            }
        }
        return result
    }
    
    
    /**
     *Analyze category
     */
    func analyzeCategory(json: JSON, index: Int) {
        var results = [String?]()
        if let responseArray = json["itemListElement"].array{
            for responseDict in responseArray {
                if let category: String = responseDict["result"]["description"].string{
                    results.append(category)
                    //detectedCategoty = category
                }
            }
        }
        if !results.isEmpty{
            if let topMatch = results[0]{
                categories[index] = topMatch
                print("final category is")
                print(topMatch)
            }
        }
        if index == imagesProcessing.count - 1{
            self.reloadView()
        }
    }
    
    
    
    /**
     *Analyze Date
     */
    func analyzeDate(json: JSON) -> Date? {
        var date: Date? = nil
        if let responseArray = json["responses"].array{
            for responseDict in responseArray {
                let ocrTxt: String! = responseDict["textAnnotations"][0]["description"].string
                date = retrieveDate(input: ocrTxt)
            }
        }
        print("final date is")
        if let theDate = date {
            print(theDate)
        }
        return date
    }
    
    
    func retrieveDate(input: String) -> Date? {
        var results = [Date]()
        var returnDate:Date? = nil
        let chrono = Chrono.shared
        var components = input.characters.split(separator: "\n").map(String.init)
        for i in 0..<components.count {
            if let date = chrono.dateFrom(naturalLanguageString: components[i]){
                results.append(date)
            }
        }
        if let min = results.min(){
            returnDate = min
        }
        return returnDate
    }
    
    
    /**
     *Analyze Amount
     */
    func analyzeAmount(json: JSON) -> Double {
        
        let finalAmount = analyzeAmountByLocation(json: json)
        print("final amount is")
        print (finalAmount)
        return finalAmount
    }
    
    
    func analyzeAmountByLocation(json: JSON) -> Double{
        var returnAmount:Double = -1.0
        var results = [Double]()
        
        if let responseArray = json["responses"].array{
        for responseDict in responseArray {
        if let textArray = responseDict["textAnnotations"].array{
            for (index, _) in textArray.enumerated() {
                let descriptionText = textArray[index]["description"].string
                if descriptionText?.lowercased().range(of:"total") != nil
                    && (descriptionText?.characters.count)! < 50
                    && descriptionText?.lowercased().range(of:"subtotal") == nil{
                            
                    let yfloor = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
                    let yceiling = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
                    let yrightEdge = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
                    let result = retrieveAmountByLocation(yfloor: yfloor!, yceiling: yceiling!,
                                                          yrightEdge: yrightEdge!, json: json)
                    results.append(result)
                }
            }
        }}}
        
        if let max = results.max(){
            returnAmount = max
        }
        return returnAmount
    }
    
    
    func retrieveAmountByLocation(yfloor: Int, yceiling: Int, yrightEdge: Int, json: JSON) -> Double {
        var returnAmount:Double = -1.0
        var candidateText = ""
        
        if let responseArray = json["responses"].array{
        for responseDict in responseArray {
        if let textArray = responseDict["textAnnotations"].array{
            for (index, _) in textArray.enumerated() {
                let yfloorCandidate = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
                let yceilingCandidate = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
                let yrightEdgeCandidate = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
                if abs(yfloor - yfloorCandidate!) < 20 && abs(yceiling - yceilingCandidate!) < 20
                    && yrightEdge < yrightEdgeCandidate!{
                    candidateText = candidateText + textArray[index]["description"].string! + " "
                }
            }
        }}}
        
        returnAmount = retrieveAmount(input: candidateText)
        if returnAmount == -1{
            candidateText = candidateText.removingWhitespaces()
            returnAmount = retrieveAmount(input: candidateText)
        }
        return returnAmount
    }
    
    
    
    func analyzePureTextAmount(ocrTxt: String) -> Double {
        
        var returnAmount:Double = -1.0
        
        // break the ocr text in lines
        var ocrTextByLines:[String] = []
        ocrTxt.enumerateLines { (line, stop) -> () in
            ocrTextByLines.append(line)
        }
        
        for (index, item) in ocrTextByLines.enumerated(){
            if item.lowercased().range(of:"total") != nil &&
                item.lowercased().range(of:"subtotal") == nil {
                // get the amount that correspond to total
                let amount = self.retrieveAmount(input: item)
                if amount != -1 {
                    print("detected amount: \(amount)")
                    returnAmount = amount
                }
                else {
                    let element = ocrTextByLines[index + 1]
                    let newAmount = self.retrieveAmount(input: element)
                    print("detected amount: \(newAmount)")
                    returnAmount = newAmount
                }
            }
        }
        return returnAmount
    }
    
    
    func retrieveAmount(input: String) -> Double {
        // split the line in words
        var components = input.characters.split(separator: " ").map(String.init)
        for i in 0..<components.count {
            if let doubleValue = Double(components[i]){
                return doubleValue
            }
            else {         // Remove the currency sign that hinders the amount to be parsed
                components[i].remove(at: components[i].startIndex)
                if let doubleValue = Double(components[i]){
                    return doubleValue
                }
            }
        }
        return -1          //No legit amount detected
    }

}
