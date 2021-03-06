//
//  VkAPI.swift
//  MyApp
//
//  Created by Ronin on 31/10/2017.
//  Copyright © 2017 Ronin. All rights reserved.
//

import Foundation
import Alamofire

struct VKResponse<T:Decodable>: Decodable {
    let response: T
}

struct ResponseErrorMessage : Codable {
    let error_code : Int?
    let error_msg : String?
}

struct ResponseError: Codable {
    let error: ResponseErrorMessage
}

struct PostResponse: Decodable {
    let postId: Int
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
    }
}

struct UploadServer: Decodable {
    let uploadUrl: URL
    let albumId: Int
    let userid: Int
    
    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case albumId = "album_id"
        case userid = "user_id"
    }
}
struct UploadedPhotoResponse: Codable {
    let hash: String
    let photo: String
    let server: Int
}

struct JoinGroupResponse: Codable {
    let response: Int
}

struct UserFriendsResponse: Codable {
    let items: [Int]
    let count: Int
}

struct UserPhotosResponse: Codable {
    let items: [AlbumPhoto]
    let count: Int
}

struct UserGroupsResponse: Decodable {
    let count: Int
    let items: [Group]
}

class VKontakteAPI {
    
    let appToken = VKConstants.accessToken
    
    static func authRequest() -> URL {
        var urlComponents = URLComponents()
        urlComponents.host   = "oauth.vk.com"
        urlComponents.scheme = "https"
        urlComponents.path   = "/authorize"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "revoke", value: "1"),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "scope", value: "email, offline, friends, wall, groups, photos, messages"),
            URLQueryItem(name: "redirect_uri", value: "vk\(VKConstants.appId)://authorize"),
            URLQueryItem(name: "client_id", value: VKConstants.appId)
        ]
        
      return urlComponents.url!
        
    }

    func getUser(userToken: String, completionHandler:@escaping  (_ user: [User]?, _ error: Error?)->()) {
        let parameters = ["fields": "photo_100"]
        VKontakteAPI().getResourse(VKConstants.users, parameters: parameters, type: [User].self, completionHandler: completionHandler)
    }
    
    func getFriendsRequests(_ completionHandler:@escaping  (_ userFriendsRequests: [User]?, _ error: Error?)->()) {
        let parameters: Parameters = [:]
        getResourse(VKConstants.friendsRequests, parameters: parameters, type: UserFriendsResponse.self) {(userIds, error) in
            if let userIds = userIds {
                VKontakteAPI().loadFriendsWithIds(userIds: userIds.items, completionHandler: completionHandler)
            } else {
                completionHandler(nil,error)
            }
        }
    }

    func getMessageHistroryWith(user: User, completionHandler:@escaping  (_ message: [Message]?, _ error: Error?)->()) {
        let parameters: Parameters = ["user_id":user.id]
        getResourse(VKConstants.getMessageHistory, parameters: parameters, type: MessageResponse.self) {(responseMessages, error) in
            if let response = responseMessages {
               completionHandler(response.items,error)
            } else {
                completionHandler(nil,error)
            }
        }
    }
    
    func send(message: String, to user: User, completionHandler:@escaping (_ success: Bool,_ error: Error?)->()) {
        let parameters: Parameters = ["user_id": user.id,
                                      "message": message]
        
        getResourse(VKConstants.sendMessage, parameters: parameters, type: Int.self) { (messageId, error) in
            if messageId != nil {
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }

    func getGroupMembers(groupId: Int, completionHandler:@escaping (_ membersCount: Int,_ groupId: Int,_ error: Error?)->()) {
        let parameters: Parameters = ["group_id": groupId]
        getResourse(VKConstants.groupMembers, parameters: parameters, type: GroupMembers.self) {(groupMembers, error) in
            if let groupMembers = groupMembers {
                completionHandler(groupMembers.count, groupId, nil)
            } else {
                completionHandler(0, groupId, error)
            }
        }
    }
    
    func getGroups(_ searchText: String, userToken: String, completionHandler:@escaping (_ groups: [Group]?,_ error: Error?)->() ) {
        let parameters: Parameters = ["q":searchText]
        getResourse(VKConstants.groupsSearch, parameters: parameters, type: UserGroupsResponse.self) {(response, error) in
            if let response = response {
                completionHandler(response.items, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func getUserGroups(_ completionHandler:@escaping (_ groups:[Group]?,_ error:Error?)->() ) {
        let parameters: Parameters = ["extended": "1"]
        getResourse(VKConstants.groups, parameters: parameters, type: UserGroupsResponse.self) {(response, error) in
            if let response = response {
                completionHandler(response.items, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func joinGroup(_ group: Group, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> () ) {
        let parameters: Parameters = ["group_id": group.id]
        getResourse(VKConstants.groupsJoin, parameters: parameters, type: Int.self) {(_ response, error) in
            completionHandler(response ?? 0 == 1, error)
        }
    }
    
    func leaveGroup(_ group: Group, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> () ) {
        let parameters: Parameters = ["group_id": group.id]
        getResourse(VKConstants.groupsLeave, parameters: parameters, type: Int.self) {(_ response, error) in
            completionHandler(response ?? 0 == 1, error)
        }
    }
    
    func getPhotos(ownerId: Int, completionHandler:@escaping (_ groups: [AlbumPhoto]?,_ error: Error?)->()) {
        let parameters: Parameters = ["album_id": "profile",
                      "owner_id": ownerId]
        getResourse(VKConstants.photosURL, parameters: parameters, type: UserPhotosResponse.self) {(_ response, error) in
            if let response = response {
                completionHandler(response.items,error)
            } else {
                completionHandler(nil,error)
            }
        }
    }
    
    private func uploadImageDataTo(url urlRequest: URLRequest,
                                   data: Data,
                                   name: String,
                                   fileName: String,
                                   mimeType: String,
                                   completionHandler:@escaping (_ newsPhoto: NewsPhoto?,_ error: Error?)->()) {
        
        Alamofire.upload(multipartFormData: {(multipartFormData) in
            multipartFormData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
        }, with: urlRequest, encodingCompletion: { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseData {[weak self] (response) in
                    if let data = response.data {
                        var result:UploadedPhotoResponse?
                        do {
                            result = try JSONDecoder().decode(UploadedPhotoResponse.self, from: data)
                        } catch let error {
                            completionHandler(nil, error)
                        }
                        if let photo = result {
                            self?.saveWallPhoto(photo, completionHandler: completionHandler)
                        }
                    }
                }
                return
            case .failure(let encodingError):
                completionHandler(nil, encodingError)
            }
        })
    }
    
    func uploadPhoto(_ photo: UIImage, completionHandler:@escaping (_ newsPhoto: NewsPhoto?,_ error: Error?)->()) {
        let token = AppState.shared.token ?? ""
        let parameters: Parameters = ["access_token": token]
        
        getResourse(VKConstants.wallUploadServer, parameters: parameters, type: UploadServer.self) {[weak self] (uploadServer, error) in
            if let uploadServer = uploadServer {
                guard let urlRequest = try? URLRequest(url: uploadServer.uploadUrl, method: .post) else {
                    completionHandler(nil, error)
                    return
                }
                guard let imageData = UIImageJPEGRepresentation(photo, 1.0) else {
                    completionHandler(nil, VKError.JPEGRepresentationFailed)
                    return
                }
                self?.uploadImageDataTo(url: urlRequest, data: imageData, name: "photo", fileName: "photo.jpeg", mimeType: "image/jpeg", completionHandler: completionHandler)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func saveWallPhoto(_ photoResponse: UploadedPhotoResponse, completionHandler:@escaping (_ newsPhoto:NewsPhoto?,_ error: Error?)->()) {
        let parameters = ["user_id": AppState.shared.userId ?? "",
                          "photo": photoResponse.photo,
                          "server": photoResponse.server,
                          "hash": photoResponse.hash] as [String : Any]
        getResourse(VKConstants.saveWallPhoto, parameters: parameters, type: [NewsPhoto].self) { (photos, error) in
            if let photos = photos, let photo = photos.first {
               completionHandler(photo, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func getUserNewsFeed(_ completionHandler:@escaping (_ response:NewsResponse?,_ error: Error?)->()) {
        let parameters = ["count":50] as [String : Any]
        getResourse(VKConstants.newsFeed, parameters: parameters, type: NewsResponse.self, completionHandler: completionHandler)
    }
    
    private func getResourse<T:Decodable>(_ url:String , parameters:[String : Any], type:T.Type, completionHandler: @escaping (_ objects:T?,_ error:Error?)->() ) {
        guard let token = AppState.shared.token else {
            completionHandler(nil, VKError.tokenFailed)
            return
        }
        var finalParameters = parameters
        if finalParameters["access_token"] == nil {
           finalParameters.updateValue(token, forKey: "access_token")
        }
        finalParameters.updateValue("5.69", forKey: "v")
        Alamofire.request(url, method: .get, parameters: finalParameters, encoding: URLEncoding.default, headers: nil).responseData(queue:DispatchQueue.global(qos: .userInitiated)) {(response) in
            
            if response.result.isSuccess, let data = response.data {
                var result:VKResponse<T>?
                //var result = try? JSONDecoder().decode(VKResponse<T>.self, from: data)
                
                do {
                    result = try JSONDecoder().decode(VKResponse<T>.self, from: data)
                } catch let error {
                    print(error)
                }
                
                if let objects = result?.response {
                    completionHandler(objects, nil)
                } else {
                    var error = VKError.readDataError(description: "unkown app error", errorCode: 0)
                    if let errorResponse = try? JSONDecoder().decode(ResponseError.self, from: data), let errorMessage = errorResponse.error.error_msg {
                        error = VKError.readDataError(description: errorMessage, errorCode: errorResponse.error.error_code ?? 0)
                    }
                    completionHandler(nil, error)
                }
                
            } else {
                completionHandler(nil, response.result.error)
            }
        }
    }
    
    func getUserFriends(_ completionHandler: @escaping (_ friends:[User]?,_ error: Error?)->() ) {
        let parameters = [String:Any]()
        getResourse(VKConstants.friends, parameters: parameters, type: UserFriendsResponse.self) {(userIds, error) in
            if let userIds = userIds {
                VKontakteAPI().loadFriendsWithIds(userIds: userIds.items, completionHandler: completionHandler)
            } else {
                completionHandler(nil,error)
            }
        }
    }
    
    func loadFriendsWithIds(userIds: [Int], completionHandler: @escaping (_ friends: [User]?,_ error: Error?)->() ) {
        let parameters: Parameters = ["user_ids": userIds,
                      "access_token": appToken,
                      "fields":["photo_100"]]
        getResourse(VKConstants.users, parameters: parameters, type: [User].self, completionHandler: completionHandler)
    }
    
    func postOnWall(_ message: String, attachment: NewsPhoto?, completionHandler:@escaping (Bool, Error?)->()) {
        let userId = AppState.shared.userId ?? 0
        guard let token = AppState.shared.token else {
            completionHandler(false, VKError.tokenFailed)
            return
        }
        var parameters: Parameters = ["owner_id": userId,
                          "friends_only": 1,
                          "message": message,
                          "access_token": token]
        if let attachment = attachment, let userId = AppState.shared.userId {
            parameters.updateValue("photo\(userId)_\(attachment.id)", forKey: "attachments")
        }
        parameters.updateValue("5.69", forKey: "v")
        Alamofire.request(VKConstants.wallPost, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess, let data = response.data {
                if (try? JSONDecoder().decode(VKResponse<PostResponse>.self, from: data)) != nil {
                    completionHandler(true, nil)
                } else {
                    var error = VKError.readDataError(description: "unkown app error", errorCode: 0)
                    if let errorResponse = try? JSONDecoder().decode(ResponseError.self, from: data), let errorMessage = errorResponse.error.error_msg {
                        error = VKError.readDataError(description: errorMessage, errorCode: errorResponse.error.error_code ?? 0)
                    }
                    completionHandler(false, error)
                }
            } else {
                completionHandler(false, response.result.error)
            }
        }
    }
}

