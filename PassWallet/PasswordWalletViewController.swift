//
//  PasswordWalletViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public enum WalletItemType: Int
{
    case webPasswords
    case genericPasswords
    case secureNotes
    
    public func toString() -> String {
        switch self {
        case .webPasswords:
            return "Web Passwords"
        case .genericPasswords:
            return "Generic Passwords"
        case .secureNotes:
            return "Secure Notes"
        }
    }
    
    public func toPasswordKeychainItem() -> PasswordKeychainItem? {
        switch self {
        case .webPasswords:
            return InternetPasswordKeychainItem(password: "", accountName: "", website: URL(string: "passwallet.com")!)
        case .genericPasswords:
            return PasswordKeychainItem(description: "", value: "")
        case .secureNotes:
            return nil
        }
    }
}

public class PasswordWalletViewController : ClientDependencyViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PasswordEditViewControllerDelegate, PasswordSummaryCardCellViewDelegate {

    public var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private var pwStyle = PWAppearance.sharedAppearance
    private var keychainItemStore = KeychainItemStore.sharedStore
    private var keychainService: KeychainServiceInterface!
    private var currentItemType: WalletItemType
    
    public init(walletItemType: WalletItemType) {
        currentItemType = walletItemType
        super.init()
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
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = currentItemType.toString()
        navigationItem.title = currentItemType.toString()
        let backButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        let addButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(addButtonPressed(_:)))
        addButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 32, weight: UIFontWeightThin), fontColor: UIColor.white), for: .normal)
        navigationItem.rightBarButtonItem = addButtonItem
        
        configureCollectionView()
        view.addSubview(collectionView)
        setupCollectionViewConstraints()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedKeychainItem = keychainItemStore.items?[indexPath.row] as? PasswordKeychainItem else {
            return
        }
        
        if keychainService.contains(passwordKeychainItem: selectedKeychainItem) {
            var error: NSError? = NSError()
            if let passwordInKeychain = keychainService.getStringValueFor(passwordKeychainItem: selectedKeychainItem, error: &error) as String? {
                selectedKeychainItem.password = passwordInKeychain
            }
        }
        
        let passwordEditVC = PasswordEditViewController(keychainItem: selectedKeychainItem, secureNote: SecureNote())
        passwordEditVC.delegate = self
        navigationController?.pushViewController(passwordEditVC, animated: true)
        passwordEditVC.isEditing = false
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.bounds.width - 40
        let defaultHeight: CGFloat = 80
        let collapsedHeight: CGFloat = 65
        let defaultSize = CGSize(width: width, height: defaultHeight)
        let collapsedSize = CGSize(width: width, height: collapsedHeight)
        
        if let currentItem = keychainItemStore.items?[indexPath.row] {
            if let webLoginItem = currentItem as? InternetPasswordKeychainItem {
                return (webLoginItem.accountName.isEmpty) ? collapsedSize : defaultSize
            } else if let passwordItem = currentItem as? PasswordKeychainItem {
                return (passwordItem.itemDescription.isEmpty) ? collapsedSize : defaultSize
            }
        }
        
        return defaultSize
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let unwrappedItems = keychainItemStore.items else {
            return 0
        }
        
        return unwrappedItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemAtIndexPath = keychainItemStore.items?[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PasswordSummaryCardCellView", for: indexPath) as! PasswordSummaryCardCellView
        cell.keychainItem = itemAtIndexPath!
        cell.delegate = self
        return cell
    }
    
    public func moreActionsButtonWasTapped(for keychainItem: PasswordKeychainItem) {
        
        var error: NSError? = NSError()
        var title = keychainItem.identifier
        if let internetPasswordKeychainItem = keychainItem as? InternetPasswordKeychainItem {
            title = internetPasswordKeychainItem.website.absoluteString
        }
        
        let moreActionsAlert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        if let internetPasswordKeychainItem = keychainItem as? InternetPasswordKeychainItem {
            moreActionsAlert.addAction(UIAlertAction(title: "copy website", style: .default, handler: { [weak self] (_) in
                if let strongSelf = self {
                    UIPasteboard.general.string = internetPasswordKeychainItem.website.absoluteString
                    ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
                }
            }))
            moreActionsAlert.addAction(UIAlertAction(title: "copy email/username", style: .default, handler: { [weak self] (_) in
                if let strongSelf = self {
                    UIPasteboard.general.string = internetPasswordKeychainItem.accountName
                    ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
                }
            }))
        }
        
        moreActionsAlert.addAction(UIAlertAction(title: "copy password", style: .default, handler: { [weak self] (_) in
            if let strongSelf = self {
                UIPasteboard.general.string = strongSelf.keychainService.getStringValueFor(passwordKeychainItem: keychainItem, error: &error) as String?
                ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
            }
        }))
        
        moreActionsAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (_) in
            if let strongSelf = self {
                var keychainItems = strongSelf.keychainItemStore.items
                keychainItems = keychainItems?.filter { !($0.isEqual(keychainItem)) }
                if let unwrappedKeychainItems = keychainItems {
                    let _ = strongSelf.keychainItemStore.save(unwrappedKeychainItems)
                }
                let _ = strongSelf.keychainService.delete(passwordKeychainItem: keychainItem, error: &error)
                strongSelf.collectionView.reloadData()
            }
        }))
        
        moreActionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(moreActionsAlert, animated: true, completion: nil)
    }
    
    public func passwordEditViewControllerUpdatedPasswords() {
        collectionView.reloadData()
    }
    
    @objc private func addButtonPressed(_ sender: UIBarButtonItem) {
        let passwordEditVC = PasswordEditViewController(keychainItem: currentItemType.toPasswordKeychainItem(), secureNote: SecureNote())
        passwordEditVC.delegate = self
        navigationController?.pushViewController(passwordEditVC, animated: true)
        passwordEditVC.isEditing = true
    }
    
    private func configureCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.itemSize = CGSize(width: view.bounds.width - 40, height: 80)
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0)
        collectionViewLayout.minimumLineSpacing = 20
        
        if currentItemType != .secureNotes, let keychainItemType = KeychainItemType(walletItemType: currentItemType) {
            keychainItemStore.keychainItemType = keychainItemType
        }
        
        collectionView.backgroundColor = pwStyle.tableViewBackgroundColor
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.dataSource = self
        collectionView.register(PasswordSummaryCardCellView.self, forCellWithReuseIdentifier: "PasswordSummaryCardCellView")
        collectionView.delegate = self
    }

    private func setupCollectionViewConstraints() {
        let constraint = PWConstraint()
        PWConstraint.disableAutoresize(forView: collectionView)
        constraint.addConstraint(collectionView.leftAnchor.constraint(equalTo: view.leftAnchor))
        constraint.addConstraint(collectionView.rightAnchor.constraint(equalTo: view.rightAnchor))
        constraint.addConstraint(collectionView.topAnchor.constraint(equalTo: view.topAnchor))
        constraint.addConstraint(collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        NSLayoutConstraint.activate(constraint.constraints)
    }
}
