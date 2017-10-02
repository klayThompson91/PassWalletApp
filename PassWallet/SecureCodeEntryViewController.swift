//
//  SecureCodeEntryViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/4/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit
import CryptoSwift


public protocol SecureCodeEntryViewControllerDelegate : class
{
    func secureCodeEntrySucceeded(context: SecureCodeEntryContext) -> Void
    func secureCodeEntryFailed(context: SecureCodeEntryContext) -> Void
}

/**
 * SecureCodeEntryViewController is a ViewController object that manages the collection and validation
 * of a user-defined secure code (such as a PIN or Passcode) similar to the one found in iOS -> Settings ->TouchID.
 * SecureCodeEntryViewController manages a PinEntryTextField and coordinates with iOS Keychain to make this happen.
 *
 * You can initialize SecureCodeEntryViewController in different contexts to either have it authenticate with a secure code,
 * setup a secure code, or change a previously set secure code. Depending on the context set, the UI updates appropriately and
 * SecureCodeEntryViewController handles and drives the flow for you.
 *
 * Please set the delegate and implement the SecureCodeEntryViewControllerDelegate to get notified 
 * when SecureCodeEntryViewController has finished setting, validating, or updating a secure code.
 */
public class SecureCodeEntryViewController : ClientDependencyViewController, PinEntryTextFieldDelegate, DirectedGraphStateMachineObserver
{
    /// MARK: Properties and Constants
    public weak var delegate: SecureCodeEntryViewControllerDelegate?
    public var secureCodeEntryType: SecureCodeEntryType = .passcode
    public var secureCodeEntryLength: SecureCodeEntryLength = .fourDigitCode
    
    public var context: SecureCodeEntryContext {
        get {
            return secureCodeEntryStateMachine.stateMachineContext
        }
        set(newContext) {
            if PWCredentials().hasCredentials {
                secureCodeEntryStateMachine.stateMachineContext = newContext
            } else {
                secureCodeEntryStateMachine.stateMachineContext = .setupSecureCode
            }
        }
    }
    
    private var pinEntryTextField = PinEntryTextField(frame: CGRect.zero, pinEntryLength: .fourDigitCode, color: UIColor.black)
    private var pinPromptHeaderLabelView = UILabel(frame: CGRect.zero)
    private var pinPromptFooterLabelContainerView = UIView(frame: CGRect.zero)
    private var pinPromptFooterLabelView = UILabel(frame: CGRect.zero)
    private var pwStyle = PWAppearance.sharedAppearance
    
    private var secureCodeEntryStateMachine: SecureCodeEntryManager!
    private var keychainService: KeychainServiceInterface!
    
    private struct Constants {
        struct Strings {
            static let cancelTitle = "Cancel"
        }
        struct UI {
            static let pinDigitSpacing: CGFloat = 25
            static let pinLabelVerticalSpacing: CGFloat = -30
            static let pinDigitDiameter: CGFloat = 20
        }
    }
    
    /// MARK: Initialization
    
    /// Use these initializers to get an instance of SecureCodeEntryViewController
    override public convenience init()
    {
        self.init(context: .authenticate, secureCodeEntryType: .pin, secureCodeEntryLength: .fourDigitCode, delegate: nil)
    }
    
    public init(context: SecureCodeEntryContext, secureCodeEntryType: SecureCodeEntryType?, secureCodeEntryLength: SecureCodeEntryLength?, delegate: SecureCodeEntryViewControllerDelegate?)
    {
        super.init()
        
        if let codeType = secureCodeEntryType {
            self.secureCodeEntryType = codeType
        }
        if let codeLength = secureCodeEntryLength {
            self.secureCodeEntryLength = codeLength
        }
        if let observer = delegate {
            self.delegate = observer
        }
        
        self.secureCodeEntryStateMachine = SecureCodeEntryManager(context: context, entryLimit: 4, secureCodeType: self.secureCodeEntryType)
        self.context = context
        self.secureCodeEntryStateMachine.delegate = AnyDirectedGraphStateMachineObserver<SecureCodeEntryState>(self)
        self.secureCodeEntryStateMachine.start()
    }
    
