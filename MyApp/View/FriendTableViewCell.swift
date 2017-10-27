//
//  FriendTableViewCell.swift
//  MyApp
//
//  Created by Ronin on 24/10/2017.
//  Copyright © 2017 Ronin. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {
    static let reuseIdentifier = "friendCell"
    var friend:Friend? {
        didSet {            
            nameLabel?.text = friend?.name
            //profileImageView?.image = friend?.profilePicture
            //guard let profileURL = friend?.photoURL else { return }
            
            
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView?.layer.cornerRadius = profileImageView.frame.width / 2
            profileImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    
}