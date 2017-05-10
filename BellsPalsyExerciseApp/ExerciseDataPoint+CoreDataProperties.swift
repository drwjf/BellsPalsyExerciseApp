//
//  ExerciseDataPoint+CoreDataProperties.swift
//  
//
//  Created by Kutlay Hanli on 10/05/2017.
//
//

import Foundation
import CoreData


extension ExerciseDataPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseDataPoint> {
        return NSFetchRequest<ExerciseDataPoint>(entityName: "DataPoint")
    }

    @NSManaged public var name: String?
    @NSManaged public var performance: Float
    @NSManaged public var date: NSDate?

}
