//
//  UIColorExtensions.swift
//  Snapet
//
//  Created by Duan Li on 4/18/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import Foundation
import UIKit


extension UIColor {
    
    static func random( ofCount: Int) -> [ UIColor] {
        
        let redColor = UIColor(red: 219/255, green: 95/255, blue:56/255, alpha:1.0);
        let orangeColor = UIColor(red: 219/255, green: 140/255, blue:59/255, alpha:1.0);
        let greenColor = UIColor(red: 81/255, green: 179/255, blue:54/255, alpha:1.0);
        let blueColor = UIColor(red: 75/255, green: 115/255, blue:229/255, alpha:1.0);
        let pinkColor = UIColor(red: 188/255, green: 106/255, blue:231/255, alpha:1.0);
        let yellowColor = UIColor(red: 231/255, green:206/255, blue:106/255, alpha:1.0);
        let lightBlueColor = UIColor(red: 106/255, green:188/255, blue:231/255, alpha:1.0);
        let cyanColor = UIColor(red: 112/255, green:225/255, blue:224/255, alpha:1.0);
        
        let palette: NSArray = [redColor, orangeColor, greenColor, blueColor, pinkColor, yellowColor, lightBlueColor, cyanColor]
        
        var colors: [UIColor] = []

        for i in 0..<ofCount {

            var index = i;
            if index > 7{
                index = index % 7
            }
            let color = palette[index]
            colors.append(color as! UIColor)
        }
        
        return colors
    }
}

