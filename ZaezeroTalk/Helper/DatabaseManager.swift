//
//  DatabaseManager.swift
//  ZaezeroTalk
//
//  Created by 재영신 on 2021/11/08.
//

import Foundation
import Firebase
import FirebaseStorage

enum InviteType {
    case create
    case append
}

class DatabaseManager{
    static let shared = DatabaseManager()
    let ref = Database.database().reference()
    private var addMessageObserver: UInt?
    private var roomObserver: UInt?
    private var messageObserver: UInt?
    private var roomListObserver = [String:UInt]()
    
    private init(){
        
    }
    
}

// MARK: - Room
extension DatabaseManager {
    func registerRoomListObserver(addCompletion: @escaping (String,ChatingRoom?) -> Void , removeCompletion: @escaping (String) -> Void) {
        
        ref.child("UserRooms/\(ConnectedUser.shared.uid)").observe(.childAdded) { snapshot in
            let roomId = snapshot.key
            print("roomList Observer !!!! ->",snapshot)
            self.roomListObserver[roomId] = self.ref.child("Rooms/\(roomId)").observe(.value) { snapshot in
                guard snapshot.exists() else { return }
                
                print("room Observer!! ->",snapshot)
                do{
                    let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                    let result = try JSONDecoder().decode(ChatingRoom.self, from: data)
                    addCompletion(roomId,result)
                } catch {
                    print("-> Error registerRoomObserver: \(error.localizedDescription)")
                }
            }
            
        }
        ref.child("UserRooms/\(ConnectedUser.shared.uid)").observe(.childRemoved) { snapshot in
            print("removed snapshot!!!! ->",snapshot)
            removeCompletion(snapshot.key)
        }
        
    }
    
