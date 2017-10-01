//
//  EditablePasswordCardViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit
import Whisper

public protocol PasswordEditViewControllerDelegate: class {
    func passwordEditViewControllerUpdatedPasswords()
}

public class PasswordEditViewController : ClientDependencyViewController, EditablePasswordCardViewDelegate {
    
    public weak var delegate: PasswordEditViewControllerDelegate?
    
    public override var isEditing: Bool {
        didSet {
            configureNavigationBar()
            editablePasswordCardView.isEditable = isEditing
            secureNoteCardView.isEditable = isEditing
            if isEditing == true {
                fadeOutSupplementaryButtonsIfApplicable()
            } else {
                editablePasswordCardView.securePasswordFieldIfApplicable(true)
            }
        }
    }
    
    private var containerScrollView = UIScrollView(frame: .zero)
    private var contentView = UIView(frame: .zero)
    private var editablePasswordCardView = EditablePasswordCardView(frame: .zero)
    private var secureNoteCardView = EditablePasswordCardView(frame: .zero)
    
    private var password: PasswordKeychainItem?
    private var secureNote: SecureNote = SecureNote.emptyNote()
    private var editValues = EditFieldValueGenerator(nil, secureNote: SecureNote.emptyNote())
    private var keychain: KeychainServiceInterface!
    
    private struct Constants {
        static let secureNoteImage = UIImage(named: "SecureNote Icon")
        static let genericPasswordImage = UIImage(named: "GenericPassword Icon")
        static let internetPasswordImage = UIImage(named: "InternetPassword Icon")
    }
    
    private enum FieldValueType {
        case actual
        case placeholder
    }
    
    private enum FieldSectionSupplementaryButtonType {
        case copyButton
        case revealButton
        case hideButton
    }
    
