//
//  DataPoint.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 04/05/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit

class DataPoint: NSObject
{
	var name:String
	var date:NSDateComponents
	var performance:Float
	
	init(name: String, date: NSDateComponents, performance: Float)
	{
		self.name = name
		self.date = date
		self.performance = performance
	}
}
