import Vision

enum CropType: UInt {
    case attentionBased = 1
    case objectnessBased = 2
    case face = 3
}

enum ImageFormat: UInt {
    case jpeg = 1
    case png = 2
}

@objc(SmartCropper)
class SmartCropper: NSObject {
    
    var resolve: RCTPromiseResolveBlock!
    var reject: RCTPromiseRejectBlock!

    @objc(request:withResolver:withRejecter:)
    func request(options:NSDictionary, resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void {
        if #available(iOS 13.0, *) {
            self.resolve = resolve
            self.reject = reject
            let path = options["path"] as! String
            let orientation = CGImagePropertyOrientation.init(rawValue: options["orientation"] as? UInt32 ?? CGImagePropertyOrientation.up.rawValue)!
            let preferBackgroundProcessing = options["preferBackgroundProcessing"] as? Bool ?? false
            let usesCPUOnly = options["usesCPUOnly"] as? Bool ?? false
            let saveFormat = ImageFormat.init(rawValue: options["saveFormat"] as? UInt ?? ImageFormat.jpeg.rawValue)!
            let quality = options["quality"] as? CGFloat ?? 1
            let cropType = CropType.init(rawValue: options["cropType"] as? UInt ?? CropType.attentionBased.rawValue)!
            
            guard let originImage = transformImage(path) else {
                self.reject("ERROR", "Failed to load image: \(path)", nil)
                return
            }
            
            var request: VNImageBasedRequest
            switch cropType {
                case .attentionBased:
                    request = VNGenerateAttentionBasedSaliencyImageRequest()
                case .objectnessBased:
                    request = VNGenerateObjectnessBasedSaliencyImageRequest()
                case .face:
                    request = VNDetectFaceRectanglesRequest()
            }
            
            do {
                let result = try self.generateSaliencyImage(path: path,
                                                            orientation: orientation,
                                                            usesCPUOnly: usesCPUOnly,
                                                            preferBackgroundProcessing: preferBackgroundProcessing,
                                                            saveFormat: saveFormat,
                                                            quality: quality,
                                                            originImage: originImage,
                                                            imageBasedRequest: request)
                self.resolve(result)
            } catch {
                self.reject("ERROR", error.localizedDescription, error)
            }
        } else {
            self.reject("ERROR", "'VNClassifyImageRequest' is only available in iOS 13.0 or newer", nil)
        }
    }
    
    @available(iOS 13.0, *)
    func generateSaliencyImage(path: String,
                               orientation: CGImagePropertyOrientation,
                               usesCPUOnly: Bool,
                               preferBackgroundProcessing: Bool,
                               saveFormat: ImageFormat,
                               quality: CGFloat,
                               originImage: UIImage,
                               imageBasedRequest: VNImageBasedRequest) throws -> [[String : Any]] {
        let handler = VNImageRequestHandler(ciImage: originImage.ciImage!,orientation: orientation)
        
        imageBasedRequest.usesCPUOnly = usesCPUOnly
        imageBasedRequest.preferBackgroundProcessing = preferBackgroundProcessing
        
        do {
            try handler.perform([imageBasedRequest])
        } catch {
            throw error
        }
        
        let objects = (imageBasedRequest.results as? [VNSaliencyImageObservation])?.first?.salientObjects ?? []
        
        var results = [[String: Any]]()
        let originSize = originImage.size
        
        for object in objects {
            let destPath = self.getDestPath("\(object.uuid).\(saveFormat == .png ? "png" : "jpg")")
            
            
            let width = object.boundingBox.width * originSize.width
            let height = object.boundingBox.height * originSize.height
            let x = object.boundingBox.origin.x * originSize.width
            let y = object.boundingBox.origin.y * originSize.height
            
            let cutImage = cropImage(inputImage: originImage, cropRect: CGRect(x: x, y: y, width: width, height: height))
            
            do {
                try (saveFormat == .png ? cutImage?.pngData() : cutImage?.jpegData(compressionQuality: quality))?.write(to: destPath)
                results.append(["path" : destPath.absoluteString,
                                "confidence": object.confidence,
                                "boundingBox": ["x": x,
                                                "y": originSize.height - height - y,
                                                "width": width,
                                                "height": height]])
            } catch {
                throw error
            }
        }
        
        return results
    }
    
    func getDestPath(_ filename: String) -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }
}

func transformImage(_ path: String) -> UIImage? {
    guard let initialImage = UIImage(contentsOfFile: path) else {
        return nil
    }
    
   return UIImage(ciImage: CIImage(image: initialImage)!.oriented(forExifOrientation: imageOrientationToTiffOrientation(initialImage.imageOrientation)))
}

func cropImage(inputImage: UIImage,cropRect: CGRect) -> UIImage?
{
    guard let cutImageRef = inputImage.ciImage?.cropped(to: cropRect)
    else {
        return nil
    }

    return UIImage(ciImage: cutImageRef)
}

func imageOrientationToTiffOrientation(_ value: UIImage.Orientation) -> Int32
{
    switch value {
        case .up:
            return 1
        case .down:
            return 3
        case .left:
            return 8
        case .right:
            return 6
        case .upMirrored:
            return 2
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .rightMirrored:
            return 7
    }
}
