//
//  MeasuringViewController.swift
//  hrvmuse
//
//  Created by René van Mil on 01-04-17.
//

import UIKit

protocol MeasuringViewControllerDelegate {
    func measuringViewControllerDidFinish(sender: MeasuringViewController)
}

class MeasuringViewController: UIViewController {
    
    var delegate: MeasuringViewControllerDelegate?
    
    @IBOutlet weak var leSlider: UISlider!
    @IBOutlet weak var lfSlider: UISlider!
    @IBOutlet weak var rfSlider: UISlider!
    @IBOutlet weak var reSlider: UISlider!
    @IBOutlet weak var heartLabel: UILabel!
    @IBOutlet weak var hrLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(museValuesDidUpdate(_:)), name: NSNotification.Name(rawValue: AppNotifications.museValuesDidUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rrIntervalDidUpdate(_:)), name: NSNotification.Name(rawValue: AppNotifications.rrIntervalDidUpdate), object: nil)
        hrLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateHeart()
    }
    
    func animateHeart() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.heartLabel.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            }) { (finished) in
                if finished {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 1.0, animations: {
                            self.heartLabel.transform = CGAffineTransform.identity
                        }, completion: { (finished) in
                            if finished {
                                self.animateHeart()
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func stop() {
        delegate?.measuringViewControllerDidFinish(sender: self)
    }
    
    func rrIntervalDidUpdate(_ notification: Notification) {
        if let rrValue = notification.userInfo {
            let rr = rrValue["rr"] as! UInt16
            let ms = Double(rr) / 1000.0
            let hr = Int(60.0 / ms)
            hrLabel.text = String(hr)
        }
    }
    
    func museValuesDidUpdate(_ notification: Notification) {
        if let museValues = notification.userInfo {
            let leftear = museValues["leftear"]
            let leftforehead = museValues["leftforehead"]
            let rightforehead = museValues["rightforehead"]
            let rightear = museValues["rightear"]
            DispatchQueue.main.async {
                UIView.animate(withDuration: 1.0, animations: { 
                    self.leSlider.setValue(Float(leftear as! Double), animated: true)
                    self.lfSlider.setValue(Float(leftforehead as! Double), animated: true)
                    self.rfSlider.setValue(Float(rightforehead as! Double), animated: true)
                    self.reSlider.setValue(Float(rightear as! Double), animated: true)
                })
            }
        }

    }

}
