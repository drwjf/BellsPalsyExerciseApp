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

class ExerciseViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate
{
	@IBOutlet weak var rightEdge: UILabel!
	@IBOutlet weak var leftEdge: UILabel!
	@IBOutlet weak var transparentView: UIView!
	@IBOutlet weak var guide: UIImageView!
	@IBOutlet weak var timerLabel: UILabel!
	@IBOutlet weak var buttonOutlet: UIButton!
	
	var exercises = [Exercise(name:"SMILING",threshold: 50.0),Exercise(name:"BLINKING",threshold: 5.0)]
	var session = AVCaptureSession()
	var output = AVCaptureVideoDataOutput()
	let layer = AVSampleBufferDisplayLayer()
	let sampleQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.sampleQueue", attributes: [])
	let faceQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.faceQueue", attributes: [])
	let wrapper = DlibWrapper()
	
	var timer: Timer?
	var countdown = 0
	var exercising = false
	
	var count:Double = 0;
	var standardDeviation:Double = 0.0
	var sum:Double = 0.0
	var average:Double = 0.0
	var dataPoints = [Double]()
	let frameCount = 15
	
	let leftEyeReference = CGPoint(x: 225, y: 560)
	let rightEyeReference = CGPoint(x: 535, y: 560)
	
	struct Stabilization
	{
		var leftEyeDataPoints = [CGPoint]()
		var rightEyeDataPoints = [CGPoint]()
		let threshold:CGFloat = 50
		
		func average(array: [CGPoint]) -> CGPoint
		{
			var result = CGPoint(x: 0, y: 0)
			
			for data in array
			{
				result = CGPoint(x: result.x + data.x, y: result.y + data.y)
			}
			
			return CGPoint(x: result.x / CGFloat(array.count), y: result.y / CGFloat(array.count))
		}
		
		func standardDeviaton(array: [CGPoint]) -> CGPoint
		{
			var temp = CGPoint(x: 0, y: 0)
			let ave = self.average(array: array)
			for data in array
			{
				temp = CGPoint(x: temp.x + pow(data.x - ave.x, 2), y: temp.y + pow(data.y - ave.y, 2))
			}
			return CGPoint(x: sqrt(temp.x / CGFloat(array.count)), y: sqrt(temp.y / CGFloat(array.count)))
		}
		
		func AVTFiltering(array: [CGPoint]) -> CGPoint
		{
			let ave = self.average(array: array)
			let sd = self.standardDeviaton(array: array)
			var validDataCount = 0
			var result = CGPoint(x: 0, y: 0)
			for data in array
			{
				if (data.x > ave.x - sd.x && data.x < ave.x + sd.x && data.y > ave.y - sd.y && data.y < ave.y + sd.y)
				{
					result = CGPoint(x: result.x + data.x, y: result.y + data.y)
					validDataCount += 1
				}
			}
			return CGPoint(x: result.x / CGFloat(validDataCount), y: result.y / CGFloat(validDataCount))
		}
		
		mutating func filter() -> [CGPoint] {
			let result = [self.AVTFiltering(array: self.leftEyeDataPoints),self.AVTFiltering(array: self.rightEyeDataPoints)]
			self.leftEyeDataPoints.removeAll()
			self.rightEyeDataPoints.removeAll()
			return result
		}
		
		mutating func add(left: CGPoint, right: CGPoint)
		{
			self.leftEyeDataPoints.append(left)
			self.rightEyeDataPoints.append(right)
		}
	}
	
	var stabilizer = Stabilization()
	
	var currentMetadata: [AnyObject] = []
	
    @IBOutlet weak var preview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.title = exercises[currentExercise].name
		
		rightEdge.layer.zPosition = 2
		leftEdge.layer.zPosition = 2
		transparentView.layer.zPosition = 1
		guide.layer.zPosition = 2
		timerLabel.layer.zPosition = 2
		buttonOutlet.layer.zPosition = 2
		timerLabel.alpha = 0
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
			
			// face location validation --------
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
			
