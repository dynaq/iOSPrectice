//
//  ViewController.swift
//  H264Test
//
//  Created by Zhenyu Shi on 4/15/21.
//

import UIKit
import AVFoundation

let screenWith = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class ViewController: UIViewController {
    
    private var priviewView: UIView?
    private var recordingButton: UIButton?
    fileprivate var session: AVCaptureSession!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initialView()
        initialCamera()
        
    }
    
    func initialView(){
        priviewView = UIView(frame: CGRect(x: 0, y: 0, width: screenWith, height: screenHeight - 100 - 44))
//        priviewView?.backgroundColor = .black
        recordingButton = UIButton(frame: CGRect(x: screenWith * 0.5 - 40, y: screenHeight - 80 - 44, width: 80, height: 80))
        recordingButton?.setBackgroundImage(UIImage(systemName: "record.circle"), for: .normal)
        recordingButton?.setBackgroundImage(UIImage(systemName: "record.circle.fill"), for: .selected)
        recordingButton?.tintColor = .red
        
        recordingButton?.addTarget(self, action: #selector(didClickButton(sender:)), for: .touchUpInside)
        
        self.view.addSubview(priviewView!)
        self.view.addSubview(recordingButton!)
    }
    
    func initialCamera(){
        let cameras = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInMicrophone], mediaType: .video, position: .unspecified).devices
        guard !cameras.isEmpty else {
            print("no camera")
            return
        }
        let testFront = cameras.first { (device) -> Bool in
            device.position == .front
        }
        guard let frontCamera = testFront else {
            print("no front camera")
            return
        }
        
        //make input
        var input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: frontCamera)
        } catch {
            print("make input fails: \(error)")
            return
        }
        do{
            try input.device.lockForConfiguration()
            if input.device.isFocusModeSupported(.continuousAutoFocus){
                input.device.focusMode = .continuousAutoFocus
            }
            if input.device.isLowLightBoostSupported{
                input.device.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            if input.device.isExposureModeSupported(.continuousAutoExposure){
                input.device.exposureMode = .continuousAutoExposure
            }
            if input.device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance){
                input.device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            input.device.unlockForConfiguration()
        }catch{
            print(error)
        }
        
        //output
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "ACVideoCaptureOutputQueue", qos: .default, autoreleaseFrequency: .workItem, target: nil)
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [:]
        output.alwaysDiscardsLateVideoFrames = true
        
        //session
        session = AVCaptureSession()
        session.usesApplicationAudioSession = false
        guard session.canAddInput(input) else{
            print("cannot add input")
            return
        }
        session.addInput(input)
        guard session.canAddOutput(output) else{
            print("cannot add output")
            return
        }
        session.addOutput(output)
        guard session.canSetSessionPreset(.high) else {
            print("cannot add preset .hd1280x720")
            return
        }
        session.sessionPreset = .high
        
        //connecttion
        guard let connection = output.connection(with: .video) else{
            print("cannot make connection")
            return
        }
        if connection.isVideoOrientationSupported{
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported{
            connection.isVideoMirrored = true
        }
        
        //layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = priviewView!.frame
        if let layerConnection = layer.connection, layerConnection.isVideoOrientationSupported{
            layerConnection.videoOrientation = .portrait
        }
        layer.videoGravity = .resizeAspectFill
        priviewView?.layer.addSublayer(layer)
    }
    
    func addNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(avCaptureSessionRuntimeError(noti:)), name: .AVCaptureSessionRuntimeError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(avCaptureSessionWasInterrupted(noti:)), name: .AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(avCaptureSessionInterruptionEnded(noti:)), name: .AVCaptureSessionInterruptionEnded, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}
extension ViewController{
    @objc func didClickButton(sender: UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            startCapture()
        }
        else{
            stopCapture()
        }
    }
    
    @objc func avCaptureSessionRuntimeError(noti: Notification){
        print("AVCaptureSessionRuntimeError")
    }
    @objc func avCaptureSessionWasInterrupted(noti: Notification){
        print("AVCaptureSessionWasInterrupted")
    }
    @objc func avCaptureSessionInterruptionEnded(noti: Notification){
        print("AVCaptureSessionInterruptionEnded")
    }
}
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func startCapture(){
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else{
            print("no authorized")
            return
        }
        session.startRunning()
    }
    
    func stopCapture(){
        session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("droped")
    }
}
