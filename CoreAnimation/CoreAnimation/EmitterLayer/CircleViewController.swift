//
//  CircleViewController.swift
//  CoreAnimation
//
//  Created by 石震宇 on 2021/4/14.
//

import UIKit

class CircleViewController: UIViewController {

    var layer: CAEmitterLayer!
    var cell: CAEmitterCell!
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.isUserInteractionEnabled = true
        view.backgroundColor = .white
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        imageView.center = view.center
        imageView.image = CellImage.instance.getImage(type: .Good)
        imageView.tintColor = .yellow
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        gesture.requiresExclusiveTouchType = true
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(gesture)
        view.addSubview(imageView)
        createSpark()
        createCell()
    }
    
    @objc func didTap(sender: Any){
        let animation = CAKeyframeAnimation()
        animation.keyPath = "transform.scale"
        animation.values = [1.5, 2, 0.8, 1.0]
        animation.calculationMode = .cubic
        animation.duration = 0.5
        animation.beginTime = 0
        
        let a2 = CAKeyframeAnimation()
        a2.duration = 0.5
        a2.keyPath = "transform.rotation.z"
        a2.values = [0, -Double.pi/4, 0]
        a2.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        a2.beginTime = 0
        let group = CAAnimationGroup()
        group.duration = 0.5
        group.animations = [animation]
        imageView.layer.add(group, forKey: nil)
        perform(#selector(startAnimation), with: nil, afterDelay: 0.25)

    }


}

extension CircleViewController{
    func createSpark(){
        layer = CAEmitterLayer()
        layer.position = CGPoint(x: imageView.frame.width / 2, y: imageView.frame.height / 2)
        layer.emitterSize = imageView.frame.size
        layer.emitterShape = .circle
        layer.emitterMode = .outline
        layer.renderMode = .oldestLast
        imageView.layer.addSublayer(layer)
    }
    
    func createCell(){
        cell = CAEmitterCell()
        cell.name = "cell";
        cell.alphaSpeed = -1
        cell.alphaRange = 0.1
        cell.lifetime = 1
        cell.lifetimeRange = 0.1
        cell.velocity = 40
        cell.velocityRange = 10
        cell.scale = 0.08
        cell.scaleRange = 0.02
        cell.contents = CellImage.instance.getImage(type: .Sparkle)?.withTintColor(.red, renderingMode: .alwaysTemplate).cgImage
        layer.emitterCells = [cell]
    }
    @objc func startAnimation(){
        layer.setValue(1000, forKeyPath: "emitterCells.cell.birthRate")
        layer.beginTime = CACurrentMediaTime()
        perform(#selector(stopAnimation), with: nil, afterDelay: 0.15)
    }
    @objc func stopAnimation(){
        layer.setValue(0, forKeyPath: "emitterCells.cell.birthRate")
        layer.removeAllAnimations()
    }
}
