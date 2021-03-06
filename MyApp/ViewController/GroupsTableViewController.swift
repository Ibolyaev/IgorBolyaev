//
//  GroupsTableViewController.swift
//  MyApp
//
//  Created by Ronin on 24/10/2017.
//  Copyright © 2017 Ronin. All rights reserved.
//

import UIKit
import Alamofire

class GroupsTableViewController: UITableViewController, UISearchBarDelegate, AlertShower {

    var groups = [Group]()
    var filteredGroups = [Group]()
    var selectedGroup: Group?
    let clientVk = VKontakteAPI()
    let cloudDatabase = CloudDatabase()
    var currentSearchWorkItem: DispatchWorkItem?
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for groups"
        
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        
        guard let token = AppState.shared.token, searchText != "" else { return }
        
        if currentSearchWorkItem != nil {
            currentSearchWorkItem?.cancel()
        }
        
        currentSearchWorkItem = DispatchWorkItem { [weak self] in
            self?.clientVk.getGroups(searchText, userToken: token) {[weak self] (groups, error) in
                if error == nil, let loadedGroups = groups  {
                    DispatchQueue.main.async {
                        self?.filteredGroups = loadedGroups
                        self?.groups = loadedGroups
                        self?.loadMembersCount()
                        self?.tableView.reloadData()
                    }
                } else {
                    self?.showError(with: error?.localizedDescription)
                }
            }
        }
        if let currentSearchWorkItem = currentSearchWorkItem {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(3), execute: currentSearchWorkItem)
        }
    }
    
    func loadMembersCount() {
        
        for group in groups {
            clientVk.getGroupMembers(groupId: group.id, completionHandler: {[weak self] (usersCount, groupId, error) in
                if group.id == groupId {
                    group.usersCount = usersCount
                    if let index = self?.groups.index(of: group) {
                        DispatchQueue.main.async {
                            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                        }
                    }                    
                }
            })
        }
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        if isFiltering() {
            return filteredGroups.count
        } else {
            return groups.count
        }        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupTableViewCell.reuseIdentifier, for: indexPath) as? GroupTableViewCell
        
        guard let groupCell = cell else {
            return UITableViewCell()
        }
        let group: Group
        if isFiltering() {
            group = filteredGroups[indexPath.row]
        } else {
            group = groups[indexPath.row]
        }
        groupCell.group = group
        
        return groupCell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isFiltering() {
            selectedGroup = filteredGroups[indexPath.row]
        } else {
            selectedGroup = groups[indexPath.row]
        }
        
        if let group = selectedGroup, !isFiltering() {
            askJoinGroup(group)
        }
        
        searchController.isActive = false
    }
    
    func joinGroup(_ group: Group) {
        clientVk.joinGroup(group) {[weak self] (success, error) in
            if success {
                self?.cloudDatabase.userDidJoinGroup(group)
                DispatchQueue.main.async {
                    self?.performSegue(withIdentifier: "unwindToUserGroup", sender: self)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError(with: error?.localizedDescription)
                }
            }
        }
    }
    
    func askJoinGroup(_ group: Group) {
        let alert = UIAlertController(title: group.name, message: "Would you like to join ?", preferredStyle: .alert)        
        alert.addAction(UIAlertAction(title: "Join", style: .default, handler: {[weak self] (_) in
            self?.joinGroup(group)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {[weak self] (_) in
            self?.selectedGroup = nil
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
}


extension GroupsTableViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        if let group = selectedGroup {
            askJoinGroup(group)
        }
    }
}

extension GroupsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
