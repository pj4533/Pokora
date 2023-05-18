//
//  VideoStore+Transformations.swift
//  Pokora
//
//  Created by PJ Gray on 5/18/23.
//

import Foundation
import CoreGraphics
import CoreImage

extension VideoStore {
    func rotateImage(image: CGImage, rotateDirection: CGFloat = 1.0) -> CGImage? {
        let width = image.width
        let height = image.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!

        context.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
//        if promptIndex == 0 {
//            rotateDirection = [1.0, -1.0].randomElement() ?? 1.0
//        }
        let rotateAngle: CGFloat = ((.pi / 180.0) * 0.333) * rotateDirection
        context.rotate(by: rotateAngle)
        context.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
        context.draw(image, in: CGRect(x: CGFloat((width - height)) / 2.0, y: CGFloat((height - width)) / 2.0, width: CGFloat(height), height: CGFloat(width)))

        return context.makeImage()
    }
    
    func zoomInImage(image: CGImage, scale: CGFloat = 1.008) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let filter1 = CIFilter(name: "CIPerspectiveTransform")!
        filter1.setValue(ciImage, forKey: kCIInputImageKey)
        let extent = ciImage.extent
        let width = extent.width * scale
        let height = extent.height * scale
        let x = extent.origin.x - (width - extent.width) / 2
        let y = extent.origin.y - (height - extent.height) / 2
        let topLeft = CIVector(x: extent.origin.x, y: y + height)
        let topRight = CIVector(x: x + width, y: y + height)
        let bottomRight = CIVector(x: x + width, y: y)
        let bottomLeft = CIVector(x: extent.origin.x, y: y)
        filter1.setValue(topLeft, forKey: "inputTopLeft")
        filter1.setValue(topRight, forKey: "inputTopRight")
        filter1.setValue(bottomRight, forKey: "inputBottomRight")
        filter1.setValue(bottomLeft, forKey: "inputBottomLeft")

        let filter2 = CIFilter(name: "CILanczosScaleTransform")!
        filter2.setValue(filter1.outputImage, forKey: kCIInputImageKey)
        filter2.setValue(scale, forKey: kCIInputScaleKey)
        filter2.setValue(1, forKey: kCIInputAspectRatioKey)

        let context = CIContext()
        return context.createCGImage(filter2.outputImage!, from: extent)
    }
}