    func sendMessage(sendMessage: [String: Any], roomId: String) {
        let messageAutoId = ref.childByAutoId().key!
        
        if sendMessage["type"] as! String == "image" {
            print("content!!! ->",sendMessage["content"] as! UIImage)
            uploadImage(image: sendMessage["content"] as! UIImage, uid: ConnectedUser.shared.uid, path: "\(roomId)/\(messageAutoId).png") { url in
                var sendMessage = sendMessage
                sendMessage["content"] = url
                print("content!!! ->", url)
                self.updateChildValues([messageAutoId: sendMessage], forPath: "Rooms/\(roomId)/messages")
                self.updateChildValues(["lastMessage": "사진","lastMessageTime": sendMessage["time"]!], forPath: "Rooms/\(roomId)")
                self.ref.child("RoomUsers/\(roomId)").observeSingleEvent(of: .value, with: {
                    snapshot in
                    
                    let users = snapshot.value as! [String: String]
                    var readUsers = [String: String]()
                    users.forEach { (key,value) in
                        if value == "true" {
                            readUsers[key] = "true"
                        }
                    }
                    //방에 참여하고 있는 유저(value == true) 를 readUsers 에다가 저장
                    
                    self.ref.child("Rooms/\(roomId)/messages/\(messageAutoId)/readUsers").setValue(readUsers)
                    
                })
            }
        } else {
            self.updateChildValues([messageAutoId: sendMessage], forPath: "Rooms/\(roomId)/messages")
            self.updateChildValues(["lastMessage": sendMessage["content"]!,"lastMessageTime": sendMessage["time"]!], forPath: "Rooms/\(roomId)")
            self.ref.child("RoomUsers/\(roomId)").observeSingleEvent(of: .value, with: {
                snapshot in
                
                let users = snapshot.value as! [String: String]
                var readUsers = [String: String]()
                users.forEach { (key,value) in
                    if value == "true" {
                        readUsers[key] = "true"
                    }
                }
                //방에 참여하고 있는 유저(value == true) 를 readUsers 에다가 저장
                
                self.ref.child("Rooms/\(roomId)/messages/\(messageAutoId)/readUsers").setValue(readUsers)
                
            })
        }
        
        
        
        
        
    }
    func registerRoomObserver(id: String,completion: @escaping (String,ChatingRoom?) -> Void) {
        roomObserver = ref.child("Rooms/\(id)").observe(.value) { snapshot in
            guard snapshot.exists() else { return }
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(ChatingRoom.self, from: data)
                completion(id,result)
            } catch {
                print("-> Error registerRoomObserver: \(error.localizedDescription)")
                completion("",nil)
            }
        }
    }
    func createRoom(message: [String: Any],participantUids: [String],participantNames: [String], name: String?,type: String , completion: @escaping (String, ChatingRoom) -> Void) {
        let roomId = ref.childByAutoId().key!
        var participants = [String: Any]()
        
        var roomInfo: [String: Any] = [
            "uids": participantUids.toFBString(),
            "userNames": participantNames.toFBString(),
            "type": type
        ]
        
        if let name = name {
            roomInfo["name"] = name
        }
        
        let chatingRoom = ChatingRoom(userNames: participantNames.toFBString(), uids: participantUids.toFBString(),name: name, messages: [String: Message](), lastMessage: "", lastMessageTime: 0, type: type)
        
        ConnectedUser.shared.chatingRoomList.append((roomId,chatingRoom))
        
        ref.child("Rooms/\(roomId)").setValue(roomInfo,withCompletionBlock:
                                                {
            _,_ in
            participantUids.forEach {
                uid in
                participants[uid] = "false"
                self.ref.child("UserRooms/\(uid)").updateChildValues([roomId: "채팅룸"],withCompletionBlock: {
                    _,_ in
                    if uid == ConnectedUser.shared.uid {
                        completion(roomId,chatingRoom)
                    }
                })
            }
            participants[ConnectedUser.shared.uid] = "true"
            
            self.ref.child("RoomUsers/\(roomId)").setValue(participants) { error, _ in
                if error != nil {
                    print("error ->",error.debugDescription)
                } else {
                    self.sendMessage(sendMessage: message,roomId: roomId)
                }
            }
            
        })
    }
    
    func registerAddedMessageObserver(roomId: String, completion: @escaping (Message?, String?) -> Void){
        addMessageObserver = ref.child("Rooms/\(roomId)/messages").observe(.childAdded) { snapshot in
            if !snapshot.exists() {
                completion(nil, nil)
                return
            }
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(Message.self, from: data)
                completion(result, snapshot.key)
            } catch {
                print("-> Error registerRoomObserver: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
        }
        
    }
    
    func registerMessageObserver(roomId: String, completion: @escaping ([Message]?) -> Void) {
        messageObserver = ref.child("Rooms/\(roomId)/messages").observe(.value) { snapshot in
            if !snapshot.exists() {
                completion(nil)
                return
            }
            do{
                var messages = [Message]()
                for child in snapshot.children {
                    let child = child as! DataSnapshot
                    let data = try JSONSerialization.data(withJSONObject: child.value!, options: .prettyPrinted)
                    let result = try JSONDecoder().decode(Message.self, from: data)
                    messages.append(result)
                }
                
                completion(messages)
            } catch {
                print("-> Error registerRoomObserver: \(error.localizedDescription)")
                completion(nil)
                return
            }
        }
    }
    
    func removeRoomObserver() {
        guard let handle = roomObserver else { return }
        ref.removeObserver(withHandle: handle)
    }
    
    func removeMessageObserver(){
        guard let handle = messageObserver else { return }
        ref.removeObserver(withHandle: handle)
    }
    
    
    func enterRoom(uid: String,roomId: String){
        updateChildValues([uid: "true"], forPath: "RoomUsers/\(roomId)")
        
    }
    
    func leaveRoom(uid: String,roomId: String){
        updateChildValues([uid: "false"], forPath: "RoomUsers/\(roomId)")
    }
    
    func readMessage(messages: [String: Message], roomId: String){
        
        var newMessages = [String: Any]()
        
        messages.forEach { id,message in
            var newMessage = message
            guard var readUsers = newMessage.readUsers else { return } //exit message는 readUsers 프로퍼티가 없다.
            readUsers[ConnectedUser.shared.uid] = "true"
            newMessage.readUsers = readUsers
            newMessages[id] = newMessage.toDictionary()
        }
        ref.child("Rooms/\(roomId)/messages").updateChildValues(newMessages)
    }
    
    /// 채팅방 나가는 함수 (나가기 버튼 클릭) ,  room 에서 user정보 삭제
    /// - Parameter roomId: 방 id
    /// - Parameter roomInfo: 방 정보 Object
    func exitRoom(roomId: String, roomInfo: ChatingRoom, completion: @escaping (Error?, DatabaseReference) -> Void){
        var uidArrays = roomInfo.uids.toFBArray()
        uidArrays.removeAll(where: {$0 == ConnectedUser.shared.uid})
        let newUids = uidArrays
        
        var userNameArrays = roomInfo.userNames.toFBArray()
        userNameArrays.removeAll(where: {$0 == ConnectedUser.shared.user.userInfo.name})
        let newUserNames = userNameArrays
        
        ref.child("Rooms/\(roomId)").removeAllObservers() // 옵저버 해제
        
        if newUids.count == 0, newUserNames.count == 0 {
            ref.child("Rooms/\(roomId)").removeValue()
            ref.child("RoomUsers/\(roomId)/\(ConnectedUser.shared.uid)").removeValue()
            ref.child("UserRooms/\(ConnectedUser.shared.uid)/\(roomId)").removeValue()
            return
        }// 더 이상 방에 사람이 남지 않으면 방 정보 삭제
        
        var userExitMessage = [String: Any]()
        userExitMessage["content"] = "\(ConnectedUser.shared.user.userInfo.name)님이 방을 나가셨습니다."
        userExitMessage["time"] = ServerValue.timestamp()
        userExitMessage["type"] = "exit"
        
        let messageAutoId = ref.childByAutoId().key!
        ref.child("Rooms/\(roomId)/messages").updateChildValues([messageAutoId: userExitMessage])
        ref.child("Rooms/\(roomId)").updateChildValues(["uids":newUids.toFBString(), "userNames":newUserNames.toFBString()])
        ref.child("RoomUsers/\(roomId)/\(ConnectedUser.shared.uid)").removeValue()
        ref.child("UserRooms/\(ConnectedUser.shared.uid)/\(roomId)").removeValue(completionBlock: completion)
        ref.child("Users/\(ConnectedUser.shared.uid)/userInfo").removeAllObservers()
    }
    
    
    func inviteUsers(users:[(uid:String,info:UserInfo)], completion: @escaping (InviteType) -> Void) {
        guard let roomId = ConnectedUser.shared.roomId else {
            print("Current Room Id null !!!")
            return
        }
        ref.child("Rooms/\(roomId)").observeSingleEvent(of: .value) {
            snapshot in
            guard snapshot.exists() else { return }
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(ChatingRoom.self, from: data)
                var newUidArrays = result.uids.toFBArray()
                newUidArrays.append(contentsOf: users.map({$0.uid}))
                var newUserNameArrays = result.userNames.toFBArray()
                newUserNameArrays.append(contentsOf: users.map({$0.info.name}))
                
                
                let invitedUserNames = users.map({$0.info.name}).joined(separator: ",")
                
                // 1대1 채팅방 이면 방을 새로 생성
                if result.type == "1:1" {
                    let message: [String: Any] = [
                        "sender" : ConnectedUser.shared.uid,
                        "time": ServerValue.timestamp(),
                        "type": "system",
                        "content": "\(ConnectedUser.shared.user.userInfo.name)님이 \(invitedUserNames)을 초대 했습니다."
                    ]
                    self.createRoom(message: message, participantUids: newUidArrays, participantNames: newUserNameArrays, name: nil, type: "1:N") { _, _ in
                        completion(.create)
                    }
                } else {
                    self.ref.child("Rooms/\(roomId)").updateChildValues(["uids": newUidArrays.toFBString(), "userNames": newUserNameArrays.toFBString()]) {
                        _, _ in
                        let message: [String:Any] = [
                            "sender" : ConnectedUser.shared.uid,
                            "time": ServerValue.timestamp(),
                            "type": "system",
                            "content": "\(ConnectedUser.shared.user!)님이 \(invitedUserNames)을 초대 했습니다."
                        ]
                        self.sendMessage(sendMessage: message, roomId: ConnectedUser.shared.roomId!)
                        completion(.append)
                    }
                }
                
            } catch {
                print("-> Error inviteUsers: \(error.localizedDescription)")
                
            }
        }
    }
}

