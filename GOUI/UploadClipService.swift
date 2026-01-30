import Foundation

protocol UploadClipService {
    func uploadClip(fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void)
}

struct StubUploadClipService: UploadClipService {
    enum StubError: Error {
        case comingSoon
    }

    func uploadClip(fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        completion(.failure(StubError.comingSoon))
    }
}
