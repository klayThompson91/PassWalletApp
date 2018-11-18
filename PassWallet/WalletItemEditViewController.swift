//
//  WalletItemEditViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit
import Whisper

public class WalletItemEditViewController : ClientDependencyViewController, EditablePasswordCardViewDelegate {
    
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
            becomeFirstResponderIfApplicable()
        }
    }
    
    private var containerScrollView = UIScrollView(frame: .zero)
    private var contentView = UIView(frame: .zero)
    private var editablePasswordCardView = EditablePasswordCardView(frame: .zero)
    private var secureNoteCardView = EditablePasswordCardView(frame: .zero)
    private var selectedIndexPath: IndexPath?
    
    private var currentWalletItem: WalletItem
    private var editValues = EditFieldValueGenerator(nil, secureNote: SecureNote.emptyNote())
    private var keychain: KeychainServiceInterface!
    
    private var passwordCardViewTapGestureRecognizer = UITapGestureRecognizer()
    private var secureNoteCardViewTapGestureRecognizer = UITapGestureRecognizer()
    
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
    
    public init(walletItem: WalletItem, selectedIndexPath: IndexPath?) {
        self.currentWalletItem = walletItem
        self.selectedIndexPath = selectedIndexPath
        super.init()
        self.editValues = EditFieldValueGenerator(currentWalletItem.keychainItem, secureNote: currentWalletItem.secureNote ?? SecureNote.emptyNote())
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        containerScrollView.backgroundColor = PWAppearance.sharedAppearance.tableViewBackgroundColor
        if self.currentWalletItem.itemType != .secureNotes {
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
        if currentWalletItem.itemType != .secureNotes {
            contentView.addSubview(editablePasswordCardView)
        }
        contentView.addSubview(secureNoteCardView)
        containerScrollView.addSubview(contentView)
        view.addSubview(containerScrollView)
        setupConstraints()
        super.viewDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        becomeFirstResponderIfApplicable()
        super.viewDidAppear(animated)
    }
    
    private func configureEditablePasswordCardView() {
        if let unwrappedPassword = currentWalletItem.keychainItem {
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
            
            passwordCardViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(editablePasswordCardViewTapped(_:)))
            editablePasswordCardView.addGestureRecognizer(passwordCardViewTapGestureRecognizer)
        }
    }
    
    private func configureSecureNoteCardView() {
        let attributes = EditablePasswordCardViewAttributes()
        attributes.containsMultiLineSection = true
        if currentWalletItem.itemType != .secureNotes {
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
        
        if currentWalletItem.itemType == .secureNotes { secureNoteCardView.delegate = self }
        
        secureNoteCardViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(secureNoteCardViewTapped(_:)))
        secureNoteCardView.addGestureRecognizer(secureNoteCardViewTapGestureRecognizer)
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
        
        if currentWalletItem.itemType != .secureNotes {
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
        var error: NSError? = NSError()
        var walletItems = WalletItemStore.shared.items
        walletItems = walletItems?.filter { !($0.isEqual(currentWalletItem)) }
        if let unwrappedWalletItems = walletItems {
            let _ = WalletItemStore.shared.save(unwrappedWalletItems)
        }
        
        if currentWalletItem.itemType != .secureNotes, let passwordToDelete = currentWalletItem.keychainItem as? PasswordKeychainItem {
            let _ = keychain.delete(passwordKeychainItem: passwordToDelete, error: &error)
        }
        NotificationCenter.default.post(Notification(name: Notification.Name.init("walletItemsChangedNotification")))
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editablePasswordCardViewTapped(_ sender: UITapGestureRecognizer) {
        guard let isFirstFieldSectionFirstResponder = editablePasswordCardView.fieldSections?[0].textField.isFirstResponder else { return }
        if !isFirstFieldSectionFirstResponder {
            editablePasswordCardView.fieldSections?[0].textField.becomeFirstResponder()
        }
    }
    
    @objc private func secureNoteCardViewTapped(_ sender: UITapGestureRecognizer) {
        if currentWalletItem.itemType == .secureNotes {
            guard let isFirstFieldSectionFirstResponder = secureNoteCardView.fieldSections?[0].textField.isFirstResponder else { return }
            if !isFirstFieldSectionFirstResponder {
                secureNoteCardView.fieldSections?[0].textField.becomeFirstResponder()
            }
        } else {
            guard let isTextSectionFirstResponder = secureNoteCardView.multiLineSection?.textView.isFirstResponder else { return }
            if !isTextSectionFirstResponder {
                secureNoteCardView.multiLineSection?.textView.becomeFirstResponder()
            }
        }
    }
    
    @objc private func saveButtonPressed(_ sender: UIBarButtonItem) {
        var walletItems = WalletItemStore.shared.items
        if walletItems == nil {
            walletItems = [WalletItem]()
        }
        
        var error: NSError? = NSError()
        if let newWalletItem = currentWalletItemAfterEdits() {
            if newWalletItem.itemType != .secureNotes, let newPasswordItem = newWalletItem.keychainItem as? PasswordKeychainItem {
                if keychain.contains(passwordKeychainItem: newPasswordItem) {
                    let _ = keychain.update(passwordKeychainItem: newPasswordItem, error: &error)
                } else {
                    let _ = keychain.add(passwordKeychainItem: newPasswordItem, error: &error)
                }
                updateWalletItems(&walletItems, newWalletItem: newWalletItem)
                if let unwrappedWalletItems = walletItems { let _ = WalletItemStore.shared.save(unwrappedWalletItems) }
            } else if newWalletItem.itemType == .secureNotes {
                updateWalletItems(&walletItems, newWalletItem: newWalletItem)
                if let unwrappedWalletItems = walletItems { let _ = WalletItemStore.shared.save(unwrappedWalletItems) }
            }
        }
        
        NotificationCenter.default.post(Notification(name: Notification.Name.init("walletItemsChangedNotification")))
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        updateScrollViewContentInset(with: UIEdgeInsets.zero)
    }
    
    private func updateWalletItems(_ walletItems: inout [WalletItem]?, newWalletItem: WalletItem) {
        var modifiedIndex: Int = 0
        if let index = selectedIndexPath?.row {
            walletItems?[index] = newWalletItem
            modifiedIndex = index
        } else {
            walletItems?.append(newWalletItem)
            if let walletItems = walletItems, walletItems.count > 0 {
                modifiedIndex = walletItems.count - 1
            }
        }
        
        if newWalletItem.itemType != .secureNotes, let unwrappedWalletItems = walletItems, let newPasswordItem = newWalletItem.keychainItem {
            //filter out duplicate passwords
            var currentIndex = 0
            var filteredWalletItems = [WalletItem]()
            for walletItem in unwrappedWalletItems {
                if walletItem.itemType == .webPasswords {
                    if !((walletItem.keychainItem as! InternetPasswordKeychainItem).isEqual(to: newPasswordItem as! InternetPasswordKeychainItem)) {
                        filteredWalletItems.append(walletItem)
                    } else {
                        if currentIndex == modifiedIndex {
                            filteredWalletItems.append(walletItem)
                        }
                    }
                } else {
                    if !((walletItem.keychainItem as! PasswordKeychainItem).isEqual(to: newPasswordItem as! PasswordKeychainItem)) {
                        filteredWalletItems.append(walletItem)
                    } else {
                        if currentIndex == modifiedIndex {
                            filteredWalletItems.append(walletItem)
                        }
                    }
                }

                currentIndex += 1
            }
            
            walletItems = filteredWalletItems
        }
    }
    
    private func currentWalletItemAfterEdits() -> WalletItem? {
        var currentKeychainItem: KeychainItem? = nil
        var currentSecureNote: SecureNote? = nil
        
        if currentWalletItem.itemType != .secureNotes {
            if currentWalletItem.itemType == .webPasswords, let fields = editablePasswordCardView.fieldSections {
                if let webURL = URL(string: fields[0].textField.text ?? "") {
                    currentKeychainItem = InternetPasswordKeychainItem(password: fields[2].textField.text ?? "", accountName: fields[1].textField.text ?? "", website: webURL)
                } else {
                    //display error alert
                    let alertController = UIAlertController(title: "Invalid Website URL", message: "You entered an invalid website URL, please correct it and try saving again. Website URL's should be of the form \"google.com\" or \"http://www.google.com\". Consider copying the URL from a web browser.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else if currentWalletItem.itemType == .genericPasswords, let fields = editablePasswordCardView.fieldSections {
                currentKeychainItem = PasswordKeychainItem(password: fields[2].textField.text ?? "", identifier: fields[0].textField.text ?? "", description: fields[1].textField.text ?? "")
            }
            currentSecureNote = SecureNote(title: "", text: currentSecureNoteText())
        } else {
            if let fields = secureNoteCardView.fieldSections {
                currentSecureNote = SecureNote(title: fields[0].textField.text ?? "", text: currentSecureNoteText())
            }
        }
        
        if let unwrappedCurrentSecureNote = currentSecureNote, unwrappedCurrentSecureNote.isEqual(SecureNote.emptyNote()) { currentSecureNote = nil }
        
        if currentKeychainItem == nil && currentSecureNote == nil { return nil }
        return WalletItem(keychainItem: currentKeychainItem, secureNote: currentSecureNote, itemType: currentWalletItem.itemType)
    }
    
    private func currentSecureNoteText() -> String {
        guard let secureNoteText = secureNoteCardView.multiLineSection?.textView.text, secureNoteText != "Your notes are currently empty." else { return "" }
        return secureNoteText
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
                title = editValues.fieldValues[0].value
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
                
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
    }
    
    private func becomeFirstResponderIfApplicable() {
        if isEditing {
            if currentWalletItem.itemType == .secureNotes {
                secureNoteCardView.fieldSections?[0].textField.becomeFirstResponder()
            } else {
                editablePasswordCardView.fieldSections?[0].textField.becomeFirstResponder()
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
        if currentWalletItem.itemType == .webPasswords, let _ = currentWalletItem.keychainItem as? InternetPasswordKeychainItem {
            enableSave = ((textFields[0].text != "") && (textFields[1].text != "") && (textFields[2].text != ""))
        } else if currentWalletItem.itemType == .genericPasswords, let _ = currentWalletItem.keychainItem as? PasswordKeychainItem {
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

