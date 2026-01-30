import AVFoundation
import UIKit

final class ThumbnailService {
    static let shared = ThumbnailService()
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "ThumbnailServiceQueue", qos: .userInitiated)

    func cachedThumbnail(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func thumbnail(for clip: Clip, recording: VideoRecording, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(recording.id.uuidString)-\(clip.startOffset)" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            completion(cached)
            return
        }

        queue.async {
            let asset = AVURLAsset(url: recording.fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: clip.startOffset, preferredTimescale: 600)
            generator.generateCGImageAsynchronously(for: time) { _, imageRef, _, result, _ in
                guard result == .succeeded, let imageRef else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let image = UIImage(cgImage: imageRef)
                self.cache.setObject(image, forKey: cacheKey)
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }
}
