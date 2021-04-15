//
//  RectangleViewController.swift
//  CoreAnimation
//
//  Created by 石震宇 on 2021/4/14.
//

import UIKit

class RectangleViewController: UIViewController {

    var layer: CAEmitterLayer!
    var cell: CAEmitterCell!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        createEmitLayer()
        createCell()
        startAnimation()
    }
    
    
}

extension RectangleViewController{
    
    func createEmitLayer(){
        layer = CAEmitterLayer()
        layer.frame = view.frame
        layer.emitterShape = .rectangle
        layer.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        layer.emitterSize = view.frame.size
        layer.emitterMode = .surface
        view.layer.addSublayer(layer)
    }
    
    func createCell(){
        cell = CAEmitterCell()
        cell.name = "StarCell"
        cell.birthRate = 20
        cell.lifetime = 3
        cell.velocity = 30
        cell.velocityRange = 100
        cell.xAcceleration = 15
        cell.yAcceleration = 30
        cell.zAcceleration = 45
        cell.scale = 0.1
        cell.scaleRange = 0.5
        cell.scaleSpeed = 0.3
//        cell.emissionLongitude = CGFloat(Double.pi / 2)
//        cell.emissionRange = CGFloat(Double.pi / 4)
        cell.contents = CellImage.instance.getImage(type: .Star)?.cgImage
        layer.emitterCells = [cell]
    }
    
    func startAnimation(){
        let animation = CABasicAnimation(keyPath: "cell.scale")
        animation.fromValue = 0.2
        animation.toValue = 0.5
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: .default)
        CATransaction.begin()
        CATransaction.disableActions()
        layer.add(animation, forKey: nil)
        CATransaction.commit()
    }
    
}
