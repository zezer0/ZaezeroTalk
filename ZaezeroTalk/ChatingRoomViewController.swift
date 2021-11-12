//
//  ChatingRoomViewController.swift
//  ZaezeroTalk
//
//  Created by 재영신 on 2021/11/12.
//

import UIKit

class ChatingRoomViewController: UIViewController {
    @IBOutlet weak var customNavigationItem: UINavigationItem! {
        didSet {
            // 채팅방 이름 설정
        }
    }
    @IBOutlet weak var inputTextView: UITextView! {
        didSet {
            inputTextView.delegate = self
        }
    }
    @IBOutlet weak var chatingTableView: UITableView! {
        didSet {
            chatingTableView.delegate = self
            chatingTableView.dataSource = self
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func clickBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView DataSource
extension ChatingRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

// MARK: - TableView Delegate
extension ChatingRoomViewController: UITableViewDelegate {
    
}

// MARK: - TextView Delegate
extension ChatingRoomViewController: UITextViewDelegate {
    
}