    /// Factory based initialization, use these to get an instance of SecureCodeEntryVC embedded in a NavigationController
    public class func navigationController() -> UINavigationController
    {
        return self.navigationController(context: .authenticate, secureCodeEntryType: .pin, secureCodeEntryLength: .fourDigitCode, delegate: nil)
    }
    
    public class func navigationController(context: SecureCodeEntryContext, secureCodeEntryType: SecureCodeEntryType?, secureCodeEntryLength: SecureCodeEntryLength?, delegate: SecureCodeEntryViewControllerDelegate?) -> UINavigationController
    {
        let secureCodeEntryVC = SecureCodeEntryViewController(context: context, secureCodeEntryType: secureCodeEntryType, secureCodeEntryLength: secureCodeEntryLength, delegate: delegate)
        let navigationController = UINavigationController(rootViewController: secureCodeEntryVC)
        return navigationController
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// MARK: Dependency Injection
    override public func serviceDependencies() -> [Any.Type] {
        return [KeychainServiceInterface.self]
    }
    
    override public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    /// MARK: ViewController Lifecycle + Layout
    override public func viewDidLoad()
    {
        view.backgroundColor = pwStyle.tableViewBackgroundColor
        
        //Configure navigationBar and Item if applicable
        if let navBar = navigationController?.navigationBar {
            pwStyle.styleNavigationBar(navigationBar: navBar)
            title = secureCodeEntryStateMachine.stateMachineContext.title(fromEntryType: secureCodeEntryType)
            navigationItem.hidesBackButton = true
            let cancelButton = UIBarButtonItem(title: Constants.Strings.cancelTitle, style: .plain, target: self, action: #selector(cancelButtonPressed(_:)))
            cancelButton.setTitleTextAttributes(pwStyle.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor.white), for: .normal)
            navigationItem.rightBarButtonItem = cancelButton
        }
        
        //Configure pin footerView
        pinPromptFooterLabelView.backgroundColor = UIColor.clear
        pinPromptFooterLabelView.text = ""
        pinPromptFooterLabelView.textAlignment = .center
        pinPromptFooterLabelView.textColor = UIColor.white
        pinPromptFooterLabelView.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        
        //Configure pin footer container
        pinPromptFooterLabelContainerView.backgroundColor = pwStyle.errorBackgroundColor
        pinPromptFooterLabelContainerView.layer.masksToBounds = true
        pinPromptFooterLabelContainerView.layer.cornerRadius = 12.0
        pinPromptFooterLabelContainerView.isHidden = true
        
        //Configure pin headerView
        pinPromptHeaderLabelView.backgroundColor = UIColor.clear
        pinPromptHeaderLabelView.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        pinPromptHeaderLabelView.text = secureCodeEntryStateMachine.currentState.title(withContext: secureCodeEntryStateMachine.stateMachineContext, withType: secureCodeEntryType)
        
        pinEntryTextField.delegate = self
        
        //Add and layout subviews
        pinPromptFooterLabelContainerView.addSubview(pinPromptFooterLabelView)
        view.addSubview(pinPromptHeaderLabelView)
        view.addSubview(pinEntryTextField)
        view.addSubview(pinPromptFooterLabelContainerView)
        
        setupConstraints()
        super.viewDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pinEntryTextField.becomeFirstResponder()
    }
    
