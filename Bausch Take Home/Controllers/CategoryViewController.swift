//
//  CategoryViewController.swift
//  Bausch Take Home
//
//  Created by Tim Bausch on 1/5/22.
//

import UIKit

class CategoryViewController: UITableViewController {
    
    // MARK: - Properties

    var categories = [String]()
    var meals = [[MealsInCategory]]()
    var indicator = UIActivityIndicatorView()
    
    let semaphore = DispatchSemaphore(value: 1)
    let queue = DispatchQueue.global()

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Recipe Collection"
        activityIndicator()
        indicator.startAnimating()
        
        queue.async {
            self.semaphore.wait()
            self.fetchCategoryJSON()
            self.semaphore.signal()
        }
        
        queue.async {
            self.semaphore.wait()
            self.fetchMealsJSON(for: self.categories)
            self.semaphore.signal()
        }
        
        DispatchQueue.main.async {
            self.semaphore.wait()
            self.tableView.reloadData()
            self.semaphore.signal()
            self.indicator.stopAnimating()
            self.indicator.hidesWhenStopped = true
        }
        
    }
    
    // MARK: - Helper Functions
    
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    func fetchCategoryJSON() {
        let urlString: String
        urlString = "https://www.themealdb.com/api/json/v1/1/categories.php"
        if let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url) {
                parseCategory(json: data)
                return
            }
        }
        performSelector(onMainThread: #selector(showError), with: nil, waitUntilDone: false)
    }
    
    func parseCategory(json: Data) {
            let decoder = JSONDecoder()
            if let jsonCategory = try? decoder.decode(Categories.self, from: json) {
                categories = jsonCategory.categories.map { $0.strCategory }.sorted()
            }
        }
    
    func fetchMealsJSON(for categories: [String]) {
        var urlString: String
        var localCategory: String
        for i in 0..<categories.count {
            localCategory = categories[i]
            urlString = "https://www.themealdb.com/api/json/v1/1/filter.php?c=\(localCategory)"
            if let url = URL(string: urlString) {
                if let data = try? Data(contentsOf: url) {
                    parseMeal(json: data)
                }
            }
        }
    }
    
    func parseMeal(json: Data) {
        let decoder = JSONDecoder()
        if let jsonMeal = try? decoder.decode(Meals.self, from: json) {
            let localMeal = jsonMeal.meals
            let sorted = localMeal.sorted{ $0.strMeal < $1.strMeal }
            meals.append(sorted)
            
        }
    }

    @objc func showError() {
        let ac = UIAlertController(title: "Loading error", message: "There was a problem loading the data; please check your connection and try again.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac,animated: true)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meals[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MealCell", for: indexPath) as! CategoryTableViewCell
        let title = meals[indexPath.section][indexPath.row].strMeal
        cell.titleLabel.text = title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor(named: "default")
        header.textLabel?.text = header.textLabel?.text?.capitalized
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        header.textLabel?.frame = header.bounds
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ListToDetail" {
            let detailVC = segue.destination as! DetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let mealID = meals[indexPath.section][indexPath.row].idMeal
            detailVC.urlString = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(mealID)"
        }
    }

}
