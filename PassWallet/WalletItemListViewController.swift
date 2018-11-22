//
//  WalletItemListViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit
import StoreKit


public class WalletItemListViewController : ClientDependencyViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PasswordSummaryCardCellViewDelegate {

    public var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var emptyWalletIconImageView = UIImageView(frame: .zero)
    private var emptyWalletMessageLabel = UILabel(frame: .zero)
    
    private var collectionViewConstraints = [NSLayoutConstraint]()
    private var emptyWalletStateConstraints = [NSLayoutConstraint]()
    
    private var pwStyle = PWAppearance.sharedAppearance
    private var walletItemStore = WalletItemStore.shared
    private var keychainService: KeychainServiceInterface!
    private var currentItemType: WalletItemType
    
    private var viewDidLoadFlag = false
    
    public init(walletItemType: WalletItemType) {
        currentItemType = walletItemType
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(walletItemsDidChange(_:)), name: NSNotification.Name.init("walletItemsChangedNotification"), object: nil)
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
        addButtonItem.setTitleTextAttributes(PWAppearance.sharedAppearance.attributesFrom(font: UIFont.systemFont(ofSize: 32, weight: UIFontWeightMedium), fontColor: UIColor.white), for: .normal)
        navigationItem.rightBarButtonItem = addButtonItem
        view.backgroundColor = pwStyle.tableViewBackgroundColor
        
