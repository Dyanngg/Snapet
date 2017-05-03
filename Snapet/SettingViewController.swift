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


class SettingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var profileView: UIImageView!
    @IBOutlet weak var budgetField: UITextField!
    var imageInProcess = UIImage()
    let imagePicker = UIImagePickerController()
    let pickerController = DKImagePickerController()
    var images: [NSManagedObject] = []
    var amount = 0.0
    
    @IBAction func uploadProfile(_ sender: Any) {
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }

    @IBAction func saveBudget(_ sender: Any) {
        if let budget = budgetField.text {
            if let budgetAmount = Double(budget) {
                amount = budgetAmount
                MainPageController.budgetNum = amount.description
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        budgetField.resignFirstResponder()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // save image to core data
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let managedContext =
                appDelegate.persistentContainer.viewContext
            let entity =
                NSEntityDescription.entity(forEntityName: "User",
                                           in: managedContext)!
            let expense = NSManagedObject(entity: entity,
                                          insertInto: managedContext)
            let imgData = UIImageJPEGRepresentation(pickedImage, 1)
            expense.setValue(imgData, forKeyPath: "image")
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            fetchAndDisplay()
        } else {
            print("something wrong")
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func fetchAndDisplay() {
        // fetch image from core data and display it
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "User")
        do {
            images = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        if !images.isEmpty {
            if let photoinData = images[images.count - 1].value(forKey: "image") as? Data{
                profileView.maskCircle(anyImage: UIImage(data: photoinData)!)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        //        DeleteAllData()
        fetchAndDisplay()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        let barColor = UIColor(red:87/255, green:97/255, blue:112/255, alpha:1.0)
        self.navigationController?.navigationBar.barTintColor = barColor
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AppleGothic", size: 20)!]
        budgetField.delegate = self
        budgetField.text = MainPageController.budgetNum
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
