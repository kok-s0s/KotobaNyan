import Foundation

struct JishoJapanese: Decodable {
    let word: String?
    let reading: String?
}

struct JishoWord: Identifiable, Decodable {
    let id = UUID()
    let japanese: [JishoJapanese]
    let senses: [JishoSense]
    let is_common: Bool?
    let tags: [String]?
    let jlpt: [String]?
    
    enum CodingKeys: String, CodingKey {
        case japanese, senses, is_common, tags, jlpt
    }
}

struct JishoSense: Decodable {
    let english_definitions: [String]
    let parts_of_speech: [String]
    let info: [String]?
    let links: [JishoSenseLink]?
}

struct JishoSenseLink: Decodable {
    let text: String?
    let url: String?
}

class JishoAPIManager {
    static let shared = JishoAPIManager()
    private init() {}
    
    enum JishoAPIError: Error, LocalizedError {
        case network
        case rateLimited
        case server
        case decode
        case unknown
        var errorDescription: String? {
            switch self {
            case .network: return "网络异常，请检查网络连接。"
            case .rateLimited: return "请求过于频繁，请稍后再试。"
            case .server: return "服务器错误，请稍后重试。"
            case .decode: return "数据解析失败。"
            case .unknown: return "未知错误。"
            }
        }
    }
    
    func search(keyword: String, completion: @escaping ([JishoWord], JishoAPIError?) -> Void) {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://jisho.org/api/v1/search/words?keyword=\(encoded)") else {
            completion([], .unknown)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion([], .network)
                return
            }
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 429 {
                    completion([], .rateLimited)
                    return
                } else if http.statusCode >= 500 {
                    completion([], .server)
                    return
                } else if http.statusCode != 200 {
                    completion([], .unknown)
                    return
                }
            }
            guard let data = data else {
                completion([], .network)
                return
            }
            do {
                let result = try JSONDecoder().decode(JishoAPIResult.self, from: data)
                completion(result.data, nil)
            } catch {
                completion([], .decode)
            }
        }.resume()
    }
}

struct JishoAPIResult: Decodable {
    let data: [JishoWord]
}
