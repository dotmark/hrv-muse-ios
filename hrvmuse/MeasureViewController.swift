//
//  ViewController.swift
//  hrvmuse
//
//  Created by René van Mil on 31-03-17.
//

import UIKit

class MeasureViewController: UIViewController, HRMonitorDelegate, MuseDelegate, MeasuringViewControllerDelegate {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var statusLabelHR: UILabel!
    @IBOutlet weak var statusLabelMuse: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let hrMonitor = HRMonitor.sharedMonitor
    let muse = Muse.sharedMuse
    
    var hrReady = false {
        didSet {
            configureView()
        }
    }

    var museReady = false {
        didSet {
            configureView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hrMonitor.delegate = self
        hrMonitor.setup()
        muse.delegate = self
        muse.setup()
        configureStartButton()
    }
    
    func configureStartButton() {
        startButton.isHidden = true
        startButton.setTitleColor(UIColor.white, for: .normal)
        startButton.layer.cornerRadius = 50
        startButton.backgroundColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
        startButton.layer.opacity = 0.0
    }
    
    func configureView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                if self.hrReady {
                    UIView.transition(with: self.statusLabelHR, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        self.statusLabelHR.text = "✅ Heart rate sensor ready"
                    }, completion: nil)
                 } else {
                    UIView.transition(with: self.statusLabelHR, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        self.statusLabelHR.text = "Waiting for heart rate sensor..."
                    }, completion: nil)
                }
                if self.museReady {
                    UIView.transition(with: self.statusLabelMuse, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        self.statusLabelMuse.text = "✅ Muse headband ready"
                    }, completion: nil)
                } else {
                    UIView.transition(with: self.statusLabelMuse, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        self.statusLabelMuse.text = "Waiting for Muse headband..."
                    }, completion: nil)
                }
            })
            if self.hrReady && self.museReady {
                self.activityIndicator.stopAnimating()
                self.startButton.isHidden = false
                UIView.animate(withDuration: 1.0, animations: {
                    self.startButton.layer.opacity = 1.0
                })
            }
        }
    }
    
    @IBAction func start() {
        runHRMonitor()
        runMuse()
        performSegue(withIdentifier: "toMeasuring", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMeasuring" {
            (segue.destination as! MeasuringViewController).delegate = self
        }
    }
    
    func stop() {
        hrMonitor.stop()
        muse.stop()
    }
    
    
    // MARK: - HRMonitor

    func runHRMonitor() {
        hrMonitor.run()
    }
    

    // MARK: - Muse

    func runMuse() {
        muse.run()
    }

    
    // MARK: - HRMonitorDelegate
    
    func hrMonitorDidReceiveRRInterval(rr: UInt16) {
        print("Received RR", rr)
    }
    
    func hrMonitorIsReady() {
        hrReady = true
    }

    
    // MARK: - MuseDelegate
    
    func museDidReceiveValues(leftear: Double, leftforehead: Double, rightforehead: Double, rightear: Double) {
        print("Received Muse alpha values", leftear, leftforehead, rightforehead, rightear)
    }
    
    func museIsReady() {
        museReady = true
    }
    
    // MARK: - MeasuringViewControllerDelegate
    
    func measuringViewControllerDidFinish(sender: MeasuringViewController) {
        self.stop()
        DispatchQueue.main.async {
            sender.dismiss(animated: true, completion: nil)
        }
    }

}
