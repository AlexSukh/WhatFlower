//
//  ViewController.swift
//  WhatFlower
//
//  Created by Alex Sukhitashvili on 11/12/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var label: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
         
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
             
             imageView.image = userPickedImage
             guard let ciimage = CIImage(image: userPickedImage) else {
                         fatalError("Could not convert to ci image")
                     }
             detect(image: ciimage)
         }
         
         imagePicker.dismiss(animated: true, completion: nil)
         
         
     }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed.")
            
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            
            if let firstResult = result.first {
                print(firstResult)
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)

              
            }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])

        } catch {
            print(error)
            
        }
        
        
        
        
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : flowerName, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]

        AF.request(wikipediaURl, method: .get, parameters: parameters)
            .responseJSON { (response) in
                let flowerJSON : JSON = JSON(response.data!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.label.text = flowerDescription
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
            }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
          present(imagePicker, animated: true, completion: nil)
          
      }
    

}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
