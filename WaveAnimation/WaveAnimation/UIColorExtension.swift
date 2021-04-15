//
//  UIColorExtension.swift
//  WaveAnimation
//
//  Created by Zhenyu Shi on 4/15/21.
//

import UIKit

extension UIColor{
    convenience init(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat, _ a : CGFloat = 1) {
        let red = r / 255.0
        let green = g / 255.0
        let blue = b / 255.0
        self.init(red: red, green: green, blue: blue, alpha: a)
    }
}