    private func setupConstraints()
    {
        let constraint = PWConstraint()
        let subviews: [UIView] = [pinPromptHeaderLabelView, pinPromptFooterLabelView, pinEntryTextField, pinPromptFooterLabelContainerView]
        PWConstraint.disableAutoresize(forViews: subviews)
        
        constraint.addConstraint( pinEntryTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -((view.bounds.height / 3) / 2)))
        constraint.addConstraint( pinEntryTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraint.addConstraint( pinPromptFooterLabelView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraint.addConstraint( pinPromptFooterLabelView.topAnchor.constraint(equalTo: pinEntryTextField.bottomAnchor, constant: -Constants.UI.pinLabelVerticalSpacing))
        constraint.addConstraint( pinPromptHeaderLabelView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraint.addConstraint( pinPromptHeaderLabelView.bottomAnchor.constraint(equalTo: pinEntryTextField.topAnchor, constant: Constants.UI.pinLabelVerticalSpacing))
        
        constraint.addConstraint( pinPromptFooterLabelContainerView.bottomAnchor.constraint(equalTo: pinPromptFooterLabelView.bottomAnchor, constant: 5.0))
        constraint.addConstraint( pinPromptFooterLabelContainerView.topAnchor.constraint(equalTo: pinPromptFooterLabelView.topAnchor, constant: -5.0))
        constraint.addConstraint( pinPromptFooterLabelContainerView.rightAnchor.constraint(equalTo: pinPromptFooterLabelView.rightAnchor, constant: 10.0))
        constraint.addConstraint( pinPromptFooterLabelContainerView.leftAnchor.constraint(equalTo: pinPromptFooterLabelView.leftAnchor, constant: -10.0))
        
        NSLayoutConstraint.activate(constraint.constraints)
    }
    
    /// MARK: PinEntryTextField Delegate
    public func pinEntryTextFieldTextDidChange(_ pinEntryTextField: PinEntryTextField) { }
    
    // Pin has been collected, need to verify with state machine
    public func pinEntryTextFieldShouldEndEditing(_ pinEntryTextField: PinEntryTextField) -> Bool
    {
        UIApplication.shared.beginIgnoringInteractionEvents()
        secureCodeEntryStateMachine.submitSecureCode(secureCode: pinEntryTextField.text)
        return false
    }
    
    public func pinEntryTextFieldShouldClearTextField(_ pinEntryTextField: PinEntryTextField) -> Bool {return false}
    
    /// MARK: Target Action Responding
    @objc private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        secureCodeEntryStateMachine.secureCodeEntryCancelled()
    }

    /// MARK: State Machine Delegate (Observer)
    public func transitionedToState(state: SecureCodeEntryState) {
        let headerMessage = state.title(withContext: secureCodeEntryStateMachine.stateMachineContext, withType: secureCodeEntryType)
        let footerMessage = state.supplementaryTitle(type: secureCodeEntryType, count: ((state == .enterSecureCode) ? secureCodeEntryStateMachine.enterSecureCodeCount : secureCodeEntryStateMachine.setSecureCodeCount))
        let backgroundColor = ((state == .enterSecureCode) ? pwStyle.errorBackgroundColor : UIColor.clear)
        let footerTextColor = ((state == .enterSecureCode) ? UIColor.white : UIColor.black)
        
        if state == .secureCodeVerified || state == .secureCodeRejected {
            UIApplication.shared.endIgnoringInteractionEvents()
            pinPromptFooterLabelContainerView.isHidden = true
            pinEntryTextField.resignFirstResponder()
            (state == .secureCodeVerified) ? delegate?.secureCodeEntrySucceeded(context: secureCodeEntryStateMachine.stateMachineContext) : delegate?.secureCodeEntryFailed(context: secureCodeEntryStateMachine.stateMachineContext)
        } else {
            asyncUpdatePinEntryFields(headerText: headerMessage, footerText: footerMessage, footerContainerColor: backgroundColor, footerTextColor: footerTextColor)
        }
    }
    
    public func transitioningFromState(state: SecureCodeEntryState) { return }
    
    /// MARK: Private Helpers
    private func asyncUpdatePinEntryFields(headerText: String, footerText: String?, footerContainerColor: UIColor, footerTextColor: UIColor)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.pinPromptHeaderLabelView.text = headerText
            if let footer = footerText {
                self.pinPromptFooterLabelView.text = footer
                self.pinPromptFooterLabelView.textColor = footerTextColor
                self.pinPromptFooterLabelContainerView.backgroundColor = footerContainerColor
                self.pinPromptFooterLabelContainerView.isHidden = false
            } else {
                self.pinPromptFooterLabelContainerView.isHidden = true
            }
            
            self.pinEntryTextField.clear()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }

}