			stabilizer.add(left: CGPoint(x: (leftEyeLeftUpperCorner[0].cgFloatValue() + leftEyeRightUpperCorner[0].cgFloatValue() + leftEyeLeftLowerCorner[0].cgFloatValue() + leftEyeRightLowerCorner[0].cgFloatValue())/4.0, y: (leftEyeLeftUpperCorner[1].cgFloatValue() + leftEyeRightUpperCorner[1].cgFloatValue() + leftEyeLeftLowerCorner[1].cgFloatValue() + leftEyeRightLowerCorner[1].cgFloatValue())/4.0), right: (CGPoint(x: (rightEyeLeftUpperCorner[0].cgFloatValue() + rightEyeRightUpperCorner[0].cgFloatValue() + rightEyeLeftLowerCorner[0].cgFloatValue() + rightEyeRightLowerCorner[0].cgFloatValue())/4.0, y: (rightEyeLeftUpperCorner[1].cgFloatValue() + rightEyeRightUpperCorner[1].cgFloatValue() + rightEyeLeftLowerCorner[1].cgFloatValue() + rightEyeRightLowerCorner[1].cgFloatValue())/4.0)))
			// ---------------------------------
			
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
				let leftEyeClosure = (abs(leftEyeLeftUpperCorner[1].doubleValue - leftEyeLeftLowerCorner[1].doubleValue) + abs(leftEyeRightUpperCorner[1].doubleValue - leftEyeRightLowerCorner[1].doubleValue)) / 2.0
				
				let rightEyeClosure = (abs(rightEyeLeftUpperCorner[1].doubleValue - rightEyeLeftLowerCorner[1].doubleValue) + abs(rightEyeRightUpperCorner[1].doubleValue - rightEyeRightLowerCorner[1].doubleValue)) / 2.0
				
				difference = abs(Double(leftEyeClosure - rightEyeClosure))
			}
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
				
				let reference = stabilizer.filter()
				
				DispatchQueue.main.async
				{
					if (CGFloat(filteredData) > self.exercises[currentExercise].threshold * 0.2)
					{
						self.transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: CGFloat(filteredData)/CGFloat(self.exercises[currentExercise].threshold))
					}
					else
					{
						self.transparentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0)
					}
					
					if (abs(self.leftEyeReference.x - reference[0].x) < self.stabilizer.threshold && abs(self.leftEyeReference.y - reference[0].y) < self.stabilizer.threshold && abs(self.rightEyeReference.x - reference[1].x) < self.stabilizer.threshold && abs(self.rightEyeReference.y - reference[1].y) < self.stabilizer.threshold)
					{
//						print("success")
						self.guide.alpha = 0
						if (self.timer == nil && self.exercising)
						{
							self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
/*
							self.timerLabel.text = "\(self.countdown)"
							self.timerLabel.alpha = 1
*/
						}
					}
					else
					{
						self.guide.alpha = 1
						if (self.exercising)
						{
							self.buttonAction(self)
						}
					}
					
					self.leftEdge.text = "x: \(reference[0].x)\ny\(reference[0].y)"
					self.rightEdge.text = "x: \(reference[1].x)\ny\(reference[1].y)"
					
				}
				// Smiling End
			}
		}
		else
		{
//			print("not valid")
			DispatchQueue.main.async
			{
				if (self.timer != nil)
				{
					self.timer?.invalidate()
					self.timer = nil
					self.countdown = 3
					self.timerLabel.alpha = 0
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

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
	{
		if let touch = touches.first
		{
			print("x:\(2 * touch.location(in: self.view).x) y:\(2 * touch.location(in: self.view).y)")
		}
//		let screenBounds = UIScreen.main.bounds
//		print("x:\(screenBounds.width) y:\(screenBounds.height)")
		// screen resolution : 1334 * 750
	}
	
	func timerAction()
	{
		timerLabel.text = "\(countdown)"
		if (countdown == 0)
		{
			timer?.invalidate()
			timer = nil
			countdown = 3
			timerLabel.alpha = 0
		}
		else
		{
			timerLabel.alpha = 1
			countdown -= 1
		}
	}
	
	@IBAction func buttonAction(_ sender: Any)
	{
		if (exercising)
		{
			buttonOutlet.setTitle("Start", for: UIControlState.normal)
			buttonOutlet.setTitleColor(UIColor.green, for: UIControlState.normal)
		}
		else
		{
			buttonOutlet.setTitle("End", for: UIControlState.normal)
			buttonOutlet.setTitleColor(UIColor.red, for: UIControlState.normal)
		}
		exercising = !exercising
	}
	
}

