//
//  FriendViewController.swift
//  ZaezeroTalk
//
//  Created by 재영신 on 2021/11/09.
//

import UIKit
import Firebase

class FriendListViewController: UIViewController {
    
    var friends = [(uid: String,info: UserInfo)]()
    
    @IBOutlet weak var customNavigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem! {
        didSet {
            customNavigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        }
    }
    @IBOutlet weak var friendListTableView: UITableView! {
        didSet {
            friendListTableView.register(UINib(nibName: "ProfileCell", bundle: nil), forCellReuseIdentifier: "ProfileCell")
            friendListTableView.dataSource = self
            friendListTableView.delegate = self
        }
    }

    /// Navigation 좌측 Title Label
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "친구"
        label.font = .systemFont(ofSize: 25, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 친구 정보 변경 Observer 등록
        DatabaseManager.shared.registerFriendChangeObserver(completion: {
            friendId, friendInfo in
            ConnectedUser.shared.user.friends![friendId] = friendInfo
            var row: Int?
            for index in self.friends.indices {
                if self.friends[index].uid == friendId {
                    self.friends[index].uid = friendId
                    self.friends[index].info = friendInfo
                    row = index
                    break
                }
            }
            guard let row = row else { return }
            self.friendListTableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .automatic)
        })
        
        /// 초기 친구 목록 가져오고 친구가 새로 추가 될떄마다 정보를 가져오는 Observer등록
        DatabaseManager.shared.registerAddFriendObserver {
            friendId, friendInfo in
            if ConnectedUser.shared.user.friends != nil {
                ConnectedUser.shared.user.friends![friendId] = friendInfo
            } else {
                ConnectedUser.shared.user.friends = [friendId: friendInfo]
            }
            if let profileImageUrl = friendInfo.profileImageUrl, !profileImageUrl.isEmpty {
                
            }
            self.friends.append((uid: friendId, info: friendInfo))
            self.friendListTableView.insertRows(at: [IndexPath(row: self.friends.count - 1, section: 1)], with: .bottom)
            self.friendListTableView.headerView(forSection: 1)!.textLabel!.text = "친구 " + String(self.friends.count)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.friendListTableView.reloadData()
    }
    
    
    /// 친구 추가 화면 이동  버튼 클릭 이벤트
    /// - Parameter sender: 친구 추가 화면 이동 버튼
    @IBAction func clickAddFriendButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "AddFriendViewController", bundle: nil)
        let addFriendVC = storyboard.instantiateViewController(withIdentifier: "AddFriendViewController") as! AddFriendViewController
        addFriendVC.modalPresentationStyle = .fullScreen
        present(addFriendVC, animated: true, completion: nil)
    }
    
    
    /// 친구 검색 이동 버튼 클릭 이벤트
    /// - Parameter sender: 친구 검색 이동 버튼
    @IBAction func clickSearchButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SearchViewController", bundle: nil)
        let searchVC = storyboard.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        searchVC.modalPresentationStyle = .fullScreen
        searchVC.modalTransitionStyle = .crossDissolve
        present(searchVC, animated: true, completion: nil)
    }
    
}



// MARK: - TableView Datasoruce
extension FriendListViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "나의 프로필"
        } else {
            return "친구 " + String(friends.count)
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return friends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
        
        // 자신의 프로필
        if indexPath.section == 0 {
            cell.nameLabel.text = ConnectedUser.shared.user.userInfo.name
            cell.stateMessageLabel.text = ConnectedUser.shared.user.userInfo.stateMessage ?? ""

            if let profileImageUrl = ConnectedUser.shared.user.userInfo.profileImageUrl {
                cell.profileImageView.setImageUrl(profileImageUrl)
            } else {
                cell.profileImageView.image = UIImage(systemName: "person.crop.rectangle.fill")
            }
        //친구의 프로필
        } else {
            cell.nameLabel.text = friends[indexPath.row].info.name
            cell.stateMessageLabel.text = friends[indexPath.row].info.stateMessage ?? ""

            if let profileImageUrl = friends[indexPath.row].info.profileImageUrl {
                cell.profileImageView.setImageUrl(profileImageUrl)
            } else {
                cell.profileImageView.image = UIImage(systemName: "person.crop.rectangle.fill")
            }
        }
        
        return cell
    }
}

// MARK: - TableView Delegate
extension FriendListViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "ProfileViewController", bundle: nil)
        let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        if indexPath.section == 0 {
            profileVC.selectedUserUid = ConnectedUser.shared.uid
            profileVC.selectedUserInfo = ConnectedUser.shared.user.userInfo
        } else {
            profileVC.selectedUserUid = friends[indexPath.row].uid
            profileVC.selectedUserInfo = friends[indexPath.row].info
        }
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true, completion: nil)
    } // 친구 목록에서 친구 선택시 프로필 화면 present
}

//extension FriendListViewController{
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y > 0 {
//            customNavigationBar.standardAppearance.shadowColor = .gray
//        }else{
//            customNavigationBar.standardAppearance.shadowColor = .white
//        }
//    }
//}

