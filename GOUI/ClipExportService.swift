import AVFoundation

final class ClipExportService {
    enum ExportError: Error {
        case exportFailed
        case invalidRange
    }

    func exportClip(clip: Clip, recording: VideoRecording, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVURLAsset(url: recording.fileURL)
        guard clip.endOffset > clip.startOffset else {
            completion(.failure(ExportError.invalidRange))
            return
        }
        let startTime = CMTime(seconds: clip.startOffset, preferredTimescale: 600)
        let endTime = CMTime(seconds: clip.endOffset, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(ExportError.exportFailed))
            return
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("clip-\(UUID().uuidString).mp4")
        export.timeRange = timeRange

        Task {
            do {
                try await export.export(to: outputURL, as: .mp4)
                await MainActor.run {
                    completion(.success(outputURL))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}