        configureCollectionView()
        configureEmptyViewState()
        view.addSubview(collectionView)
        view.addSubview(emptyWalletMessageLabel)
        view.addSubview(emptyWalletIconImageView)
        setupCollectionViewConstraints()
        setupEmptyViewConstraints()
        toggleViewStateAndTree()
        viewDidLoadFlag = true
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewDidLoadFlag {
            toggleViewStateAndTree()
        }
    }
    
    private func toggleViewStateAndTree() {
        if let itemsCount = WalletItemStore.shared.items?.count, itemsCount > 0 {
            emptyWalletMessageLabel.removeFromSuperview()
            emptyWalletIconImageView.removeFromSuperview()
            view.addSubview(collectionView)
            NSLayoutConstraint.activate(collectionViewConstraints)
        } else {
            collectionView.removeFromSuperview()
            view.addSubview(emptyWalletIconImageView)
            view.addSubview(emptyWalletMessageLabel)
            NSLayoutConstraint.activate(emptyWalletStateConstraints)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedWalletItem = walletItemStore.items?[indexPath.row] else {
            return
        }
        
        routeToWalletItemEditViewController(selectedWalletItem, indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.bounds.width - 40
        let defaultHeight: CGFloat = 80
        let collapsedHeight: CGFloat = 65
        let defaultSize = CGSize(width: width, height: defaultHeight)
        let collapsedSize = CGSize(width: width, height: collapsedHeight)
        
        if let currentWalletItem = walletItemStore.items?[indexPath.row] {
            if currentWalletItem.itemType == .webPasswords, let webLoginWalletItem = currentWalletItem.keychainItem as? InternetPasswordKeychainItem {
                return (webLoginWalletItem.accountName.isEmpty) ? collapsedSize : defaultSize
            } else if currentWalletItem.itemType == .genericPasswords, let passwordWalletItem = currentWalletItem.keychainItem as? PasswordKeychainItem {
                return (passwordWalletItem.itemDescription.isEmpty) ? collapsedSize : defaultSize
            } else if currentWalletItem.itemType == .secureNotes, let secureNoteWalletItem = currentWalletItem.secureNote {
                return (secureNoteWalletItem.title.isEmpty) ? collapsedSize : defaultSize
            }
        }
        
        return defaultSize
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let unwrappedItems = walletItemStore.items else {
            return 0
        }
        
        return unwrappedItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemAtIndexPath = walletItemStore.items?[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PasswordSummaryCardCellView", for: indexPath) as! PasswordSummaryCardCellView
        cell.walletItem = itemAtIndexPath!
        cell.delegate = self
        return cell
    }
    
    public func moreActionsButtonWasTapped(for walletItem: WalletItem, cell: PasswordSummaryCardCellView) {
        
        var error: NSError? = NSError()
        var title = ""
        
        if walletItem.itemType == .secureNotes, let secureNote = walletItem.secureNote {
            title = secureNote.title
        }
        if walletItem.itemType == .genericPasswords, let genericPassword = walletItem.keychainItem as? PasswordKeychainItem {
            title = genericPassword.identifier
        }
        if walletItem.itemType == .webPasswords, let webPassword = walletItem.keychainItem as? InternetPasswordKeychainItem {
            title = webPassword.website.absoluteString
        }
        
        let moreActionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        moreActionsAlert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self] (_) in
            if let strongSelf = self {
                if let selectedIndexPath = strongSelf.collectionView.indexPath(for: cell) {
                    strongSelf.routeToWalletItemEditViewController(walletItem, selectedIndexPath)
                }
            }
        }))
        
        if walletItem.itemType != .secureNotes {
            if walletItem.itemType == .webPasswords, let internetPasswordKeychainItem = walletItem.keychainItem as? InternetPasswordKeychainItem {
                moreActionsAlert.addAction(UIAlertAction(title: "Copy website", style: .default, handler: { [weak self] (_) in
                    if let strongSelf = self {
                        UIPasteboard.general.string = internetPasswordKeychainItem.website.absoluteString
                        ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
                    }
                }))
                moreActionsAlert.addAction(UIAlertAction(title: "Copy email/username", style: .default, handler: { [weak self] (_) in
                    if let strongSelf = self {
                        UIPasteboard.general.string = internetPasswordKeychainItem.accountName
                        ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
                    }
                }))
            }
            
            moreActionsAlert.addAction(UIAlertAction(title: "Copy password", style: .default, handler: { [weak self] (_) in
                if let strongSelf = self {
                    UIPasteboard.general.string = strongSelf.keychainService.getStringValueFor(passwordKeychainItem: walletItem.keychainItem as! PasswordKeychainItem, error: &error) as String?
                    ClipboardWhisper.showCopiedMessage(for: strongSelf.navigationController!)
                }
            }))
        }
        
        moreActionsAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (_) in
            if let strongSelf = self {
                let confirmationAlert = AlertControllerFactory.deleteWalletItemAlert(walletItem.itemType) { [weak self] (_) in
                    if let strongSelf = self {
                        var walletItems = strongSelf.walletItemStore.items
                        walletItems = walletItems?.filter { !($0.isEqual(walletItem)) }
                        if let unwrappedWalletItems = walletItems {
                            let _ = strongSelf.walletItemStore.save(unwrappedWalletItems)
                        }
                        
                        if walletItem.itemType != .secureNotes, let keychainItem = walletItem.keychainItem {
                            let _ = strongSelf.keychainService.delete(passwordKeychainItem: keychainItem as! PasswordKeychainItem, error: &error)
                        }
                        self?.walletItemsDidChange(Notification.init(name: Notification.Name.init("walletItemsChangedNotification")))
                    }
                }
                strongSelf.present(confirmationAlert, animated: true, completion: nil)

            }
        }))
        
        moreActionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        moreActionsAlert.popoverPresentationController?.sourceView = cell
        self.present(moreActionsAlert, animated: true, completion: nil)
    }
    
    @objc private func walletItemsDidChange(_ notification: Notification) {
        if let itemsCount = WalletItemStore.shared.items?.count, itemsCount <= 0 {
            toggleViewStateAndTree()
        } else {
            collectionView.reloadData()
        }
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    @objc private func addButtonPressed(_ sender: UIBarButtonItem) {
        let editVC = WalletItemEditViewController(walletItem: WalletItem(keychainItem: currentItemType.toPasswordKeychainItem(), secureNote: SecureNote.emptyNote(), itemType: currentItemType), selectedIndexPath: nil)
        navigationController?.pushViewController(editVC, animated: true)
        editVC.isEditing = true
    }
    
    private func configureCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.itemSize = CGSize(width: view.bounds.width - 40, height: 80)
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0)
        collectionViewLayout.minimumLineSpacing = 20
        
        walletItemStore.itemType = currentItemType
        
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
        collectionViewConstraints = constraint.constraints
    }
    
    private func setupEmptyViewConstraints() {
        let constraint = PWConstraint()
        PWConstraint.disableAutoresize(forViews: [emptyWalletIconImageView, emptyWalletMessageLabel])
        constraint.addConstraint(emptyWalletIconImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80))
        constraint.addConstraint(emptyWalletIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraint.addConstraint(emptyWalletIconImageView.widthAnchor.constraint(equalToConstant: 100))
        constraint.addConstraint(emptyWalletIconImageView.heightAnchor.constraint(equalToConstant: 100))
        constraint.addConstraint(emptyWalletMessageLabel.topAnchor.constraint(equalTo: emptyWalletIconImageView.bottomAnchor, constant: 60))
        constraint.addConstraint(emptyWalletMessageLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30))
        constraint.addConstraint(emptyWalletMessageLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30))
        emptyWalletStateConstraints = constraint.constraints
    }
    
    private func configureEmptyViewState() {
        if currentItemType == .webPasswords {
            emptyWalletIconImageView.image = UIImage(named: "LargeInternetPassword Icon")
        } else if currentItemType == .genericPasswords {
            emptyWalletIconImageView.image = UIImage(named: "LargeGenericPassword Icon")
        } else {
            emptyWalletIconImageView.image = UIImage(named: "LargeSecureNote Icon")
        }
        
        emptyWalletMessageLabel.numberOfLines = 0
        emptyWalletMessageLabel.text = "Your \(currentItemType.toString()) are currently empty, get started by pressing the plus button on the top right."
        emptyWalletMessageLabel.textAlignment = .center
        emptyWalletMessageLabel.textColor = UIColor(colorLiteralRed: 0.427451, green: 0.427451, blue: 0.447059, alpha: 1)
        emptyWalletMessageLabel.font = UIFont.systemFont(ofSize: 16)
    }
    
    private func routeToWalletItemEditViewController(_ selectedWalletItem: WalletItem, _ indexPath: IndexPath)
    {
        if selectedWalletItem.itemType != .secureNotes, let selectedWalletKeychainItem = selectedWalletItem.keychainItem as? PasswordKeychainItem {
            if keychainService.contains(passwordKeychainItem: selectedWalletKeychainItem) {
                var error: NSError? = NSError()
                if let passwordInKeychain = keychainService.getStringValueFor(passwordKeychainItem: selectedWalletKeychainItem, error: &error) as String? {
                    selectedWalletKeychainItem.password = passwordInKeychain
                }
            }
        }
        
        let passwordEditVC = WalletItemEditViewController(walletItem: selectedWalletItem, selectedIndexPath: indexPath)
        navigationController?.pushViewController(passwordEditVC, animated: true)
        passwordEditVC.isEditing = false
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
}
