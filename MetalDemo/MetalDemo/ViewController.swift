//
//  ViewController.swift
//  MetalDemo
//
//  Created by Saheem Hussain on 26/09/23.
//

import UIKit

class ViewController: UIViewController {
    
    var metal = MetalView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let metalCircleView = MetalView()
        view.addSubview(metalCircleView)
        
        //constraining to window
        metalCircleView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        metalCircleView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        metalCircleView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        metalCircleView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    
}

