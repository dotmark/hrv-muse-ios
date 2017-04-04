//
//  InterfaceController.swift
//  hrvmuse WatchKit Extension
//
//  Created by René van Mil on 31-03-17.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var startButton: WKInterfaceButton!
    
    let workout = Workout()
    
    var started = false {
        didSet {
            updateStartButton()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func handleStartButtonTap(sender: WKInterfaceButton) {
        started = !started
        if started {
            workout.start()
        } else {
            workout.stop()
        }
    }
    
    func updateStartButton() {
        if started {
            startButton.setTitle("Stop")
        } else {
            startButton.setTitle("Start")
        }
    }

}
