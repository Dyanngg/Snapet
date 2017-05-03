//
//  ExtensionLibrary.swift
//  Snapet
//
//  Created by Yang Ding on 5/1/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import Foundation

// Extension for making a UIImageView round
extension UIImageView {
    public func maskCircle(anyImage: UIImage) {
        self.contentMode = UIViewContentMode.scaleAspectFill
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        // make square(* must to make circle),
        // resize(reduce the kilobyte) and fix rotation.
        self.image = anyImage
    }
}


// Extension for animating the fade in and fade out of UIView
extension UIView{
    func fadeIn1(withDuration duration: TimeInterval = 0.25) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 })
    }
    
    func fadeIn2(withDuration duration: TimeInterval = 0.7) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 })
    }
    
    func fadeIn3(withDuration duration: TimeInterval = 1.2) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 0.25) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0.0 })
    }
}


// Extension for string manipulation
extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}


// Extension for Dictionary
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


// Extension for making a solid color UIImage
public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

public extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}
