//
//  LoginViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/4/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

// Adhere to this delegate protocol to get updated when LoginViewController successfully authenticates the user.
public protocol LoginViewControllerDelegate: class
{
    /** 
      * Auth succeeded. The return bool value lets LoginVC know that you logged in the user.
      * Returning false for whatever reason forces loginVC to kick off another auth session.
      */
    func loginViewControllerAuthenticatedUser() -> Bool
}

/** 
 * PassWallet's LoginViewController. Works in conjunction with AuthenticationSessionManager
 * and SecureCodeEntryViewController to collect and verify a user's authentication credentials
 * in order to log them in to the PassWallet application.
 */
public class LoginViewController : ClientDependencyViewController, SecureCodeEntryViewControllerDelegate, DirectedGraphStateMachineObserver
{
    
    /// MARK: Properties and Constants
    public weak var delegate: LoginViewControllerDelegate?
    private var keyIconImageView = UIImageView(frame: CGRect.zero)
    private var walletIconImageView = UIImageView(frame: CGRect.zero)
    private var headerLabel = UILabel(frame: CGRect.zero)
    private var authStatusMessageLabel = UILabel(frame: CGRect.zero)
    private var logInButton = UIButton(type: .custom)
    
    private var authenticationManager = AuthenticationSessionManager()
    private var keychainService: KeychainServiceInterface!
    private var pwStyle = PWAppearance.sharedAppearance
    private var presentingPinEntry = false
    
    private struct Constants {
        struct Strings {
            static let appName = "PassWallet"
            static let walletIcon = "\(Constants.Strings.appName) Icon"
            static let keyIcon = "KeyIcon"
            
            static let logIn = "Log In"
            static let logInMessage = "Securely store all your passwords on one device"
            static let authenticatingMessage = "Authenticating.."
        }
        struct UI {
            static let animationDuration = 0.25
            static let headerFontSize: CGFloat = 36.0
        }
    }
    
    /// MARK: View Configuration, Lifecycle, and Layout
    override public func viewDidLoad()
    {
        view.backgroundColor = pwStyle.appThemeColor
        keyIconImageView.image = UIImage(named: Constants.Strings.keyIcon)
        walletIconImageView.image = UIImage(named: Constants.Strings.walletIcon)
        headerLabel.attributedText = attributedTextForHeader()
        headerLabel.textAlignment = .center
        
        authStatusMessageLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightRegular)
        authStatusMessageLabel.textColor = pwStyle.appThemeTextFontColor
        authStatusMessageLabel.textAlignment = .center
        authStatusMessageLabel.numberOfLines = 0
        authStatusMessageLabel.lineBreakMode = .byWordWrapping
        
