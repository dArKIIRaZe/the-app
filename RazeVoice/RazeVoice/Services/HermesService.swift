import Foundation
import Combine

class HermesService: ObservableObject {
    @Published var status: String = "Idle"

    // CHANGE THIS to your relay server address
    // Example: "https://voice.razetech.co.uk" or "https://relay.razetech.co.uk"
    var baseURL: String = "https://voice.razetech.co.uk"

    func send(audio: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat") else {
            completion(.failure(NSError(domain: "Raze", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"voice.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        DispatchQueue.main.async { self.status = "Sending..." }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.status = "Error: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    self.status = "No response"
                    completion(.failure(NSError(domain: "Raze", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty response"])))
                    return
                }
                self.status = "Idle"
                completion(.success(data))
            }
        }
        task.resume()
    }
}
