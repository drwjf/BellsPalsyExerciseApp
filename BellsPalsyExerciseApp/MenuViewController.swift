//
//  MenuViewController.swift
//  BellsPalsyExerciseApp
//
//  Created by Kutlay Hanli on 04/05/2017.
//  Copyright © 2017 ku.khanli. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController
{
	
	let exercises = ["Smiling","Blinking"]

	@IBOutlet weak var navigationBar: UINavigationItem!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		navigationItem.title = "Menu"

		

/*
		// Sets the translucent background color
		UINavigationBar.appearance().backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		// Set translucent. (Default value is already true, so this can be removed if desired.)
		UINavigationBar.appearance().isTranslucent = false
*/
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

	override func viewWillAppear(_ animated: Bool)
	{
		if let navController = self.navigationController
		{
			navController.navigationBar.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
			navController.navigationItem.title = "Menu"
			navController.navigationBar.tintColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
		}
	}
	
	override var prefersStatusBarHidden: Bool
	{
		return true
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        // #warning Incomplete implementation, return the number of rows
        return exercises.count
    }

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if (section == 0)
		{
			return "Exercises"
		}
		else
		{
			return "Progress"
		}
	}
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell", for: indexPath) as! MenuViewCell

        // Configure the cell...

		cell.label.text = exercises[indexPath.row]
		
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		currentExercise = indexPath.row
		if (indexPath.section == 0)
		{
			performSegue(withIdentifier: "exerciseSegue", sender: self)
		}
		else
		{
			performSegue(withIdentifier: "progressSegue", sender: self)
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
