//
//  ViewController.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 23/02/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate
{
	@IBOutlet weak var rightEdge: UITextField!
	@IBOutlet weak var leftEdge: UITextField!
	
	@IBOutlet weak var transparentView: UIView!
	var session = AVCaptureSession()
	var output = AVCaptureVideoDataOutput()
	let layer = AVSampleBufferDisplayLayer()
	let sampleQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.sampleQueue", attributes: [])
	let faceQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.faceQueue", attributes: [])
	let wrapper = DlibWrapper()
	
	var count:Double = 0;
	var standardDeviation:Double = 0.0
	var sum:Double = 0.0
	var average:Double = 0.0
	var mouthData = [Double]()
	let frameCount = 15
	
	var currentMetadata: [AnyObject] = []
	
    @IBOutlet weak var preview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		rightEdge.layer.zPosition = 2
		leftEdge.layer.zPosition = -5
		transparentView.layer.zPosition = 1
		rightEdge.backgroundColor = UIColor.clear
		leftEdge.backgroundColor = UIColor.clear
		transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.0)
//		transparentView.backgroundColor = UIColor.clear
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
        openSession()
		self.preview.layer.addSublayer(layer)
	}
	
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		updateVideoOrientation()
	}
	
	func updateVideoOrientation () {
		if let connection = output.connection(withMediaType: AVMediaTypeVideo)  {
			if (connection.isVideoOrientationSupported) {
				switch (UIDevice.current.orientation) {
					case .portrait:
						connection.videoOrientation = AVCaptureVideoOrientation.portrait
						break
					case .landscapeRight:
						connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
						break
					case .landscapeLeft:
						connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
						break
					case .portraitUpsideDown:
						connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
						break
					default:
						connection.videoOrientation = AVCaptureVideoOrientation.portrait
						break
					}
				}
			}
		layer.frame = self.preview.bounds
	}

	override var prefersStatusBarHidden: Bool
	{
		return true
	}
	
	func openSession()
	{
		let device = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
			.map { $0 as! AVCaptureDevice }
			.filter { $0.position == .front}
			.first!
		
		let input = try! AVCaptureDeviceInput(device: device)
		
		output.setSampleBufferDelegate(self, queue: sampleQueue)
		
		let metaOutput = AVCaptureMetadataOutput()
		metaOutput.setMetadataObjectsDelegate(self, queue: faceQueue)
		
		session.beginConfiguration()
		
		if session.canAddInput(input) {
			session.addInput(input)
		}
		if session.canAddOutput(output) {
			session.addOutput(output)
		}
		if session.canAddOutput(metaOutput) {
			session.addOutput(metaOutput)
		}
		
		session.commitConfiguration()
		
		let settings: [AnyHashable: Any] = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
		output.videoSettings = settings
		
		// availableMetadataObjectTypes change when output is added to session.
		// before it is added, availableMetadataObjectTypes is empty
		metaOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
		
		wrapper?.prepare()
		
		session.startRunning()
	}
	
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
	{
		connection.videoOrientation = AVCaptureVideoOrientation.portrait
		connection.isVideoMirrored = true
		
		if !currentMetadata.isEmpty
		{
			let boundsArray = currentMetadata
				.flatMap { $0 as? AVMetadataFaceObject }
				.map { (faceObject) -> NSValue in
					let convertedObject = captureOutput.transformedMetadataObject(for: faceObject, connection: connection)
					return NSValue(cgRect: convertedObject!.bounds)
			}
			
			let points = wrapper?.doWork(on: sampleBuffer, inRects: boundsArray) as! [NSArray]
			let leftCorner = points[48] as! [NSNumber]
			let rightCorner = points[54] as! [NSNumber]
			let center = points[62] as! [NSNumber]
			let leftOffset = abs(center[0].intValue - leftCorner[0].intValue)
			let rightOffset = abs(center[0].intValue - rightCorner[0].intValue)
			let difference:Double = abs(Double(leftOffset - rightOffset))
			DispatchQueue.main.async
			{
				if (self.count < Double(self.frameCount))
				{
					self.mouthData.append(difference)
					self.sum += difference
					self.count += 1
				}
				else
				{
					// filtering -----------
					
					for data in self.mouthData
					{
						self.average += data
					}
					self.average /= Double(self.mouthData.count)
					for data in self.mouthData
					{
						self.standardDeviation += (data - self.average) * (data - self.average)
					}
					self.standardDeviation = sqrt(self.standardDeviation / Double(self.mouthData.count))
					
					for index in 0...(self.frameCount-1)
					{
						if (abs(self.mouthData[index]) > self.standardDeviation + abs(self.average))
						{
							self.sum -= self.mouthData[index]
							self.count -= 1
						}
					}
					
					let filteredData = self.sum / self.count
					
					// ---------------------
					
					self.mouthData.removeAll()
					self.standardDeviation = 0
					self.sum = 0
					self.average = 0
					self.count = 0
					self.transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: CGFloat(filteredData)/CGFloat(50))
					self.leftEdge.text = String(filteredData)
					self.rightEdge.text = String(filteredData)
				}
			}
		}
		
		layer.enqueue(sampleBuffer)
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
	{
		print("DidDropSampleBuffer")
	}
	
	// MARK: AVCaptureMetadataOutputObjectsDelegate
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
	{
		currentMetadata = metadataObjects as [AnyObject]
	}

}

