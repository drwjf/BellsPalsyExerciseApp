//
//  ViewController.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 23/02/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit
import AVFoundation

var currentExercise = 0

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate
{
	@IBOutlet weak var rightEdge: UITextField!
	@IBOutlet weak var leftEdge: UITextField!
	@IBOutlet weak var transparentView: UIView!
	
	var exercises = [Exercise(name:"SMILING",threshold: 50.0),Exercise(name:"BLINKING",threshold: 5.0)]
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
	var dataPoints = [Double]()
	let frameCount = 15
	
	var currentMetadata: [AnyObject] = []
	
    @IBOutlet weak var preview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		rightEdge.layer.zPosition = 2
		leftEdge.layer.zPosition = 2
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
			var difference:Double = 0.0
			
			if (currentExercise < 0)
			{
				let leftEyebrowInnerEdge = points[21] as! [NSNumber]
				let rightEyebrowInnerEdge = points[22] as! [NSNumber]
				let topNose = points[27] as! [NSNumber]
				let leftOffset = abs(leftEyebrowInnerEdge[0].intValue - topNose[0].intValue)
				let rightOffset = abs(rightEyebrowInnerEdge[0].intValue - topNose[0].intValue)
				difference = abs(Double(leftOffset - rightOffset))
			}
			else if (currentExercise == 0)
			{
				let leftCorner = points[48] as! [NSNumber]
				let rightCorner = points[54] as! [NSNumber]
				let center = points[62] as! [NSNumber]
				let leftOffset = abs(center[0].intValue - leftCorner[0].intValue)
				let rightOffset = abs(center[0].intValue - rightCorner[0].intValue)
				difference = abs(Double(leftOffset - rightOffset))
				
			}
			else if (currentExercise == 1)
			{
				// left eye
				let leftEyeLeftUpperCorner = points[37] as! [NSNumber]
				let leftEyeRightUpperCorner = points[38] as! [NSNumber]
				let leftEyeLeftLowerCorner = points[41] as! [NSNumber]
				let leftEyeRightLowerCorner = points[40] as! [NSNumber]
				// right eye
				let rightEyeLeftUpperCorner = points[43] as! [NSNumber]
				let rightEyeRightUpperCorner = points[44] as! [NSNumber]
				let rightEyeLeftLowerCorner = points[47] as! [NSNumber]
				let rightEyeRightLowerCorner = points[46] as! [NSNumber]
				
				let leftEyeClosure = (abs(leftEyeLeftUpperCorner[1].doubleValue - leftEyeLeftLowerCorner[1].doubleValue) + abs(leftEyeRightUpperCorner[1].doubleValue - leftEyeRightLowerCorner[1].doubleValue)) / 2.0
				
				let rightEyeClosure = (abs(rightEyeLeftUpperCorner[1].doubleValue - rightEyeLeftLowerCorner[1].doubleValue) + abs(rightEyeRightUpperCorner[1].doubleValue - rightEyeRightLowerCorner[1].doubleValue)) / 2.0
				
				difference = abs(Double(leftEyeClosure - rightEyeClosure))
			}
			DispatchQueue.main.async
				{
					// Smiling
					if (self.count < Double(self.frameCount))
					{
						self.dataPoints.append(difference)
						self.sum += difference
						self.count += 1
					}
					else
					{
						// filtering -----------
						
						
						for data in self.dataPoints
						{
							self.average += data
						}
						self.average /= Double(self.dataPoints.count)
						for data in self.dataPoints
						{
							self.standardDeviation += (data - self.average) * (data - self.average)
						}
						self.standardDeviation = sqrt(self.standardDeviation / Double(self.dataPoints.count))
						
						for index in 0...(self.frameCount-1)
						{
							if (abs(self.dataPoints[index]) > self.standardDeviation + abs(self.average))
							{
								self.sum -= self.dataPoints[index]
								self.count -= 1
							}
						}
						
						let filteredData = self.sum / self.count
						
						// ---------------------
						
						self.dataPoints.removeAll()
						self.standardDeviation = 0
						self.sum = 0
						self.average = 0
						self.count = 0
						if (CGFloat(filteredData) > self.exercises[currentExercise].threshold * 0.2)
						{
							self.transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: CGFloat(filteredData)/CGFloat(self.exercises[currentExercise].threshold))
						}
						else
						{
							self.transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0)
						}
						
						self.leftEdge.text = String(filteredData)
						self.rightEdge.text = String(filteredData)
						
					}
					// Smiling End
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

