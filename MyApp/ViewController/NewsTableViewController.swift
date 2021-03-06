//
//  NewsTableViewController.swift
//  MyApp
//
//  Created by Ronin on 08/01/2018.
//  Copyright © 2018 Ronin. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift

class NewsTableViewController: UITableViewController, AlertShower {
    
    var newsResponse: NewsResponse? {
        didSet {
            let filteredItems = newsResponse?.items?.filter({ (news) -> Bool in
                return news.type != "wall_photo"
            })
            // Update profile for every News
            updateProfiles(filteredItems)
            
        }
    }
    let clientVk = VKontakteAPI()
    var items: [News]? {
        didSet {
            tableView.reloadData()
            if let items = items {
                AppState.shared.saveLastNewsFrom(items)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 250
        
        tableView.register(UINib(nibName: "NewsWithPhotoTableViewCell", bundle: nil), forCellReuseIdentifier: NewsWithPhotoTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "NewsWithoutPhotoTableViewCell", bundle: nil), forCellReuseIdentifier: NewsWithoutPhotoTableViewCell.reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNews()
    }
    
    @IBAction func quitTouchUpInside(_ sender: UIBarButtonItem) {
        AppState.shared.quit(self)
    }
    private func updateProfiles(_ news:[News]?) {
        items = news?.flatMap({ (item) -> News? in
            var tempItem = item
            guard let source_id = item.source_id else {
                return nil
            }
            if source_id > 0 {
                guard let userProfile = (newsResponse?.profiles?.first() {$0.id == item.source_id}) else { return item }
                tempItem.profile = Profile(userProfile)
            } else {
                guard let groupProfile = (newsResponse?.groups?.first() {$0.id == -source_id}) else { return item }
                tempItem.profile = Profile(groupProfile)
            }
            
            return tempItem
        })
    }
    
    private func loadNews() {
        clientVk.getUserNewsFeed() {[weak self](news, error) in
            if let loadedNews = news {
                DispatchQueue.main.async {
                    self?.newsResponse = loadedNews
                }
            } else {
                self?.showError(with: error?.localizedDescription) 
            }
        }
    }
   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let items = items else { return UITableViewCell() }
        
        var anyNewsCell:NewsCell?
        var item = items[indexPath.row]
        
        if item.havePhoto {
           anyNewsCell = tableView.dequeueReusableCell(withIdentifier: NewsWithPhotoTableViewCell.reuseIdentifier, for: indexPath) as? NewsWithPhotoTableViewCell
        } else {
           anyNewsCell = tableView.dequeueReusableCell(withIdentifier: NewsWithoutPhotoTableViewCell.reuseIdentifier, for: indexPath) as? NewsWithoutPhotoTableViewCell
        }
        
        guard let newsCell = anyNewsCell else { return UITableViewCell() }
        newsCell.confugurateCell(news: item)
        
        return newsCell as! UITableViewCell
    }
}
