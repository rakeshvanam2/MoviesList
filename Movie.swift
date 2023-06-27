struct Movie: Decodable {
    let title: String
    let year: String
    let runtime: String
    let cast: [String]
    let imdbID: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case runtime = "Runtime"
        case cast = "Cast"
        case imdbID = "imdbID"
    }
}
