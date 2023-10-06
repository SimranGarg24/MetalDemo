//
//  ViewController.swift
//  MetalFilters
//
//  Created by Saheem Hussain on 15/09/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var originalImge: UIImageView!
    
    @IBOutlet weak var filteredImage: UIImageView!
    
    @IBOutlet weak var notchView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let image = UIImage(named: "Image")
        originalImge.image = image
        
        let inputImage = CIImage(image: image!)
        
        let filter = Super8Filter()
        filter.inputImage = inputImage // a CIImage
        filteredImage.image = UIImage(ciImage: filter.outputImage!)
        
        let glowFilter = GlowFilter()
        glowFilter.inputImage = inputImage
        glowFilter.inputRadius = 10.0 // Adjust glow radius as needed
        glowFilter.inputIntensity = 1.5 // Adjust glow intensity as neede
//        filteredImage.image = UIImage(ciImage: glowFilter.outputImage!)
        if let outputImage = glowFilter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                originalImge.image = UIImage(cgImage: cgImage)
                // Use filteredImage as needed
            }
        }
        
    }

    

}

