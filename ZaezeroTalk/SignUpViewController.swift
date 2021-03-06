//
//  SignUpViewController.swift
//  ZaezeroTalk
//
//  Created by 재영신 on 2021/11/08.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

enum ValidType{
    case empty
    case valid
    case invalid
}

class SignUpViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    @IBOutlet weak var pwdCheckTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var nameErrorLabel: UILabel!
    @IBOutlet weak var pwdErrorLabel: UILabel!
    @IBOutlet weak var pwdCheckErrorLabel: UILabel!
    
    private var labelHeightConstraints = [UILabel : NSLayoutConstraint]()
    private let pwdMinLength = 6
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        labelHeightConstraints[emailErrorLabel] = emailErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        labelHeightConstraints[nameErrorLabel] = nameErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        labelHeightConstraints[pwdErrorLabel] = pwdErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        labelHeightConstraints[pwdCheckErrorLabel] = pwdCheckErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        
        confirmButton.layer.cornerRadius = confirmButton.bounds.height / 2
        
        emailTextField.delegate = self
        pwdTextField.delegate = self
        nameTextField.delegate = self
        pwdCheckTextField.delegate = self
        
        labelHeightConstraints[emailErrorLabel]?.isActive = true
        labelHeightConstraints[nameErrorLabel]?.isActive = true
        labelHeightConstraints[pwdErrorLabel]?.isActive = true
        labelHeightConstraints[pwdCheckErrorLabel]?.isActive = true
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true) // 외부 뷰 클릭 시 키보드 내리기
    }
    /// 확인 버튼 -> 회원가입
    /// - Parameter sender: confirm 버튼
    @IBAction func touchConfirmButton(_ sender: Any) {
        ///error label 이 하나라도 보여지고 있는 상태이면 회원가입을 진행 할 수 없으므로 return
        if isShownErrorLabel() == true {
            return
        }
        // 회원 가입
        Auth.auth().createUser(withEmail: emailTextField.text!, password: pwdTextField.text!) {
            (result,error) in
            guard let result = result , error == nil else {
                if let errorCode : AuthErrorCode = AuthErrorCode(rawValue: error!._code){
                    print("-> errorCode -> \(errorCode.rawValue)")
                    if AuthErrorCode.emailAlreadyInUse.rawValue == errorCode.rawValue{
                        self.emailErrorLabel.text = "The email address is already"
                        self.labelHeightConstraints[self.emailErrorLabel]?.isActive = false
                        UIView.animate(withDuration: 0.5) {
                            self.view.layoutIfNeeded()
                        }
                    }
                } // 회원가입 실패 !!
                return
            }
            
            
            let signUpUser = result.user
            guard let email = signUpUser.email, let name = self.nameTextField.text else { return }
            let userInfo = [ "email": email, "name": name]
            DatabaseManager.shared.setValue(userInfo, forPath: "Users/\(signUpUser.uid)/userInfo")
            let changeRequest = signUpUser.createProfileChangeRequest()
            changeRequest.displayName = self.nameTextField.text
            changeRequest.commitChanges {
                error in
                if error != nil {
                    print("user createProfileChangeRequest error !! \(String(describing: error))")
                }
            }
            self.dismiss(animated: true, completion: nil)
        }
        
    }
}

// MARK: - valid text verify func
extension SignUpViewController{
    /// 유효한 이름 입력 검증 메소드
    /// - Parameter name: nameTextField.text
    /// - Returns: enum ValidType
    func isValidName(name: String?) -> ValidType{
        guard let name = name else { return .invalid }
        
        if name.isEmpty {
            return .empty
        } else if name.count >= 3{
            return .valid
        }
        return .invalid
    }
    
    /// 유효한 이메일 입력 검증 메소드
    /// - Parameter email: emailTextField.text
    /// - Returns: enum ValidType
    func isValidEmail(email:String?) -> ValidType{
        guard let email = email else { return .invalid }
        
        if email.isEmpty {
            return .empty
        }
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let pred = NSPredicate(format: "SELF MATCHES %@", regEx)
        
        if pred.evaluate(with: email) == true{
            return .valid
        } else {
            return .invalid
        }
    }
    