        logInButton.layer.borderWidth = 0
        logInButton.backgroundColor = UIColor.clear
        logInButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightRegular)
        logInButton.setTitle(Constants.Strings.logIn, for: .normal)
        logInButton.setTitle(Constants.Strings.logIn, for: .disabled)
        logInButton.setTitleColor(pwStyle.appThemeTextFontColor, for: .normal)
        logInButton.setTitleColor(pwStyle.appThemeTextFontColor, for: .disabled)
        logInButton.addTarget(self, action: #selector(loginButtonPressed(_:)), for: .touchUpInside)
        logInButton.alpha = 0.0
        
        view.addSubviews([keyIconImageView, walletIconImageView, headerLabel, authStatusMessageLabel, logInButton])
        setupConstraints()
        
        //start authentication session
        authenticationManager.delegate = AnyDirectedGraphStateMachineObserver<AuthenticationState>(self)
        loginButtonPressed(logInButton)
        super.viewDidLoad()
    }
    
    private func setupConstraints()
    {
        let constraintBuilder = PWConstraint()
        PWConstraint.disableAutoresize(forViews: [keyIconImageView, walletIconImageView, headerLabel, authStatusMessageLabel, logInButton])
        constraintBuilder.addConstraint( walletIconImageView.leftAnchor.constraint(equalTo: view.centerXAnchor))
        constraintBuilder.addConstraint( walletIconImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 55))
        constraintBuilder.addConstraint( keyIconImageView.rightAnchor.constraint(equalTo: walletIconImageView.leftAnchor))
        constraintBuilder.addConstraint( keyIconImageView.topAnchor.constraint(equalTo: walletIconImageView.topAnchor))
        constraintBuilder.addConstraint( headerLabel.topAnchor.constraint(equalTo: walletIconImageView.bottomAnchor))
        constraintBuilder.addConstraint( headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraintBuilder.addConstraint( authStatusMessageLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 35))
        constraintBuilder.addConstraint( authStatusMessageLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -35))
        constraintBuilder.addConstraint( authStatusMessageLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 130))
        constraintBuilder.addConstraint( logInButton.topAnchor.constraint(lessThanOrEqualTo: authStatusMessageLabel.bottomAnchor, constant: 170))
        constraintBuilder.addConstraint( logInButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -35))
        constraintBuilder.addConstraint( logInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        NSLayoutConstraint.activate(constraintBuilder.constraints)
    }
    
    /// MARK: Dependency Injection
    override public func serviceDependencies() -> [Any.Type]
    {
        return [KeychainServiceInterface.self]
    }
    
     override public func injectDependencies(dependencies: [InjectableService])
    {
        for dependency in dependencies {
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    /// MARK: SecureCodeEntryViewControllerDelegate
    public func secureCodeEntryFailed(context: SecureCodeEntryContext) {
        authenticationManager.pinRejected()
    }
    
    public func secureCodeEntrySucceeded(context: SecureCodeEntryContext) {
        authenticationManager.pinVerified()
    }
    
    /// MARK: AnyDirectedGraphMachineObserver
    public func transitioningFromState(state: AuthenticationState) {
        return
    }
    
    public func transitionedToState(state: AuthenticationState) {
        switch state {
        case .authenticating:
            return
        case .authenticated:
            if presentingPinEntry {
                dismissPinEntry(withCompletion: {
                    self.notifyDelegateOfAuthSuccess()
                })
            } else {
                notifyDelegateOfAuthSuccess()
            }
            return
        case .authenticationFailed:
            if presentingPinEntry {
                dismissPinEntry(withCompletion: {
                    self.animateAndUpdateAuthStatusMessageLabel(statusMessage: Constants.Strings.logInMessage, completion: { (finishedAnimating) in
                        if finishedAnimating {
                            self.fadeInLoginButton(completion: nil)
                        }
                    })
                })
            } else {
                animateAndUpdateAuthStatusMessageLabel(statusMessage: Constants.Strings.logInMessage, completion: { (finishedAnimating) in
                    if finishedAnimating {
                        self.fadeInLoginButton(completion: nil)
                    }
                })
            }
            return
        case .verifyingUserPin:
            presentingPinEntry = true
            present(SecureCodeEntryViewController.navigationController(context: .authenticate, secureCodeEntryType: .pin, secureCodeEntryLength: .fourDigitCode, delegate: self), animated: true, completion: nil)
            return
        default:
            return
        }
    }
    
    /// MARK: Target-Action Responding
    @objc private func loginButtonPressed(_ sender: UIButton) {
        fadeOutLogInButton { (finishedAnimating) in
            if finishedAnimating {
                self.animateAndUpdateAuthStatusMessageLabel(statusMessage: Constants.Strings.authenticatingMessage, completion: { (finishedAnimating) in
                    if finishedAnimating {
                        self.authenticationManager.start()
                    }
                })
            }
        }
    }
    
    /// MARK: Private Helpers
    private func fadeInLoginButton(completion: ((Bool) -> Void)?)
    {
        UIView.animate(withDuration: Constants.UI.animationDuration, animations: {
            self.logInButton.alpha = 1.0
        }, completion: completion)
    }
    
    private func fadeOutLogInButton(completion: ((Bool) -> Void)?)
    {
        UIView.animate(withDuration: Constants.UI.animationDuration, animations: {
            self.logInButton.alpha = 0.0
        }, completion: completion)
    }
    
    private func animateAndUpdateAuthStatusMessageLabel(statusMessage: String, completion: ((Bool) -> Void)?)
    {
        UIView.transition(with: authStatusMessageLabel, duration: Constants.UI.animationDuration, options: [.transitionCrossDissolve], animations: {
            self.authStatusMessageLabel.text = statusMessage
        }, completion: completion)
    }
    
    private func dismissPinEntry(withCompletion: (() -> Void)?)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.dismiss(animated: true, completion: withCompletion)
            self.presentingPinEntry = false
        }
    }
    

    private func notifyDelegateOfAuthSuccess()
    {
        guard let loggedInUser = delegate?.loginViewControllerAuthenticatedUser() else {
            return
        }
        
        if loggedInUser {
            restoreInitialState()
        }
    }
    
    private func restoreInitialState()
    {
        logInButton.alpha = 1.0
        authStatusMessageLabel.text = Constants.Strings.logInMessage
    }
    
    private func attributedTextForHeader() -> NSAttributedString
    {
        let semiBoldSystemFont = UIFont.systemFont(ofSize: Constants.UI.headerFontSize, weight: UIFontWeightSemibold)
        let semiBoldItalicSystemFont = UIFont.systemFont(ofSize: Constants.UI.headerFontSize, weight: UIFontWeightSemibold).withTraits(traits: .traitItalic)
        let passAttributes = [NSForegroundColorAttributeName : pwStyle.appThemeTextFontColor, NSFontAttributeName : semiBoldSystemFont]
        let walletAttributes = [NSForegroundColorAttributeName : pwStyle.appThemeTextFontColor, NSFontAttributeName : semiBoldItalicSystemFont]
        
        let attributedBuffer = NSMutableAttributedString(string: Constants.Strings.appName)
        attributedBuffer.setAttributes(passAttributes, range: NSMakeRange(0, 4))
        attributedBuffer.setAttributes(walletAttributes, range: NSMakeRange(4, 6))
        return attributedBuffer
    }
    
}
