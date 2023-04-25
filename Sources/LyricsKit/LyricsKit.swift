import SwiftUI
import SwiftSoup

@available(macOS 10.15, *)
public class LyricsKit: ObservableObject {
    @Published public var isParsingError: Bool = false
    @Published public var isLyricsAvailable: Bool = false
    @Published public var lyrics: [String] = [String]()
    
    private var queryString: String = ""
    public init() { }
    
    /**
     Fetch song lyrics from Melon API
     :param: title of the music
     :param: artist of the music
     
     - Important: Fetching with only the title is more reliable and has higher chance of getting the correct lyrics
    */
    public func fetch(title: String, artist: String? = nil) {
        if let artist = artist {
            let title = title.split(separator: " ").joined(separator: "+")
            let artist = artist.split(separator: " ").joined(separator: "+")
            queryString = String(format: "%@+%@", title, artist)
    
        } else {
            let title = title.split(separator: " ").joined(separator: "+")
            queryString = String(format: "%@", title)
        }
        
        // TODO: Improve this Pyramid of Doom
        let urlString = String(format: "%@%@%@", Global.base.path, Global.indexPostfix.path, queryString)
        guard let url = URL(string: urlString) else { fatalError("URL Error: unable to create query URL") }
        let urlRequest = URLRequest(url: url)
        request(with: urlRequest, encoding: .utf8) { result in
            switch result {
            case .success(let html):
                guard let id = self.parseQuerySongList(from: html) else { fatalError("Parse Error: unable to parse song id") }
                let urlString = String(format:"%@%@%@", Global.base.path, Global.detailPostfix.path, id)
                guard let url = URL(string: urlString) else { fatalError("URL Error: unable to create id query URL") }
                let urlRequest = URLRequest(url: url)
                self.request(with: urlRequest, encoding: .utf8) { result in
                    switch result {
                    case .success(let html):
                        if let lyrics = self.parseQuerySong(from: html) {
                            DispatchQueue.main.async {
                                self.lyrics = lyrics
                                self.isLyricsAvailable = true
                            }
                        }
                    case .failure(_):
                        self.isLyricsAvailable = false
                    }
                }
            case .failure(_):
                self.isParsingError = true
                self.isLyricsAvailable = false
            }
        }
        
    }
    
    // MARK: Private Functions
    
    /// Parse HTML of song list related to the query.
    ///
    /// - Parameter html: String typed HTML content from query with title and (if available) artist of the song.
    /// - Returns: ID of song given by the parameter. Provided by Melon.
    /// - Throws : Thrown when failed parsing HTML content.
    func parseQuerySongList(from html: String) -> String? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            let song = try document.select("td").array().first!
            let id = try song.select("input").attr("value")
            return id
        } catch {
            return nil
        }
    }
    
    /// Parse HTML of specific song related to the query.
    ///
    /// - Parameter html: String typed HTML content from query with title and (if available) artist of the song.
    /// - Returns: Lyrics of song given by the parameter. Provided by Melon.
    /// - Throws : Thrown when failed parsing HTML content.
    func parseQuerySong(from html: String) -> [String]? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            let lyrics: String = try document.select(".lyric").html()
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "<!-- height:auto; 로 변경시, 확장됨 -->", with: "")
            if lyrics.isEmpty { throw ParserError.noLyricsFoundError }
            return lyrics.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        } catch {
            print(error)
            return nil
        }
    }
    
    /// Request through URL created from the parse functions
    ///
    /// - Parameter url: URL including root Melon website and query parameters.
    /// - Parameter encoding: String encoding for returned content from url.
    /// - Parameter completion: Completion handler for URLSession data task.
    /// - Returns: Completion handler from URLSession data task. Returns `requestError` if invalid response occurs.
    func request(with urlRequest: URLRequest, encoding: String.Encoding, completion: @escaping (Result<String, Error>) -> Void) {
        URLSession.shared.invalidateAndCancel()
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                return completion(Result.failure(error!))
            }
            
            if let data = data,
               let html = String(data: data, encoding: encoding),
               let response = response as? HTTPURLResponse,
               response.statusCode == 200 {
                return completion(Result.success(html))
            } else {
                return completion(Result.failure(ParserError.requestError))
            }
        }.resume()
    }
}
