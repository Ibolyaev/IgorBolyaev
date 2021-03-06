//
//  ChatTableViewCell.swift
//  MyApp
//
//  Created by Ronin on 16/02/2018.
//  Copyright © 2018 Ronin. All rights reserved.
//

import UIKit

class ReceiverChatTableViewCell: UITableViewCell, ChatCell {
    
    static let reuseIdentifier = "ReceiverChatTableViewCell"
    
    @IBOutlet var messageTextView: UITextView! {
        didSet {            
            messageTextView.layer.cornerRadius = 8
        }       
    }
    @IBOutlet var timeStemp: UILabel!
}