// MARK: - Image
extension DatabaseManager {
    func uploadImage(image: UIImage,uid: String,path: String, completion: @escaping (String) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.1) ?? image.pngData() else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        print("test")
        Storage.storage().reference().child(path).putData(data, metadata: metaData) {
            (metaData,error) in
            if let error = error {
                print("error ->", error)
                print("error -> image upload error!!!",error.localizedDescription)
            } else {
                Storage.storage().reference().child(path).downloadURL { (url, error) in
                    if let error = error {
                        print("error -> download Image Error",error)
                    } else {
                        
                    }
                    completion(url?.absoluteString ?? "")
                }
            }
        }
    }
}



// MARK: - Set,Update Data
extension DatabaseManager {
    func setValue(_ value: [String: Any], forPath path: String){
        ref.child(path).setValue(value)
    }
    
    func updateChildValues(_ value: [String: Any], forPath path: String){
        ref.child(path).updateChildValues(value)
    }
    func updateChildValues(_ value: [String: Any], forPath path: String, completion: @escaping (Error?,DatabaseReference)-> Void){
        ref.child(path).updateChildValues(value,withCompletionBlock: completion)
    }
}

// MARK: - Fetch User Data
extension DatabaseManager {
    
    func fetchUid(email: String,compltion: @escaping (String?) -> Void) {
        ref.child("Users").queryOrdered(byChild: "userInfo/email").queryEqual(toValue: email).observeSingleEvent(of: .value) { snapshot in
            let child = snapshot.value as! [String: Any]
            compltion(child.keys.first)
        }
    }
    
