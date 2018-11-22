//
//  ViewController.swift
//  VideoCapture
//
//  Created by 洋蔥胖 on 2018/11/22.
//  Copyright © 2018 ChrisYoung. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    //    fileprivate var connection : AVCaptureConnection?
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var movieOutput : AVCaptureMovieFileOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
}

// MARK:- 視頻的開始採集&停止採集
extension ViewController {
    
    @IBAction func startCapture(_ sender: Any) {
        // 1.設置視頻的輸入&輸出
        setupVideo()
        
        // 2.設置音頻的輸入&輸出
        setupAudeio()
        
        // 3.添加寫入文件的Output
        let movieOutput = AVCaptureMovieFileOutput()
        session.addOutput(movieOutput)
        self.movieOutput = movieOutput
        
        //設置寫入的穩定性
        let connection = movieOutput.connection(with: .video)
        connection?.preferredVideoStabilizationMode = .auto
        
        // 4.給用戶看到一個預覽圖層(可選)
        previewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // 5.開始採集
        session.startRunning()
        
        // 6.開始將採集到的畫面，寫入到文件中
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        
        let url = URL(fileURLWithPath: path)
        
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    
    @IBAction func stopCapture(_ sender: Any) {
        movieOutput?.stopRecording()
        
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
    
    //切換攝像頭
    @IBAction func switchScene(_ sender: Any) {
        // 1.獲取之前的鏡頭
        guard var position = videoInput?.device.position else { return }
        
        // 2.獲取當前應該顯示的鏡頭
        position = position == .front ? .back : .front
        
        // 3.根據當前鏡頭創建新的deivce
        let devices = AVCaptureDevice.devices(for: .video)
        guard let device =  devices.filter({ $0.position == position}).first else { return }
        
        // 4.根據新的deivce創建新的Input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 5.在session中切換Input
        session.beginConfiguration()  //開啟配置
        session.removeInput(self.videoInput!) //先刪掉之前videoInput
        session.addInput(videoInput)
        session.commitConfiguration() //提交配置
        self.videoInput = videoInput
        //下面log不會打印出採集視頻畫面 是因為已經切換攝像頭了 所以connection也要切換
        
    }
}

extension ViewController {
    fileprivate func setupVideo() {
        
        // 1.給 補捉會話 設置 輸入源(攝像頭)
        // 1.1.獲取攝像頭設備
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
            print("攝像頭不可用")
            return
        }
        guard let device = devices.filter({ $0.position == .front }).first else { return } //拿到前置攝像頭
        
        // 1.2.通過device創建AVCaptureDeviceInput
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = videoInput
        
        // 1.3.將input添加到會話中
        session.addInput(videoInput)
        
        // 2.給 補捉會話 設置 輸出源
        let videoOutput = AVCaptureVideoDataOutput()
        //輸出數據
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        session.addOutput(videoOutput)
        
        // 3.獲取videod對應的Connection
        //        connection = videoOutput.connection(with: .video)
        self.videoOutput = videoOutput
    }
    
    fileprivate func setupAudeio() {
        // 1.設置音頻的輸入(話筒)
        // 1.1.獲取話筒設備
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else { return }
        
        // 1.2.通過device創建AVCaptureDeviceInput
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 1.3.將input添加到會話中
        session.addInput(audioInput)
        
        // 2.給 補捉會話 設置 輸出源
        let audioOutput = AVCaptureAudioDataOutput()
        //輸出數據
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        session.addOutput(audioOutput)
        
    }
    
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureAudioDataOutputSampleBufferDelegate{
    
    //sampleBuffer 取到每一禎畫面 想要對畫面 進行美顏效果 和 進行編碼
    // from connection 來區分video或audio
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //
        //        if connection == self.connection
        if connection == videoOutput?.connection(with: .video)
        {
            print("已經採集視頻畫面")
        }else {
            print("已經採集音頻畫面")
        }
    }
}

/*
 把我們錄製的視頻和音頻寫入到文件
 其實我們真實開發時不是寫入到文件的，而是將這些數據進行編碼再傳輸到服務器，如何編碼這部份，放到後面講解，現在先把我們錄製音頻寫入到文件，看看我們真實進行一個錄製，怎麼開始，就是一但開始採集時，就要開始寫入文件
 */
extension ViewController : AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("開始寫入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("結束寫入文件")
    }
    
}
