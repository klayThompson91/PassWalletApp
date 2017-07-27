//
//  PasswordWalletViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class PasswordWalletViewController : ClientDependencyViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PasswordEditViewControllerDelegate {
    
    private var pwStyle = PWAppearance.sharedAppearance
    public var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var keychainItemStore = KeychainItemStore.sharedStore
    private var keychainService: KeychainServiceInterface!
    
    private struct Constants {
        static let title = "Passwords"
    }
    
    override public init() {
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
        title = Constants.title
        navigationItem.title = Constants.title
        let backButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        let addButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(addButtonPressed(_:)))
        addButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 28, weight: UIFontWeightRegular), fontColor: UIColor.white), for: .normal)
        navigationItem.rightBarButtonItem = addButtonItem
        tabBarItem = TabBarItemFactory.makeTabBarItem(title: Constants.title, selectedAppearance: ("PassWallet Icon Green", pwStyle.appThemeColor), unselectedAppearance: ("PassWallet Icon Gray", pwStyle.tabBarItemFontColor))
        
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
    
    public func passwordEditViewControllerUpdatedPasswords() {
        collectionView.reloadData()
    }
    
    @objc private func addButtonPressed(_ sender: UIBarButtonItem) {
        let passwordEditVC = PasswordEditViewController(keychainItem: InternetPasswordKeychainItem(password: "", accountName: "", website: URL(string: "passwallet.com")!), secureNote: SecureNote())
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
        
        collectionView.backgroundColor = pwStyle.tableViewBackgroundColor
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.dataSource = keychainItemStore
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
