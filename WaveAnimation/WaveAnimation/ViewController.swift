//
//  ViewController.swift
//  WaveAnimation
//
//  Created by Zhenyu Shi on 4/15/21.
//

import UIKit

class ViewController: UIViewController {

    var waveView: WaveView!
    var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建文本标签
        label = UILabel()
        label.text = "正在加载中......"
        label.textColor = .black
        label.textAlignment = .center
        label.frame = CGRect(x: (screenWidth() * 0.5 - 100), y: 0, width: 200, height: 50)
        label.center = view.center
        
        let progressBar = UISlider()
        progressBar.frame = CGRect(x: 0 , y: screenHeight() * 0.9, width: screenWidth(), height: 50)
        progressBar.maximumTrackTintColor = .lightGray
        progressBar.minimumTrackTintColor = .white
        progressBar.minimumValue = 0
        progressBar.maximumValue = 100
        progressBar.addTarget(self, action: #selector(valueDidChange(sender:)), for: .valueChanged)
        // 创建波浪视图
        waveView = WaveView(frame: CGRect(x: 0, y: screenHeight() * 0.9, width: screenWidth(),
                                             height: 130))
        //       // 波浪动画回调
        //       waveView.closure = {centerY in
        //           // 同步更新文本标签的y坐标
        //           label.frame.origin.y = waveView.frame.height + centerY - 55
        //       }

        // 添加视图
        self.view.addSubview(waveView)
        self.view.addSubview(label)
        self.view.addSubview(progressBar)
        // 开始播放波浪动画
        waveView.startWave()
   }
    
    @objc func valueDidChange(sender: UISlider){
        let progress = sender.value / sender.maximumValue
        label.text = "正在加载中\(Int(progress * 100))%......"
        print("progress: \(progress)")
        var frame = waveView.frame
        print("new Y: \(screenHeight() * CGFloat(0.9 * (1 - progress)))")
        frame.origin.y = screenHeight() * CGFloat(0.9 * (1 - progress))
        frame.size.height = screenHeight() - frame.origin.y + 150
        waveView.frame = frame
    }
   // 返回当前屏幕宽度
   func screenWidth() -> CGFloat {
       return UIScreen.main.bounds.size.width
   }
    func screenHeight() -> CGFloat{
        return UIScreen.main.bounds.height
    }

}

