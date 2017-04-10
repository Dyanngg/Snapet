//
//  TableViewController.swift
//  Snapet
//
//  Created by Duan Li on 3/27/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import MobileCoreServices

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}


class TableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    @IBAction func uploadImage(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
        useCamera = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeleteAllData()
        imagePicker.delegate = self
        title = "The List"
//        tableView.register(ExpenseTableViewCell.self,
//                           forCellReuseIdentifier: "Cell")
        self.tableView.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return expenses.count
//        return test.count
    }

    /*
     Fetching from Core Data
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Expense")
        
        //3
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
        self.tableView.reloadData()
        print("test4")
        
    }
    
    // display the constraints obtained from setting page
    @IBAction func myUnwindAction(_ unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.source as? DetailViewController {
            expenses = svc.expenses
            print("expenses is assigned")
        }
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("printing expenses: ")
        print(expenses)
        let expense = expenses[indexPath.row]
        print("printing expense: ")
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let cell = dequeued as! ExpenseTableViewCell
        let amountLabel = expense.value(forKeyPath: "amount") as? Double
        let dateLabel = expense.value(forKeyPath: "date") as? Date
        let categoryLabel = expense.value(forKeyPath: "category") as? String
        let merchantLabel = expense.value(forKeyPath: "merchant") as? String
        if (categoryLabel != nil) {
            cell.categoryLabel?.text = categoryLabel
        }
//        else {
//            cell.categoryLabel?.text = ""
//        }
        if (merchantLabel != nil) {
            cell.merchantLabel.text = merchantLabel
        }
//        else {
//            cell.merchantLabel?.text = ""
//        }
        if (amountLabel != nil) {
            cell.amountLabel?.text = "$\(String(amountLabel!))"
        }
//        else {
//            cell.amountLabel?.text = ""
//        }
        if (dateLabel != nil) {
            let date = dateLabel!.description
            cell.dateLabel?.text = date.substring(to: date.index(date.startIndex, offsetBy: 10))
        }
//        else {
//            cell.dateLabel?.text = ""
//        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB Google vision API limit
        if (imagedata!.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
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
//                    [
//                        "type": "LOGO_DETECTION",
//                        "maxResults": 5
//                    ],
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
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            self.analyzeResults(data)
        }
        task.resume()
        //        let viewController:DetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "test") as! DetailViewController
        //        let s = UIStoryboardSegue(identifier: "trial", source: self, destination: viewController)
        //        self.prepare(for: s, sender: nil)
    }
    
    
    
    func createKGRequest(input:String) {
        var finalURLString = googleKGURL + "?query=" + input + "&key=" + googleAPIKey + "&limit=5"
//        let finalURL = URL(string: finalURLString)
//        var request = URLRequest(url: finalURL!)
        finalURLString = NSString(string: finalURLString).addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let urlComponents = URLComponents(string: finalURLString)
        //print(urlComponents)
        if let finalURL = urlComponents?.url{
            print("url is")
            print(finalURL)
            var request = URLRequest(url: finalURL)
        
            //request.addValue(input, forHTTPHeaderField: "query")
            //request.addValue(googleAPIKey, forHTTPHeaderField: "key")
            request.httpMethod = "GET"
            DispatchQueue.global().sync { self.runKGRequest(request) }
            //self.runKGRequest(request)
        }
        
    }
    
    
    func runKGRequest(_ request: URLRequest) {
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
                self.analyzeCategory(json: KGjson)
            }
        }
        task.resume()
    }
    
    
    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Go"{
            // get a reference to the second view controller
            let secondViewController = segue.destination as! DetailViewController
            // set the variables in the second view controller with the String to pass
//            if (detectedAccount != nil) {
//                secondViewController.account = detectedAccount!}
//            if (detectedCategory != nil) {
//                secondViewController.category = detectedCategory!}
//            if (detectedAmount != nil) {
//                secondViewController.amount = detectedAmount}
//            if (detectedDate != nil) {
//                secondViewController.date = detectedDate!}
//            secondViewController.amount = detectedAmount
//            secondViewController.date = detectedDate
//            if (detectedMerchant != nil) {
//                secondViewController.merchant = detectedMerchant!}
            if let amountDetected = detectedAmount {
                secondViewController.amount = amountDetected
            }
            if let dateDetected = detectedDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let inputDate = dateFormatter.string(from: dateDetected)
                let inputDate2 = dateFormatter.date(from: inputDate)
                print("dateDetected date is \(dateDetected)")
                print("inputDate2 date is \(inputDate2)")
//                if (inputDate.characters.count >= 10) {
//                    let temp1 = inputDate.substring(to: inputDate.index((inputDate.startIndex), offsetBy: 10))
//                    let d = dateFormatter.date(from:temp1)!
//                    let calendar = Calendar.current
//                    let components = calendar.dateComponents([.year, .month, .day], from: d)
//                    let finalDate = calendar.date(from:components)
//                    inputDate = dateFormatter.string(from: finalDate!)
//                    print("inputDate2 date is \(inputDate)")
//                }
                dateFormatter.dateFormat = "MMM dd, yyyy"
                let outputDate = dateFormatter.string(from: inputDate2!)
                let outputDate2 = dateFormatter.date(from: outputDate)
                print("output date is \(outputDate)")
                print("output date2 is \(outputDate2)")
                secondViewController.date = outputDate2
            }
            if let accountDetected = detectedAccount {
                secondViewController.account = accountDetected
            }
            if let categoryDetected = detectedCategory {
                secondViewController.category = categoryDetected
            }
            if let merchantDetected = detectedMerchant {
                secondViewController.merchant = merchantDetected
            }
            print("prepare for segue")
            print("detected amount = \(String(describing: detectedAmount))")
            print("detected date = \(String(describing: detectedDate))")
            print("detected cat = \(String(describing: detectedCategory))")
            detectedMerchant = ""
            detectedDate = nil
            detectedAmount = 0.0
            detectedAccount = 0
            detectedCategory = ""
        }
    }
    
    
    
    func analyzeResults(_ dataToParse: Data) {
        
        var isMerchantDetected = false
        
        // Update UI on the main thread
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                print( "Error code \(errorObj["code"]): \(errorObj["message"])")
            } else {
                // Parse the response
                print(json)
                
                self.detectedAmount = self.analyzeAmount(json: json)
                
                if let merchantDetected = self.analyzeLogo(json: json){
                    if let webResults = self.analyzeWeb(json: json){
                        if webResults.contains(merchantDetected){
                            self.detectedMerchant = merchantDetected
                            self.createKGRequest(input: merchantDetected)
                            isMerchantDetected = true
                        }
                    }
                }
                
                if !isMerchantDetected{
                    if let webResults = self.analyzeWeb(json: json){
                        self.detectedMerchant = webResults[0]
                        self.createKGRequest(input: webResults[0])
                        isMerchantDetected = true
                    }
                }
                
                
                //let chrono = Chrono.shared
                if let dateDetected = self.analyzeDate(json: json){
                    self.detectedDate = dateDetected
                }
                //print(date)
                print("set detected amount = \(String(describing: self.detectedAmount))")
                print("set detected date = \(String(describing: self.detectedDate))")
            }
        if(!isMerchantDetected){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "Go", sender: nil)
            }
        }
        
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
    func analyzeCategory(json: JSON) {
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
                detectedCategory = topMatch
                print("final category is")
                print(topMatch)
            }
        }
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "Go", sender: nil)
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
                //print("ocrtext is")
                //print(ocrTxt)
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
                //print("found")
                //print(components[i])
                //returnDate = date.description
                //let result = chrono.parsedResultsFrom(naturalLanguageString: components[i], referenceDate: nil)
                //print(result)
                //print("result is")
                //print(date.description)
                results.append(date)
            }
        }
        if let min = results.min(){
            returnDate = min
        }
//        if returnDate != nil {
//            var date = returnDate!.description
//        }
        return returnDate
    }
    
    
    /**
     *Analyze Amount
     */
    func analyzeAmount(json: JSON) -> Double {
        //        var finalAmount:Double = -1.0
        
        //        if let responseArray = json["responses"].array{
        //            for responseDict in responseArray {
        //                let ocrTxt: String! = responseDict["textAnnotations"][0]["description"].string
        //                let initialResult = self.analyzePureTextAmount(ocrTxt: ocrTxt)
        //
        //                // The simple approach worked
        //                if initialResult != -1{
        //                    finalAmount = initialResult
        //                }
        //                // Analyze based ont location
        //                else {
        let finalAmount = analyzeAmountByLocation(json: json)
        //                }
        //            }
        //        }
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
                            //print("location is")
                            //print(textArray[index]["boundingPoly"]["vertices"][0]["x"])
                            let yfloor = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
                            let yceiling = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
                            let yrightEdge = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
                            let result = retrieveAmountByLocation(yfloor: yfloor!, yceiling: yceiling!, yrightEdge: yrightEdge!, json: json)
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
                        if abs(yfloor - yfloorCandidate!) < 20 && abs(yceiling - yceilingCandidate!) < 20 && yrightEdge < yrightEdgeCandidate!{
                            candidateText = candidateText + textArray[index]["description"].string! + " "
                        }
                    }
                }}}
        //print("candidateText is")
        //print(candidateText)
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
                    //print("index is: \(index)")
                    let element = ocrTextByLines[index + 1]
                    //print(element)
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
                // Remove the currency sign that hinders the amount to be parsed
            else {
                components[i].remove(at: components[i].startIndex)
                if let doubleValue = Double(components[i]){
                    return doubleValue
                }
            }
        }
        //No legit amount detected
        return -1
        //        var returnResult:Double = -1.0
        //        let scanner = Scanner(string: input)
        //        scanner.scanDouble(&returnResult)
        //        return returnResult
    }

}
