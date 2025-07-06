import CoreML
import CoreImage
import Vision
import Accelerate

/// 1. takes JPEG/PNG `Data`
/// 2. finds *largest* face
/// 3. returns a **unit-norm 512-float vector**
struct FaceEmbeddingService {
    private let size = 112
    private lazy var model: BuffaloL = {
        try! BuffaloL(configuration: .init())
    }()
    
    /// Returns `true` when cosine ≥ 0.60 (empirically safe for w600k_r50).
    func evaluateMatch(passport: Data, selfie: Data) throws -> Bool {
        var svc   = FaceEmbeddingService()
        let e1    = try svc.embedding(from: passport)
        let e2    = try svc.embedding(from: selfie)
        let cos   = svc.cosine(e1, e2)
        print("🧠 Cosine similarity: \(cos)")
        return cos >= 0.70
    }
    
    // MARK: - Public API ----------------------------------------------------
    mutating func embedding(from jpeg: Data) throws -> [Float] {
        let cg = try cropLargestFace(from: jpeg)
        let arr = try mlMultiArray(from: cg)        // shape [3,112,112]
        let out = try model.prediction(input_1: arr)
        let raw = out._683                     // MLMultiArray [512]
        return unitNorm(raw)
    }
    
    func cosine(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }    // already unit-norm
    }
    
    // MARK: - Internals -----------------------------------------------------
    private func cropLargestFace(from jpeg: Data) throws -> CGImage {
        let handler = VNImageRequestHandler(data: jpeg, options: [:])
        let req     = VNDetectFaceRectanglesRequest()
        try handler.perform([req])

        guard
            let face = (req.results)?
                       .max(by: { $0.boundingBox.area < $1.boundingBox.area })
        else {
            throw NSError(domain: "Face", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No face found"])
        }
        let image = CIImage(data: jpeg)!
        let context = CIContext()
        let boundingBox = VNImageRectForNormalizedRect(face.boundingBox, Int(image.extent.width), Int(image.extent.height))
        let croppedCIImage = image.cropped(to: boundingBox)
        guard let cg = context.createCGImage(croppedCIImage, from: croppedCIImage.extent) else {
            throw NSError(domain: "Face", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from cropped face"])
        }
        return cg.resize(to: CGSize(width: size, height: size))
    }
    
    private func mlMultiArray(from img: CGImage) throws -> MLMultiArray {
        // 8‑bit BGRA buffer → normalised Float32 BGR tensor, channels‑first
        let bytesPerPixel  = 4
        let bytesPerRow    = bytesPerPixel * size
        var rawRGBA        = [UInt8](repeating: 0, count: bytesPerRow * size)

        // 1. Draw resized face into an 8‑bit BGRA context
        guard let ctx = CGContext(data: &rawRGBA,
                                   width: size, height: size,
                                   bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue |
                                               CGBitmapInfo.byteOrder32Little.rawValue) else {
            throw NSError(domain: "Face", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
        }
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: size, height: size))

        // 2. Create MLMultiArray [3,112,112] Float32
        let tensor = try MLMultiArray(shape: [3, size, size] as [NSNumber], dataType: .float32)

        // 3. Copy & normalise: (channel value − 127.5) / 128
        let plane  = size * size                       // elements per channel
        for y in 0..<size {
            for x in 0..<size {
                let pxIndex = y * bytesPerRow + x * 4  // BGRA
                let b = Float(rawRGBA[pxIndex])
                let g = Float(rawRGBA[pxIndex + 1])
                let r = Float(rawRGBA[pxIndex + 2])

                let idx = y * size + x                 // flattened (H,W)
                tensor[idx]            = NSNumber(value: (b - 127.5) / 128.0)          // channel 0 (B)
                tensor[plane + idx]    = NSNumber(value: (g - 127.5) / 128.0)          // channel 1 (G)
                tensor[2 * plane + idx] = NSNumber(value: (r - 127.5) / 128.0)         // channel 2 (R)
            }
        }
        return tensor
    }
    
    
    private func unitNorm(_ ma: MLMultiArray) -> [Float] {
        let f = (0..<ma.count).map { ma[$0].floatValue }
        var sum: Float = 0; vDSP_svesq(f, 1, &sum, vDSP_Length(f.count))
        let inv = 1 / sqrt(sum)
        return f.map { $0 * inv }
    }
}

private extension CGRect { var area: CGFloat { width * height } }
private extension CGImage {
    func resize(to size: CGSize) -> CGImage {
        let ctx = CGContext(data: nil,
                            width: Int(size.width), height: Int(size.height),
                            bitsPerComponent: bitsPerComponent, bytesPerRow: 0,
                            space: colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: bitmapInfo.rawValue)!
        ctx.interpolationQuality = .high
        ctx.draw(self, in: CGRect(origin: .zero, size: size))
        return ctx.makeImage()!
    }
}
