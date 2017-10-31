//
//  UserStroryTableViewController.swift
//  MyApp
//
//  Created by Ronin on 18/10/2017.
//  Copyright © 2017 Ronin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FriendsTableViewController: UITableViewController {

    private var friends = [Friend]()
    var currentUserId:String?
    let VKClient = VKontakteAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUserId = "6823870"
    }

    override func viewWillAppear(_ animated: Bool) {
        if friends.count == 0 {
           updateList()
        }
    }
    
    func updateList() {
        guard let currentUserId = currentUserId else { return }
        
        VKClient.getUserFriends(userId: currentUserId) {[weak self] (friends, error) in
            if let loadedFriends = friends {
                self?.friends = loadedFriends
                self?.tableView.reloadData()
            } else {
                print(error ?? "Failed to load data")
            }
        }
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.reuseIdentifier, for: indexPath) as? FriendTableViewCell
        guard let friendCell = cell else { return UITableViewCell() }        
        
        let friend = friends[indexPath.row]
        friendCell.friend = friend
        
        Alamofire.request(friend.photo.url).responseData {[weak friendCell] (response) in
            if response.result.isSuccess {
                
                if let data = response.result.value {
                    if let image = UIImage(data: data) {
                        if friendCell?.friend?.photo.url == response.request?.url?.absoluteString {
                            friendCell?.profileImageView?.image = image
                            friendCell?.friend?.photo.image = image
                        }
                    }
                }
            }
        }
        
        return friendCell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFriendPictures",
            let friend = (sender as? FriendTableViewCell)?.friend,
        let friendPhotoCollectionView = segue.destination as? FriendPhotoCollectionViewController {
            friendPhotoCollectionView.friend = friend
        }
    }
    

}
