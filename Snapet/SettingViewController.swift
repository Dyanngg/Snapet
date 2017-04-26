//
//  SettingViewController.swift
//  Snapet
//
//  Created by Duan Li on 4/25/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import Photos
import AVKit
import DKImagePickerController

class SettingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileView: UIImageView!
    var imageInProcess = UIImage()
    let imagePicker = UIImagePickerController()
    let pickerController = DKImagePickerController()
    var images: [NSManagedObject] = []
    
    @IBAction func uploadProfile(_ sender: Any) {
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profileView.image = pickedImage
//            guard let appDelegate =
//                UIApplication.shared.delegate as? AppDelegate else {
//                    return
//            }
//            // 1
//            let managedContext =
//                appDelegate.persistentContainer.viewContext
//            // 2
//            let entity =
//                NSEntityDescription.entity(forEntityName: "User",
//                                           in: managedContext)!
//            
//            let expense = NSManagedObject(entity: entity,
//                                          insertInto: managedContext)
//            // 3
//            print("convert image to data")
//            let imgData = UIImageJPEGRepresentation(pickedImage, 1)
//            expense.setValue(imgData, forKeyPath: "image")
//            // 4
//            do {
//                try managedContext.save()
//                print("save data")
//            } catch let error as NSError {
//                print("Could not save. \(error), \(error.userInfo)")
//            }
//            
//            
//            let fetchRequest =
//                NSFetchRequest<NSManagedObject>(entityName: "User")
//            do {
//                images = try managedContext.fetch(fetchRequest)
//                print("fetch data")
//            } catch let error as NSError {
//                print("Could not fetch. \(error), \(error.userInfo)")
//            }
//            if let photoinData = images[0].value(forKey: "image") as? UIImage{
//                profileView.image = photoinData
//                print("convert date to image")
//            }
            
            
//            imageInProcess = pickedImage
//            isOCR = true
            // Base64 encode the image and create the request
//            let binaryImageData = base64EncodeImage(pickedImage)
//            createRequest(with: binaryImageData)
        }
        dismiss(animated: true, completion: nil)
//        analyzeInProgress = true
//        showProgressBar()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
