//
//  AppDelegate.swift
//  MyApp
//
//  Created by Ronin on 16/10/2017.
//  Copyright © 2017 Ronin. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
       
        /*let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if AppState.shared.userLoggedIn {
            self.window?.rootViewController = storyBoard.instantiateViewController(controller: MainTabBarController.self)
        } else {
            self.window?.rootViewController = storyBoard.instantiateViewController(controller: LoginViewController.self)
        }*/
        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(30))
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: .CloseSafariViewControllerNotification, object: url)
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let clientVk = VKontakteAPI()
        clientVk.getFriendsRequests {(friends, error) in
            if var loadedFriends = friends {
                loadedFriends = loadedFriends.map {$0.friendshipReuqest = true; return $0}
                do {
                    let realm = try Realm()
                    try realm.write {
                        realm.add(loadedFriends, update: true)
                    }
                    let usersInDataBaseToDelete = NSPredicate(format: "NOT id IN %@ AND friendshipReuqest == %@", loadedFriends.map {$0.id}, NSNumber(value: true))
                    let usersToDelete = realm.objects(User.self).filter(usersInDataBaseToDelete)
                    try realm.write {
                        realm.delete(usersToDelete)
                    }
                    if loadedFriends.count == 0 && usersToDelete.count == 0 {
                        completionHandler(.noData)
                    } else {
                        completionHandler(.newData)
                    }
                    
                } catch {
                    completionHandler(.failed)
                }
                
            } else {
                completionHandler(.failed)
            }
        }
    }
}

