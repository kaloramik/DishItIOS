//
//  CameraManager.swift
//  DishIt
//
//  Created by Michael Chen on 11/24/15.
//  Copyright © 2015 NinthAndMarket. All rights reserved.
//

import Foundation
import AVFoundation

class CameraManager {
    
    let SAVED_IMAGE_WIDTH : CGFloat = 1080.0
    let SAVED_IMAGE_HEIGHT : CGFloat = 1080.0
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var imageOutput = AVCaptureStillImageOutput()
    
    var rootLayer : CALayer?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var frame : CGRect?
    
    class var sharedInstance: CameraManager {
        struct Static {
            static var instance: CameraManager?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = CameraManager()
        }
        
        return Static.instance!
    }
    
    // initialize camera
    init() {
        let devices = AVCaptureDevice.devices()
        print(devices)
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        if (captureSession.canAddOutput(imageOutput)) {
            captureSession.addOutput(imageOutput);
        }
        else {
            print("Could not add image output")
        }
    }
    
    func beginSession() {
        if (captureSession.running) {
            return
        }
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("unable to start camera")
            // quit out?
        }
        
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

        self.rootLayer!.masksToBounds = true
        self.previewLayer?.frame = self.frame!
        self.rootLayer!.addSublayer(previewLayer!)
        captureSession.startRunning()
    }
    
    func setRootLayer(layer : CALayer) {
        self.rootLayer = layer
    }
    func setFrame(frame : CGRect) {
        self.frame = frame
    }
    
    func findVideoConnection() -> AVCaptureConnection? {
        var videoConnection:AVCaptureConnection?
        for connection in imageOutput.connections as! [AVCaptureConnection] {
            for port in connection.inputPorts as! [AVCaptureInputPort] {
                if (port.mediaType == AVMediaTypeVideo) {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection != nil) { break; }
        }
        return videoConnection
    }
    
    // TODO: how should this work in the future? delegate? 
    func captureImage(completionHandler handler: (UIImage? -> Void)!) {
        self.imageOutput.captureStillImageAsynchronouslyFromConnection(findVideoConnection(), completionHandler: {
            (imageSampleBuffer, error) -> Void in
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
            var image = UIImage(data: imageData)
            if let previewLayer = self.previewLayer {
                // get rectangle of the image in the coordinate system of the camera
                // this is given in ratios between 0-1
                let outputRect = previewLayer.metadataOutputRectOfInterestForRect(previewLayer.bounds)
                print(outputRect)
                let takenCGImage = image!.CGImage
                let w = CGFloat(CGImageGetWidth(takenCGImage))
                let h = CGFloat(CGImageGetHeight(takenCGImage))
                // force this to be 1080 due to some rounding issues
                let cropRect = CGRectMake(floor(outputRect.origin.x * w),
                    floor(outputRect.origin.y * h),
                    self.SAVED_IMAGE_WIDTH,
                    self.SAVED_IMAGE_HEIGHT)
                print(cropRect)
                let cropCGImage = CGImageCreateWithImageInRect(takenCGImage, cropRect)
                // at this point we have a 1080 x 1080 image
                // can save to photo roll at this point with 
                // UIImageWriteToSavedPhotosAlbum(takenImage, nil, nil, nil)
                let takenImage = UIImage(CGImage: cropCGImage!, scale: 1.0, orientation: image!.imageOrientation)
                // remove orientation and orient correctly
                let transformedImage = CameraManager.sharedInstance.transformImage(takenImage)
                handler(transformedImage)
            }
        })
    }
    
    func transformImage(image : UIImage) -> UIImage {
        
        
        let imgRef = image.CGImage
        
        let width = CGFloat(CGImageGetWidth(imgRef))
        let height = CGFloat(CGImageGetHeight(imgRef))
        let kMaxResolution = CGFloat(max(width, height));
        
        var bounds = CGRectMake(0, 0, width, height)
        
        var transform = CGAffineTransformIdentity
        
        if  (width > kMaxResolution || height > kMaxResolution) {
            let ratio = width/height;
            if (ratio > 1) {
                bounds.size.width = kMaxResolution;
                bounds.size.height = round(bounds.size.width / ratio);
            } else {
                bounds.size.height = kMaxResolution;
                bounds.size.width = round(bounds.size.height * ratio);
            }
        }
        
        let scaleRatio = bounds.size.width / width
        let imageSize = CGSizeMake(CGFloat(CGImageGetWidth(imgRef)), CGFloat(CGImageGetHeight(imgRef)));
        
        var boundHeight : CGFloat
        
        let orient : UIImageOrientation = image.imageOrientation
        
        switch(orient) {
        case UIImageOrientation.Up: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientation.UpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientation.Down: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI));
            break;
            
        case UIImageOrientation.DownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientation.LeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0);
            break;
            
        case UIImageOrientation.Left: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0);
            break;
            
        case UIImageOrientation.RightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0);
            break;
            
        case UIImageOrientation.Right: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0);
            break;
         default:
            NSException(name: "fail", reason: NSInternalInconsistencyException, userInfo: nil).raise()
        }
        UIGraphicsBeginImageContext(bounds.size)
        
        let context = UIGraphicsGetCurrentContext();
        
        if (orient == UIImageOrientation.Right || orient == UIImageOrientation.Left) {
            CGContextScaleCTM(context, -scaleRatio, scaleRatio);
            CGContextTranslateCTM(context, -height, 0);
        }
        else {
            CGContextScaleCTM(context, scaleRatio, -scaleRatio);
            CGContextTranslateCTM(context, 0, -height);
        }
        
        CGContextConcatCTM(context, transform);
        
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
        
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
         return imageCopy;
    }
    
    
}