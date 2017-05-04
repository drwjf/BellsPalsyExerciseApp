//
//  Exercise.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 04/05/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit

class Exercise: NSObject
{
	var name:String
	var threshold:CGFloat

	init(name: String, threshold: CGFloat)
	{
		self.name = name
		self.threshold = threshold
	}
	
}
