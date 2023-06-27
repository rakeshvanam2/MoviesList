import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var movies: [Movie] = []
    private var currentPage = 1
    private let pageSize = 10
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Movies"
        
        // Configure table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MovieCell.self, forCellReuseIdentifier: "MovieCell")
        
        // Add table view to the view hierarchy
        view.addSubview(tableView)
        
        // Set table view constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Load movies from API or local storage
        if Reachability.isConnectedToNetwork() {
            fetchMoviesFromAPI()
        } else {
            fetchMoviesFromLocalDB()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies[indexPath.row]
        cell.configure(with: movie)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fetch more movies when reaching the last cell
        if indexPath.row == movies.count - 1 {
            fetchMoreMovies()
        }
    }
    
    private func fetchMoviesFromAPI() {
        let urlString = "http://task.auditflo.in/1.json"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
                if let data = data {
                    self?.parseMoviesFromData(data)
                    self?.saveMoviesToLocalDB()
                } else if let error = error {
                    print("Failed to fetch movies: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
    }
    
    private func parseMoviesFromData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(MovieData.self, from: data)
            self.movies = movieData.movies
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to parse movie data: \(error.localizedDescription)")
        }
    }
    
    private func saveMoviesToLocalDB() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        for movie in movies {
            let movieEntity = MovieEntity(context: context)
            movieEntity.title = movie.title
            movieEntity.year = movie.year
            movieEntity.runtime = movie.runtime
            movieEntity.cast = movie.cast.joined(separator: ", ")
            movieEntity.imdbID = movie.imdbID
        }
        do {
            try context.save()
        } catch {
            print("Failed to save movies to local database: \(error.localizedDescription)")
        }
    }
    
    private func fetchMoviesFromLocalDB() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        do {
            let movieEntities = try context.fetch(fetchRequest)
            self.movies = movieEntities.map { Movie(entity: $0) }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to fetch movies from local database: \(error.localizedDescription)")
        }
    }
    
    private func fetchMoreMovies() {
        currentPage += 1
        let urlString = "http://task.auditflo.in/\(currentPage).json"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
                if let data = data {
                    self?.parseMoreMoviesFromData(data)
                    self?.saveMoviesToLocalDB()
                } else if let error = error {
                    print("Failed to fetch more movies: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
    }
    
    private func parseMoreMoviesFromData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(MovieData.self, from: data)
            let newMovies = movieData.movies
            self.movies.append(contentsOf: newMovies)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to parse more movie data: \(error.localizedDescription)")
        }
    }
}
