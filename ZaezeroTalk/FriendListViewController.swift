//
//  FriendViewController.swift
//  ZaezeroTalk
//
//  Created by 재영신 on 2021/11/09.
//

import UIKit
import Firebase
class FriendListViewController: UIViewController {
    
    
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
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "친구"
        label.font = .systemFont(ofSize: 25, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        friendListTableView.reloadData()
    }
    @IBAction func clickAddFriendButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "AddFriendViewController", bundle: nil)
        let addFriendVC = storyboard.instantiateViewController(withIdentifier: "AddFriendViewController") as! AddFriendViewController
        addFriendVC.modalPresentationStyle = .fullScreen
        present(addFriendVC, animated: true, completion: nil)
    }
}



// MARK: - TableView Datasoruce , Delegate
extension FriendListViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "나의 프로필"
        } else {
            return "친구 " + String(ConnectedUser.shared.friendCount)
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return ConnectedUser.shared.friendCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
        if indexPath.section == 0 {
            cell.nameLabel.text = ConnectedUser.shared.Info?.name
        } else {
            cell.nameLabel.text = ConnectedUser.shared.friends[indexPath.row].name
        }
        
        return cell
    }
    
    
}
extension FriendListViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "ProfileViewController", bundle: nil)
        let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
        
        present(profileVC, animated: true, completion: nil)
    }
}

extension FriendListViewController{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 {
            customNavigationBar.standardAppearance.shadowColor = .gray
        }else{
            customNavigationBar.standardAppearance.shadowColor = .white
        }
    }
}

