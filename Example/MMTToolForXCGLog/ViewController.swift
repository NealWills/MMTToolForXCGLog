//
//  ViewController.swift
//  MMTToolForXCGLog
//
//  Created by Donghn on 11/03/2025.
//  Copyright (c) 2025 Donghn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy_MM_dd hh:mm:ss.SSS"
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { _ in
            let date = Date()
            let time = dateFormatter.string(from: date)
            log.info("log info: \(time)")
        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

