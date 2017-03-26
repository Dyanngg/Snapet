//
//  ViewController.swift
//  Snapet
//
//  Created by Yang Ding on 2/19/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var amount = 3.0
    var merchant = ""
    var account = ""
    var date = "2017-01-27"
    var category = "Food"
    var expenses: [NSManagedObject] = []
    var savedAmount = Float(-1.0)
    var fetchedAmount = Float(-1.0)
    var test = ["a", "b"]

    let session = URLSession.shared
    let imagePicker = UIImagePickerController()
    let googleAPIKey = "AIzaSyBmcPFpapjEug_lKki4qnuiN-XYvE3xVYQ"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func uploadImage(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        title = "The List"
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "Cell")
        self.tableView.reloadData()
        print("test0")
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
            let expense = expenses[expenses.count - 1]
            fetchedAmount = (expense.value(forKeyPath: "amount") as? Float)!
            print("fetched amount = \(fetchedAmount)")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        self.tableView.reloadData()
        print("test4")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        print("test3")
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        print("test2")
        return test.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure the cell...
        
        cell.textLabel!.text = test[indexPath.row]
        print("test1")
        
        return cell
    }
    
    // display the constraints obtained from setting page
    @IBAction func myUnwindAction(_ unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.source as? DetailViewController {
            expenses = svc.expenses
            print("expenses is assigned")
        }
    }
    
    
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
                    [
                        "type": "LOGO_DETECTION",
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
        self.performSegue(withIdentifier: "Detail", sender: nil)
    }
    
    
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                print( "Error code \(errorObj["code"]): \(errorObj["message"])")
            } else {
                // Parse the response
                // print("This is the beginning of JSON response\n")
                print(json)
                
                let amount = self.analyzeAmount(json: json)
            }
        })
    }
    
    
    func analyzeAmount(json: JSON) -> Float {
        
        var finalAmount:Float = -1
        
        if let responseArray = json["responses"].array{
            for responseDict in responseArray {
//                let ocrTxt: String! = responseDict["textAnnotations"][0]["description"].string
//                let initialResult = self.analyzePureTextAmount(ocrTxt: ocrTxt)
//                
//                // The simple approach worked
//                if initialResult != -1{
//                    finalAmount = initialResult
//                }
//                // Analyze based ont location
//                else {
                    finalAmount = analyzeAmountByLocation(json: json)
//                }
            }
        }
        print("final amount is")
        print (finalAmount)
        return finalAmount
    }
    
    
    func analyzeAmountByLocation(json: JSON) -> Float{
        var returnAmount:Float = -1
        
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
                    returnAmount = result
                }
            }
        }}}
        return returnAmount
    }
    
    
    func retrieveAmountByLocation(yfloor: Int, yceiling: Int, yrightEdge: Int, json: JSON) -> Float {
        var returnAmount:Float = -1
        
        if let responseArray = json["responses"].array{
        for responseDict in responseArray {
        if let textArray = responseDict["textAnnotations"].array{
            for (index, _) in textArray.enumerated() {
                let yfloorCandidate = textArray[index]["boundingPoly"]["vertices"][0]["y"].int
                let yceilingCandidate = textArray[index]["boundingPoly"]["vertices"][2]["y"].int
                let yrightEdgeCandidate = textArray[index]["boundingPoly"]["vertices"][2]["x"].int
                if abs(yfloor - yfloorCandidate!) < 20 && abs(yceiling - yceilingCandidate!) < 20 && yrightEdge < yrightEdgeCandidate!{
                    let candidateText = textArray[index]["description"].string!
                    returnAmount = retrieveAmount(input: candidateText)
                }
            }
        }}}
        return returnAmount
    }
    
    
    
    func analyzePureTextAmount(ocrTxt: String) -> Float {
        
        var returnAmount:Float = -1
        
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
    
    
    func retrieveAmount(input: String) -> Float {
        // split the line in words
        var components = input.characters.split(separator: " ").map(String.init)
        for i in 0..<components.count {
            if let floatValue = Float(components[i]){
                return floatValue
            }
            // Remove the currency sign that hinders the amount to be parsed
            else {
                components[i].remove(at: components[i].startIndex)
                if let floatValue = Float(components[i]){
                    return floatValue
                }
            }
        }
        //No legit amount detected
        return -1
    }


}

//extension ViewController: UITableViewDataSource {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        // 1
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView,
//                   numberOfRowsInSection section: Int) -> Int {
//        return expenses.count
//    }
//    
//    func tableView(_ tableView: UITableView,
//                   cellForRowAt indexPath: IndexPath)
//        -> UITableViewCell {
//            
//            let expense = expenses[indexPath.row]
//            let cell =
//                tableView.dequeueReusableCell(withIdentifier: "Cell",
//                                              for: indexPath)
//            print("table view is resetting")
////            cell.textLabel?.text =
////                expense.value(forKeyPath: "amount") as? String
//            cell.textLabel!.text = test[indexPath.row]
//            return cell
//    }
//}

