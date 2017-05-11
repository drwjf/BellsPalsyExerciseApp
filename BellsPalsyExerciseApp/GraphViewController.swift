//
//  GraphViewController.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 04/05/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit
import CorePlot
import CoreData

class GraphViewController: UIViewController
{
	@IBOutlet weak var hostView: CPTGraphHostingView!

	var dummyData = [DataPoint]()
	var plot: CPTBarPlot!
	let BarWidth = 0.25
	let BarInitialX = 0.25
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		fetch()
		for i in 0..<5
		{
			var date = NSDateComponents()
			date.day = i+13
			date.month = 4
			date.year = 2017
			dummyData.append(DataPoint(name: "Smiling", date: date, performance: Float(arc4random()) / Float(UINT32_MAX)))
		}
		
		navigationItem.title = "Smiling Exercise"
        // Do any additional setup after loading the view.
    }

	override var prefersStatusBarHidden: Bool
	{
		return true
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		initPlot()
	}
	
	func initPlot()
	{
		configureHostView()
		configureGraph()
		configureChart()
		configureAxes()
	}
	
	func configureHostView()
	{
		hostView.allowPinchScaling = false
	}
	
	
	func configureGraph()
	{
		// 1 - Create the graph
		let graph = CPTXYGraph(frame: hostView.bounds)
		graph.plotAreaFrame?.masksToBorder = false
		hostView.hostedGraph = graph
		
		// 2 - Configure the graph
		graph.apply(CPTTheme(named: CPTThemeName.plainWhiteTheme))
		graph.fill = CPTFill(color: CPTColor.clear())
		graph.paddingBottom = 30.0
		graph.paddingLeft = 30.0
		graph.paddingTop = 0.0
		graph.paddingRight = 0.0
		
		// 3 - Set up styles
		let titleStyle = CPTMutableTextStyle()
		titleStyle.color = CPTColor.black()
		titleStyle.fontName = "HelveticaNeue-Bold"
		titleStyle.fontSize = 16.0
		titleStyle.textAlignment = .center
		graph.titleTextStyle = titleStyle
		
		let title = "Smiling Exercise Performance"
		graph.title = title
		graph.titlePlotAreaFrameAnchor = .top
		graph.titleDisplacement = CGPoint(x: 0.0, y: -16.0)
		
		// 4 - Set up plot space
		let xMin = Double(dummyData[0].date.day)
		let xMax = Double(dummyData[dummyData.count-1].date.day)
		let yMin = 0.0
		let yMax = 1.2
		guard let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return }
		plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
		plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
	}
	
	func configureChart()
	{
		// 1 - Set up the three plots
		plot = CPTBarPlot()
		plot.fill = CPTFill(color: CPTColor(componentRed:0.92, green:0.28, blue:0.25, alpha:1.00))
		
		// 2 - Set up line style
		let barLineStyle = CPTMutableLineStyle()
		barLineStyle.lineColor = CPTColor.lightGray()
		barLineStyle.lineWidth = 0.5
		
		// 3 - Add plots to graph
		guard let graph = hostView.hostedGraph else { return }
		var barX = BarInitialX
		plot.dataSource = self
		plot.delegate = self
		plot.barWidth = NSNumber(value: BarWidth)
		plot.barOffset = NSNumber(value: barX)
		plot.lineStyle = barLineStyle
		graph.add(plot, to: graph.defaultPlotSpace)
		barX += BarWidth
		
	}
	
	func configureAxes()
	{
		// 1 - Configure styles
		let axisLineStyle = CPTMutableLineStyle()
		axisLineStyle.lineWidth = 2.0
		axisLineStyle.lineColor = CPTColor.black()
		// 2 - Get the graph's axis set
		guard let axisSet = hostView.hostedGraph?.axisSet as? CPTXYAxisSet else { return }
		// 3 - Configure the x-axis
		if let xAxis = axisSet.xAxis
		{
			xAxis.labelingPolicy = .none
			xAxis.majorIntervalLength = 1
			xAxis.axisLineStyle = axisLineStyle
			var majorTickLocations = Set<NSNumber>()
			var axisLabels = Set<CPTAxisLabel>()
			for data in dummyData.enumerated()
			{
				majorTickLocations.insert(NSNumber(value: data.element.date.day))
				let label = CPTAxisLabel(text: "\(data.element.date.day)", textStyle: CPTTextStyle())
				label.tickLocation = NSNumber(value: data.offset)
				label.offset = 5.0
				label.alignment = .left
				axisLabels.insert(label)
			}
			xAxis.majorTickLocations = majorTickLocations
			xAxis.axisLabels = axisLabels
		}
		// 4 - Configure the y-axis
		if let yAxis = axisSet.yAxis {
			yAxis.labelingPolicy = .automatic
			yAxis.labelOffset = -10.0
			yAxis.minorTicksPerInterval = 4
			yAxis.majorTickLength = 30
			let majorTickLineStyle = CPTMutableLineStyle()
			majorTickLineStyle.lineColor = CPTColor.black().withAlphaComponent(0.5)
			yAxis.majorTickLineStyle = majorTickLineStyle
			yAxis.minorTickLength = 20
			let minorTickLineStyle = CPTMutableLineStyle()
			minorTickLineStyle.lineColor = CPTColor.black().withAlphaComponent(0.25)
			yAxis.minorTickLineStyle = minorTickLineStyle
			yAxis.axisLineStyle = axisLineStyle
		}
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	func fetch()
	{
		let personFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DataPoint")
		do {
			let fetchedPerson = try moc.fetch(personFetch) as! [ExerciseDataPoint]
			let formatter  = DateFormatter()
			formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
			if fetchedPerson.count > 0
			{
				print(fetchedPerson.first!.name!)
				print(fetchedPerson.first!.performance)
				print(formatter.string(from: fetchedPerson.first?.date as! Date))
			}
		} catch {
			fatalError("Failed to fetch person: \(error)")
		}
	}

}

extension GraphViewController: CPTBarPlotDataSource, CPTBarPlotDelegate
{
	
	func numberOfRecords(for plot: CPTPlot) -> UInt
	{
		return UInt(dummyData.count)
	}
	
	func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any?
	{
		if fieldEnum == UInt(CPTBarPlotField.barTip.rawValue) {
			if plot == plot {
    return dummyData[Int(idx)].performance
			}
		}
		return dummyData[Int(idx)].date.day
	}
	
	func barPlot(_ plot: CPTBarPlot, barWasSelectedAtRecord idx: UInt, with event: UIEvent)
	{
		
	}
}
