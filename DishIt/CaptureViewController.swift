//
//  ViewController.swift
//  DishIt
//
//  Created by Michael Chen on 11/18/15.
//  Copyright © 2015 NinthAndMarket. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var frameForCapture: UIView!
    
    let IMAGE_PREVIEW_FRAME = CGRectMake(0, 50, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.width)
    
    override func viewDidLayoutSubviews() {
        // TODO: this needs to be cleaner
        CameraManager.sharedInstance.setFrame(frameForCapture.frame)
        CameraManager.sharedInstance.setRootLayer(self.view.layer)
        CameraManager.sharedInstance.beginSession()
        let button = UIButton(type: UIButtonType.Custom)
        button.addTarget(self, action: "roundButtonDidTap:", forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(UIScreen.mainScreen().bounds.width / 2 - 50, UIScreen.mainScreen().bounds.height - 200, 100, 100)
        button.clipsToBounds = true
        button.layer.cornerRadius = 50
        button.layer.borderColor = UIColor.redColor().CGColor
        button.layer.borderWidth = 2.0
        button.layer.backgroundColor = UIColor.whiteColor().CGColor
        button.layer.opacity = 0.1
        self.view.addSubview(button)
    }
    
    func roundButtonDidTap(tappedButton: UIButton) {
        print("got here")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

