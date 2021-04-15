//
//  CellImage.swift
//  CoreAnimation
//
//  Created by 石震宇 on 2021/4/14.
//

import UIKit

class CellImage: NSObject {
    
    enum CellType {
        case Star
        case Good
        case Sparkle
    }
    
    class var instance: CellImage{
        get{
            struct Singleton{
                static let instance = CellImage()
            }
            return Singleton.instance
        }
    }
}


extension CellImage{
    func getImage(type: CellType) -> UIImage?{
        switch type {
        case .Star:
            return getStarImage()
        case .Good:
            return getGoodImage()
        case .Sparkle:
            return getSparkcleImage()
        default:
            return nil
        }        
    }
    private func getStarImage() -> UIImage?{
        return UIImage(systemName: "star.fill")?.withTintColor(.yellow, renderingMode: .alwaysTemplate)
    }
    private func getGoodImage() -> UIImage?{
        return UIImage(systemName: "hand.thumbsup.fill")?.withTintColor(.yellow, renderingMode: .alwaysTemplate)
    }
    private func getSparkcleImage() -> UIImage?{
        return UIImage(systemName: "sparkle")?.withTintColor(.red, renderingMode: .alwaysTemplate)
    }
}
