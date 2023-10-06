//
//  Filters.swift
//  MetalFilters
//
//  Created by Saheem Hussain on 15/09/23.
//

import CoreImage

class ThreeDyeFilter: CIFilter {
    
    private lazy var kernel: CIKernel = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load metallib")
        }
        let name = "dyeInThree"
        guard let kernel = try? CIKernel(functionName: name, fromMetalLibraryData: data) else {
            fatalError("Unable to create the CIColorKernel for filter \(name)")
        }
        return kernel
    }()
    
    
    var inputImage: CIImage?
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return .none }
        
        let inputExtent = inputImage.extent
        
        let reddish   = CIVector(x: 1.1, y: 0.1, z: 0.1) // (3)
        let greenish  = CIVector(x: 0.1, y: 1.1, z: 0.1)
        let blueish   = CIVector(x: 0.1, y: 0.1, z: 1.1)
        
        let roiCallback: CIKernelROICallback = { _, rect -> CGRect in  // (4)
            return rect
        }

        return kernel.apply(
            extent: inputExtent,
            roiCallback: roiCallback,
            arguments: [inputImage, reddish, greenish, blueish]
        )
    }
    
    
}

class Super8Filter: CIFilter {
    
    private lazy var kernel: CIKernel = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load metallib")
        }
        let name = "super8Filter"
        guard let kernel = try? CIKernel(functionName: name, fromMetalLibraryData: data) else {
            fatalError("Unable to create the CIColorKernel for filter \(name)")
        }
        return kernel
    }()
    
    
    var inputImage: CIImage?
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return .none }
        
        let inputExtent = inputImage.extent
        
        let roiCallback: CIKernelROICallback = { _, rect -> CGRect in  // (4)
            return rect
        }

        return kernel.apply(
            extent: inputExtent,
            roiCallback: roiCallback,
            arguments: [inputImage]
        )
    }
    
    
}

class GlowFilter: CIFilter {
    
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputRadius: CGFloat = 10.0
    @objc dynamic var inputIntensity: CGFloat = 1.0

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }

        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(inputRadius, forKey: kCIInputRadiusKey)

        let blurredImage = blurFilter?.outputImage?.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: inputIntensity])

        let blendFilter = CIFilter(name: "CIScreenBlendMode")
        blendFilter?.setValue(blurredImage, forKey: kCIInputImageKey)
        blendFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)

        return blendFilter?.outputImage
    }
}

