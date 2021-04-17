//
//  ViewController.swift
//  H264Test
//
//  Created by Zhenyu Shi on 4/15/21.
//

import UIKit
import AVFoundation
import VideoToolbox

let screenWith = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class ViewController: UIViewController {
    
    private var priviewView: UIView?
    private var recordingButton: UIButton?
    fileprivate var session: AVCaptureSession!
    var compressSession: VTCompressionSession? = nil
    var isRecording: Bool = false
    
    let queue = DispatchQueue(label: "test.write.queue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    var semaphore = DispatchSemaphore(value: 1)
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
        guard session.canSetSessionPreset(.hd1280x720) else {
            print("cannot add preset .hd1280x720")
            return
        }
        session.sessionPreset = .hd1280x720
        
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
        prepareCompresData()
    }
    
    func stopCapture(){
        session.stopRunning()
        stopCompress()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let session = compressSession else{
            print("session empty")
            return
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{
            print("get image buffer fails")
            return
        }
        guard VTCompressionSessionEncodeFrame(session, imageBuffer: imageBuffer, presentationTimeStamp: CMTime.invalid, duration: CMTime.invalid, frameProperties: nil, infoFlagsOut: nil, outputHandler: { (status, flag, sampleBuffer) in
                print("status: \(status), flag: \(flag), sampleBuffer: \(sampleBuffer)")
        }) == 0 else{
            print("VTCompressionSessionEncodeFrame error")
            return
        }
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("droped")
    }
    
    func prepareCompresData(){
        let callback: VTCompressionOutputCallback = { outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer in
            guard let buffer = sampleBuffer else{
                print("no buffer")
                return
            }
            guard let pointer = outputCallbackRefCon?.assumingMemoryBound(to: ViewController.self) else {
                print("cannot convert self")
                return
            }

            let encoder = Unmanaged<ViewController>.fromOpaque(pointer).takeUnretainedValue()
            let header: [CChar] = [0x00, 0x00, 0x00, 0x01]
            let headerSize: size_t = MemoryLayout.size(ofValue: header) - 1
            let headerData = Data(bytes: header, count: headerSize)
            let arrays = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true)
            let dic = Unmanaged<CFDictionary>.fromOpaque(CFArrayGetValueAtIndex(arrays, 0)).takeUnretainedValue()
            let key = kCMSampleAttachmentKey_NotSync
            let isKeyFrame = CFDictionaryGetValue(dic, Unmanaged<CFString>.passUnretained(key).toOpaque())
            if isKeyFrame != nil{
                print("key frame")
                guard let formatDesceiption = CMSampleBufferGetFormatDescription(buffer) else{
                    print("no description")
                    return
                }
                //SPS
                var sParameterSetSize: Int = 0
                var sParameterSetCount: Int = 0
                var sParamaterSet: UnsafePointer<UInt8>? = nil
                guard CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesceiption, parameterSetIndex: 0, parameterSetPointerOut: &sParamaterSet, parameterSetSizeOut: &sParameterSetSize, parameterSetCountOut: &sParameterSetCount, nalUnitHeaderLengthOut: nil) == 0 else{
                    print("canot insert SPS Data")
                    return
                }
                //PPS
                var pParameterSetSize: Int = 0
                var pParameterSetCount: Int = 0
                var pParamaterSet: UnsafePointer<UInt8>? = nil
                guard CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesceiption, parameterSetIndex: 1, parameterSetPointerOut: &pParamaterSet, parameterSetSizeOut: &pParameterSetSize, parameterSetCountOut: &pParameterSetCount, nalUnitHeaderLengthOut: nil) == 0 else{
                    print("canot insert PPS Data")
                    return
                }
                guard let spsPoint = sParamaterSet else {
                    print("sParamaterSet == nil")
                    return
                }
                let sps = Data(bytes: spsPoint, count: sParameterSetSize)
                var spsData = Data()
                spsData.append(headerData)
                spsData.append(sps)
                encoder.queue.sync {
                    encoder.semaphore.wait()
                    encoder.writeToFile(data: spsData)
                    encoder.semaphore.signal()
                }
                guard let ppsPoint = pParamaterSet else {
                    print("pParamaterSet == nil")
                    return
                }
                let pps = Data(bytes: ppsPoint, count: pParameterSetSize)
                var ppsData = Data()
                ppsData.append(headerData)
                ppsData.append(pps)
                encoder.queue.sync {
                    encoder.semaphore.wait()
                    encoder.writeToFile(data: ppsData)
                    encoder.semaphore.signal()
                }
            }
            guard let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else{
                print("cannot get block buffer")
                return
            }
            var length: Int = 0, totalLength: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>? = nil
            guard CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == 0 else {
                print("cannot get BlockBufferGetDataPointeret ")
                return
            }
            var bufferOffset: Int8 = 0
            let avcHeaderLength = 4
            while bufferOffset < totalLength - avcHeaderLength {
                var nalUnitLength: UInt32 = 0
                memcmp(&nalUnitLength, (dataPointer! + UnsafeMutablePointer<Int8>.Stride(bufferOffset)), avcHeaderLength)
                nalUnitLength = CFSwapInt32BigToHost(nalUnitLength)
                let frameBytes = dataPointer! + UnsafeMutablePointer<Int8>.Stride(Int(bufferOffset) + avcHeaderLength)
                let frameData = Data(bytes: frameBytes, count: Int(nalUnitLength))
                var realData = Data()
                realData.append(headerData)
                realData.append(frameData)
                bufferOffset =  bufferOffset + Int8(avcHeaderLength) + Int8(nalUnitLength)
                encoder.queue.sync {
                    encoder.semaphore.wait()
                    encoder.writeToFile(data: realData)
                    encoder.semaphore.signal()
                }
            }
            
        }
        guard VTCompressionSessionCreate(allocator: nil, width: 720, height: 1280, codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: callback, refcon: Unmanaged.passUnretained(self).toOpaque(), compressionSessionOut: &compressSession) == 0 else{
            print("VTCompressionSessionCreate error")
            return
        }
        guard let session = compressSession else{
            print("session create fails")
            return
        }
        guard VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: Int(512*1024) as CFTypeRef) == 0 else {
            print("kVTCompressionPropertyKey_AverageBitRate error ")
            return
        }
        guard VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_4_1) == 0 else {
            print("kVTCompressionPropertyKey_ProfileLevel error")
            return
        }
        guard VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue) == 0 else {
            print("kVTCompressionPropertyKey_RealTime error")
            return
        }
        guard VTCompressionSessionPrepareToEncodeFrames(session) == 0 else{
            print("VTCompressionSessionPrepareToEncodeFrames error")
            return
        }
    }
    
    func stopCompress(){
        guard let session = compressSession,  VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid) == 0 else {
            print("cannot finish")
            return
        }
        VTCompressionSessionInvalidate(session)
//        CFRelease(session)
        compressSession = nil
    }
}

extension ViewController{
    func writeToFile(data: Data?){
        autoreleasepool{
            guard let encodedData = data else {
                print("no data")
                return
            }
            guard let path = getPath() else {
                return
            }
            if !isRecording{
                do {
                    try encodedData.write(to: URL(fileURLWithPath: path), options: .atomic)
                    isRecording = true
                }catch{
                    print(error)
                }
            }
            else{
                let handle = FileHandle(forWritingAtPath: path)
                do{
                    try handle?.seekToEnd()
                    handle?.write(encodedData)
                    try handle?.close()
                }catch{
                    print(error)
                }
                
            }
        }
    }
    private func getPath() -> String? {
        let manager = FileManager.default
        guard let path = manager.urls(for: .documentDirectory, in: .userDomainMask).first else{
            print("cannot find path")
            return nil
        }
        let filePath = path.absoluteString + "/" + "test.mp4"
        return filePath
    }
}
