//
//  ExerciseTableViewCell.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 08/05/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit

class ExerciseTableViewCell: UITableViewCell
{
	@IBOutlet weak var explanationLabel:UILabel!
	@IBOutlet weak var exerciseLabel:UILabel!
	@IBOutlet weak var demo:UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