    public init(keychainItem: PasswordKeychainItem?, secureNote: SecureNote) {
        super.init()
        self.password = keychainItem
        self.secureNote = secureNote
        self.editValues = EditFieldValueGenerator(keychainItem, secureNote: secureNote)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        configureNavigationBar()
        containerScrollView.backgroundColor = PWAppearance.sharedAppearance.tableViewBackgroundColor
        if self.password != nil {
            configureEditablePasswordCardView()
        }
        configureSecureNoteCardView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func serviceDependencies() -> [Any.Type] {
        return [KeychainServiceInterface.self]
    }
    
    override public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is KeychainServiceInterface {
                keychain = dependency as? KeychainServiceInterface
            }
        }
    }
    
    override public func viewDidLoad() {
        if password != nil {
            contentView.addSubview(editablePasswordCardView)
        }
        contentView.addSubview(secureNoteCardView)
        containerScrollView.addSubview(contentView)
        view.addSubview(containerScrollView)
        setupConstraints()
    }
    
    private func configureEditablePasswordCardView() {
        if let unwrappedPassword = password {
            editablePasswordCardView.delegate = self
            editablePasswordCardView.iconImageView.image = fetchImage(for: unwrappedPassword)
            if let numberOfFieldSections = editablePasswordCardView.fieldSections?.count {
                for i in 0..<numberOfFieldSections {
                    let currentFieldValue = editValues.fieldValues[i]
                    
                    if currentFieldValue.valueType == .actual {
                        editablePasswordCardView.fieldSections?[i].textField.text = currentFieldValue.value
                    } else {
                        editablePasswordCardView.fieldSections?[i].textField.placeholder = currentFieldValue.value
                    }
                    
                    if let _ = unwrappedPassword as? InternetPasswordKeychainItem {
                        editablePasswordCardView.fieldSections?[i].supplementaryButton.setTitle("copy", for: .normal)
                    } else {
                        if i == 2 {
                            editablePasswordCardView.fieldSections?[i].supplementaryButton.setTitle("copy", for: .normal)
                        }
                    }
                    
                    editablePasswordCardView.fieldSections?[i].titleLabel.text = editValues.labelValues[i]
                }
            }
        }
    }
    
    private func configureSecureNoteCardView() {
        let attributes = EditablePasswordCardViewAttributes()
        attributes.containsMultiLineSection = true
        if password != nil {
            attributes.numberOfFieldSections = 0
            secureNoteCardView = EditablePasswordCardView(frame: .zero, attributes: attributes)
        } else {
            attributes.numberOfFieldSections = 1
            secureNoteCardView = EditablePasswordCardView(frame: .zero, attributes: attributes)
            let currentFieldValue = editValues.fieldValues[0]
            if currentFieldValue.valueType == .actual {
                secureNoteCardView.fieldSections?[0].textField.text = currentFieldValue.value
            } else {
                secureNoteCardView.fieldSections?[0].textField.placeholder = currentFieldValue.value
            }
            secureNoteCardView.fieldSections?[0].titleLabel.text = editValues.labelValues[0]
        }
        
        secureNoteCardView.iconImageView.image = Constants.secureNoteImage
        secureNoteCardView.multiLineSection?.titleLabel.text = editValues.labelValues.last
        
        let currentFieldValue = editValues.fieldValues.last
        if currentFieldValue?.valueType == .actual {
            secureNoteCardView.multiLineSection?.textView.text = currentFieldValue?.value
        } else {
            secureNoteCardView.multiLineSection?.textView.text = currentFieldValue?.value
            secureNoteCardView.multiLineSection?.textView.textColor = UIColor.lightGray
        }
    }
    
    private func fetchImage(for keychainItem: KeychainItem) -> UIImage? {
        if let _ = keychainItem as? InternetPasswordKeychainItem {
            return Constants.internetPasswordImage
        } else if let _ = keychainItem as? PasswordKeychainItem {
            return Constants.genericPasswordImage
        }
        
        return nil
    }
    
    private func setupConstraints() {
        
        var constraints = [NSLayoutConstraint]()
        PWConstraint.disableAutoresize(forViews: [containerScrollView, contentView, editablePasswordCardView, secureNoteCardView])
        
        constraints.append(containerScrollView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(containerScrollView.leftAnchor.constraint(equalTo: view.leftAnchor))
        constraints.append(containerScrollView.rightAnchor.constraint(equalTo: view.rightAnchor))
        constraints.append(containerScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        constraints.append(contentView.topAnchor.constraint(equalTo: containerScrollView.topAnchor))
        constraints.append(contentView.leftAnchor.constraint(equalTo: containerScrollView.leftAnchor))
        constraints.append(contentView.rightAnchor.constraint(equalTo: containerScrollView.rightAnchor))
        constraints.append(contentView.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor))
        constraints.append(contentView.widthAnchor.constraint(equalTo: view.widthAnchor))
        
        if password != nil {
            constraints += constraintsByPinningToContentView(editablePasswordCardView, shouldPinBottom: false)
            constraints.append(secureNoteCardView.topAnchor.constraint(equalTo: editablePasswordCardView.bottomAnchor, constant: 20))
            constraints.append(secureNoteCardView.leftAnchor.constraint(equalTo: editablePasswordCardView.leftAnchor))
            constraints.append(secureNoteCardView.rightAnchor.constraint(equalTo: editablePasswordCardView.rightAnchor))
            constraints.append(secureNoteCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50))
        } else {
            constraints += constraintsByPinningToContentView(secureNoteCardView, shouldPinBottom: true)
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func constraintsByPinningToContentView(_ cardView: EditablePasswordCardView, shouldPinBottom: Bool) -> [NSLayoutConstraint]
    {
        var constraints = [cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25),
                           cardView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
                           cardView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)]
        
        if shouldPinBottom { constraints.append(cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)) }
        return constraints
    }
    
    @objc private func keyboardDidShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            updateScrollViewContentInset(with: contentInsets)
        }
    }
    
    @objc private func editButtonPressed(_ sender: UIBarButtonItem) {
        isEditing = true
    }
    
    @objc private func deleteButtonPressed(_ sender: UIBarButtonItem) {
        guard let passwordToDelete = password else {
            return
        }
        var error: NSError? = NSError()
        let keychainItemStore = KeychainItemStore.sharedStore
        var keychainItems = keychainItemStore.items
        keychainItems = keychainItems?.filter { !($0.isEqual(passwordToDelete)) }
        if let unwrappedKeychainItems = keychainItems {
            let _ = keychainItemStore.save(unwrappedKeychainItems)
        }
        let _ = keychain.delete(passwordKeychainItem: passwordToDelete, error: &error)
        delegate?.passwordEditViewControllerUpdatedPasswords()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveButtonPressed(_ sender: UIBarButtonItem) {
        let keychainStore = KeychainItemStore.sharedStore
        var keychainItems = keychainStore.items
        if keychainItems == nil {
            keychainItems = [KeychainItem]()
        }
        var error: NSError? = NSError()
        if let newPassword = keychainItemAfterEdits(), let currentPassword = password {
            if newPassword.isEqual(currentPassword) {
                let _ = keychain.update(passwordKeychainItem: newPassword, error: &error)
            } else {
                if keychain.contains(passwordKeychainItem: newPassword) {
                    let _ = keychain.update(passwordKeychainItem: newPassword, error: &error)
                } else {
                    let _ = keychain.add(passwordKeychainItem: newPassword, error: &error)
                    keychainItems?.append(newPassword)
                }
                let _ = keychain.delete(passwordKeychainItem: currentPassword, error: &error)
                
                keychainItems = keychainItems?.filter { !($0.isEqual(currentPassword)) }
                if let unwrappedKeychainItems = keychainItems {
                    let _ = keychainStore.save(unwrappedKeychainItems)
                    delegate?.passwordEditViewControllerUpdatedPasswords()
                }
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        updateScrollViewContentInset(with: UIEdgeInsets.zero)
    }
    
    private func keychainItemAfterEdits() -> PasswordKeychainItem? {
        if let unwrappedPassword = password {
            if let _ = unwrappedPassword as? InternetPasswordKeychainItem, let fields = editablePasswordCardView.fieldSections {
                return InternetPasswordKeychainItem(password: fields[2].textField.text ?? "", accountName: fields[1].textField.text ?? "", website: URL(string: fields[0].textField.text ?? "")!)
            } else {
                if let fields = editablePasswordCardView.fieldSections {
                    return PasswordKeychainItem(password: fields[2].textField.text ?? "", identifier: fields[0].textField.text ?? "", description: fields[1].textField.text ?? "")
                }
            }
        }
        
        return nil
    }
    
    private func fadeOutSupplementaryButtonsIfApplicable() {
        if isEditing, let sections = editablePasswordCardView.fieldSections {
            for i in 0..<sections.count {
                let fieldSection = sections[i]
                UIView.animate(withDuration: 0.25, animations: {
                    fieldSection.supplementaryButton.alpha = 0.0
                }, completion: { (finishedAnimating) in
                    if finishedAnimating {
                        fieldSection.hideSupplementaryButton = true
                        self.editablePasswordCardView.securePasswordFieldIfApplicable(false)
                    }
                })
            }
        }
    }
    
    private func configureNavigationBar() {
        if let navBar = navigationController?.navigationBar {
            PWAppearance.sharedAppearance.styleNavigationBar(navigationBar: navBar)
            let fadeTextAnimation = CATransition()
            fadeTextAnimation.duration = 0.25
            fadeTextAnimation.type = kCATransitionFade
            navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
            if isEditing == false {
                if let internetPassword = password as? InternetPasswordKeychainItem {
                    title = internetPassword.website.hostWithoutSubDomain?.capitalizingFirstLetter() ?? ""
                } else {
                    if editValues.fieldValues[0].valueType == .actual {
                        title = editValues.fieldValues[0].value
                    }
                }
                
                let editButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonPressed(_:)))
                editButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor.white), for: .normal)
                navigationItem.rightBarButtonItem = editButtonItem
            } else {
                title = "Edit"
                
                let deleteButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
                deleteButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor.white), for: .normal)
                deleteButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor(white: 1.0, alpha: 0.5)), for: .disabled)
                
                let saveButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonPressed(_:)))
                saveButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor.white), for: .normal)
                saveButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular), fontColor: UIColor(white: 1.0, alpha: 0.5)), for: .disabled)
                
                navigationItem.rightBarButtonItems = [saveButtonItem, deleteButtonItem]
                
                guard let viewControllers = navigationController?.viewControllers else {
                    return
                }
                
                let backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
                viewControllers[viewControllers.count - 2].navigationItem.backBarButtonItem = backBarButtonItem
            }
        }
    }
    
    private func updateScrollViewContentInset(with insets: UIEdgeInsets) {
        containerScrollView.contentInset = insets
        containerScrollView.scrollIndicatorInsets = insets
    }
    
    public func supplementaryButtonWasTapped(_ supplementaryButton: UIButton, for fieldSectionIndex: Int) {
        UIPasteboard.general.string = editablePasswordCardView.fieldSections?[fieldSectionIndex].textField.text
        ClipboardWhisper.showCopiedMessage(for: self.navigationController!)
    }
    
    public func fieldSectionTextFieldsTextDidChange(_ textFields: [UITextField]) {
        var enableSave = true
        if let _ = password as? InternetPasswordKeychainItem {
            enableSave = ((textFields[0].text != "") && (textFields[1].text != "") && (textFields[2].text != ""))
        } else if let _ = password {
            enableSave = ((textFields[0].text != "") && (textFields[2].text != ""))
        } else {
            enableSave = (textFields[0].text != "")
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = enableSave
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
}