    /// 유효한 비밀번호 입력 검증 메소드
    /// - Parameter password: pwdTextField.text
    /// - Returns: enum ValidType
    func isValidPassword(password:String?) -> ValidType{
        guard let password = password else { return .invalid }
        
        if password.isEmpty {
            return .empty
        } else if password.count >= 6 {
            return .valid
        }
        return .invalid
    }
    
    
    /// 비밀번호 일치 확인 메소드
    /// - Parameter checkPassword: pwdCheckTextField.text
    /// - Returns: enum ValidType
    func isMatchedPwd(with checkPassword : String?) -> ValidType{
        guard let checkPassword = checkPassword else { return .invalid }
        
        if checkPassword.isEmpty {
            return .empty
        }
        if let password = pwdTextField.text{
            if password == checkPassword {
                return .valid
            }
        }
        return .invalid
    }
    
    
    /// Error Label이 보여지고 있는지 확인하는 메소드
    /// - Returns: 보여지고 있으면 true 아니면 false
    func isShownErrorLabel() -> Bool {
        guard let emailErrorLabelConstraint = labelHeightConstraints[emailErrorLabel] ,
              let nameErrorLabelConstraint = labelHeightConstraints[nameErrorLabel] ,
              let pwdErrorLabelConstraint = labelHeightConstraints[pwdErrorLabel] ,
              let pweCheckErrorLabelConstraint = labelHeightConstraints[pwdCheckErrorLabel] else {
                  print("error!! error label height constraints nil!!")
                  return true
              }
        if emailErrorLabelConstraint.isActive == false || nameErrorLabelConstraint.isActive == false || pwdErrorLabelConstraint.isActive == false || pweCheckErrorLabelConstraint.isActive == false {
            return true
        }
        
        return false
    }
    
}

// MARK: - TextFieldDelegate
extension SignUpViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // textField의 현재상태를 포기한다 즉 올라와 있는 상태를 포기 한다.
        return true
    }
    
    /// TextField 입력이 끝났을 때 값이 유효한지 테스트
    /// - Parameter textField: 입력한 TextField
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField{
        case emailTextField:
            let isValid = isValidEmail(email: emailTextField.text)
            if isValid == .empty {
                emailErrorLabel.text = "필수 정보 입니다"
                labelHeightConstraints[emailErrorLabel]?.isActive = false
            } else if isValid == .valid {
                labelHeightConstraints[emailErrorLabel]?.isActive = true
            } else {
                emailErrorLabel.text = "Please enter a valid email Address."
                labelHeightConstraints[emailErrorLabel]?.isActive = false
            }
        case nameTextField:
            let isValid = isValidName(name: nameTextField.text)
            if isValid == .empty {
                nameErrorLabel.text = "필수 정보 입니다."
                labelHeightConstraints[nameErrorLabel]?.isActive = false
            } else if isValid == .valid {
                labelHeightConstraints[nameErrorLabel]?.isActive = true
            } else {
                nameErrorLabel.text = "Please enter valid name."
                labelHeightConstraints[nameErrorLabel]?.isActive = false
            }
        case pwdTextField:
            let isValid = isValidPassword(password: pwdTextField.text)
            if isValid == .empty {
                pwdErrorLabel.text = "필수 정보 입니다."
                labelHeightConstraints[pwdErrorLabel]?.isActive = false
            } else if isValid == .valid {
                labelHeightConstraints[pwdErrorLabel]?.isActive = true
            } else {
                pwdErrorLabel.text = "Minimum 6 Characters.."
                labelHeightConstraints[pwdErrorLabel]?.isActive = false
            }
        case pwdCheckTextField:
            let isValid = isMatchedPwd(with: pwdCheckTextField.text)
            if isValid == .empty {
                pwdCheckErrorLabel.text = "필수 정보 입니다."
                labelHeightConstraints[pwdCheckErrorLabel]?.isActive = false
            } else if isValid == .valid {
                labelHeightConstraints[pwdCheckErrorLabel]?.isActive = true
            } else {
                pwdCheckErrorLabel.text = "The passwords are not the same."
                labelHeightConstraints[pwdCheckErrorLabel]?.isActive = false
            }
        default: break
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
}
