//
//  ImageProcess.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class ImageProcess {
    
    public class func sizeImage(image: UIImage, aspectHeight: CGFloat, aspectWidth: CGFloat, center: CGPoint) -> UIImage? {
        let aspectRatio = aspectHeight / aspectWidth
        
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let imageAspectRatio = imageSize.height / imageSize.width
        
        let largestSize = (imageAspectRatio > aspectRatio) ?
            CGSize(width: imageSize.width, height: aspectRatio * imageSize.width) :
            CGSize(width: imageSize.height / aspectRatio, height: imageSize.height)
        
        var cropRect = CGRect(origin: .zero, size: largestSize)
        if largestSize.height == imageSize.height {
            cropRect.origin.x = center.x - (largestSize.width / 2)
            
            cropRect.origin.y = 0
            
            if cropRect.origin.x < 0 {
                cropRect.origin.x = 0
            }
            if cropRect.origin.x + cropRect.size.width > imageSize.width {
                cropRect.origin.x = imageSize.width - cropRect.size.width
            }
        } else {
            cropRect.origin.x = 0
            
            cropRect.origin.y = center.y - (largestSize.height / 2)
            
            if cropRect.origin.y < 0 {
                cropRect.origin.y = 0
            }
            if cropRect.origin.y + cropRect.size.height > imageSize.height {
                cropRect.origin.y = imageSize.height - cropRect.size.height
            }
        }
        
        if let croppedImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedImage)
        }
        return nil
    }
}