    func fetchUser(email : String ,completion : @escaping (User?) -> Void){
        ref.child("Users").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(User.self, from: data)
                completion(result)
            } catch {
                print("-> Error : \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func fetchUser(uid: String, completion : @escaping (User?) -> Void) {
        ref.child("Users/\(uid)").observeSingleEvent(of: .value, with: {
            snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                print(data)
                let result = try JSONDecoder().decode(User.self, from: data)
                completion(result)
            } catch {
                print("-> Error : \(error.localizedDescription)")
                completion(nil)
            }
        })
    }
    
    func fetchUserInfo(uid: String, completion : @escaping (UserInfo?) -> Void){
        ref.child("Users/\(uid)/userInfo").observeSingleEvent(of: .value, with: {
            snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(UserInfo.self, from: data)
                completion(result)
            } catch {
                print("-> Error : \(error.localizedDescription)")
                completion(nil)
            }
        })
    }
    func fetchUserInfo(email: String, completion : @escaping (UserInfo?) -> Void){
        ref.child("Users").queryOrdered(byChild: "userInfo/email").queryEqual(toValue: email).observeSingleEvent(of: .value, with: {
            snapshot in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let child = snapshot.value as! [String: Any]
            let userInfoDictionary = child[child.keys.first!] as! [String: Any]
            
            do{
                let data = try JSONSerialization.data(withJSONObject: userInfoDictionary["userInfo"]!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(UserInfo.self, from: data)
                completion(result)
                print(result)
            } catch {
                print("-> Error : \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - Register User Observer
extension DatabaseManager {
    func registerUserInfoObserver(forUid uid: String, completion: @escaping (UserInfo) -> Void){
        ref.child("Users/\(uid)/userInfo").observe(.value, with: {
            snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(UserInfo.self, from: data)
                completion(result)
                print("User Info JSONDecoder result!!! -> ",result)
            } catch {
                print("-> Error UserInfo Observer: \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - Friend

extension DatabaseManager {
    func registerAddFriendObserver(completion: @escaping (String,UserInfo) -> Void) {
        ref.child("Users/\(ConnectedUser.shared.uid)/friends").observe(.childAdded) {
            snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(UserInfo.self, from: data)
                completion(snapshot.key, result)
                print(result)
            } catch {
                print("-> Error Friend Observer: \(error.localizedDescription)")
            }
        }
    }
    func registerFriendChangeObserver(completion: @escaping (String, UserInfo) -> Void) {
        ref.child("Users/\(ConnectedUser.shared.uid)/friends").observe(.childChanged) {
            snapshot in
            do{
                let data = try JSONSerialization.data(withJSONObject: snapshot.value!, options: .prettyPrinted)
                let result = try JSONDecoder().decode(UserInfo.self, from: data)
                completion(snapshot.key, result)
                print(result)
            } catch {
                print("-> Error Friend Observer: \(error.localizedDescription)")
            }
        }
    }
    func notiProfileChangeToFriends() {
        ref.child("Users/\(ConnectedUser.shared.uid)").observeSingleEvent(of: .value)
        {
            snapshot in
            print("real Test", snapshot)
            
            
            
            let user = snapshot.value as! [String: Any]
            if user["friends"] == nil {
                return
            }
            let friends = user["friends"] as! [String: Any]
            
            for key in friends.keys {
                if key == ConnectedUser.shared.uid {
                    self.ref.child("Users/\(ConnectedUser.shared.uid)/friends/\(ConnectedUser.shared.uid)").setValue(ConnectedUser.shared.user.userInfo.toDictionary())
                    break
                }
            }
            
        }
    }
}
