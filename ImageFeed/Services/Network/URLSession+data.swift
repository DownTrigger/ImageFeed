import Foundation
import Logging

// MARK: - NetworkError
enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

// MARK: - URLSession
extension URLSession {
    
    // MARK: - Logger
    private static let logger = Logger(label: "urlsession")
    
    // MARK: - Data
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
//                    Self.logger.error("URLSession.data]: NetworkError.httpStatusCode – \(statusCode)")
                    print("[URLSession.data]: NetworkError.httpStatusCode – \(statusCode)")
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
//                Self.logger.error("[URLSession.data]: NetworkError.urlRequestError – \(error.localizedDescription)")
                print("[URLSession.data]: NetworkError.urlRequestError – \(error.localizedDescription)")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
//                Self.logger.error("[URLSession.data]: NetworkError.urlSessionError")
                print("[URLSession.data]: NetworkError.urlSessionError")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        })
        
        return task
    }
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        
        let decoder = JSONDecoder()
        
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
//                    Self.logger.error("[URLSession.objectTask]: DecodingError – \(error.localizedDescription), Data: \(String(data: data, encoding: .utf8) ?? "")")
                    print("[URLSession.objectTask]: DecodingError – \(error.localizedDescription), Data: \(String(data: data, encoding: .utf8) ?? "")")
                    completion(.failure(error))
                }
            case .failure(let error):
//                Self.logger.error("[URLSession.objectTask]: NetworkError – \(error)")
                print("[URLSession.objectTask]: NetworkError – \(error)")
                completion(.failure(error))
            }
        }
        return task
    }
}
