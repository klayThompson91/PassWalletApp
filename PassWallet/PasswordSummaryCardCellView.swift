//
//  PasswordSummaryCardView.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/11/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public protocol PasswordSummaryCardCellViewDelegate: class {
    func moreActionsButtonWasTapped(for walletItem: WalletItem, cell: PasswordSummaryCardCellView)
}

public class PasswordSummaryCardCellView : CardCellView {
    
    public var walletItem: WalletItem {
        didSet {
            updateViewState(with: walletItem)
            setNeedsUpdateConstraints()
        }
    }
    
    public weak var delegate: PasswordSummaryCardCellViewDelegate?
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var subtitleLabel = UILabel(frame: .zero)
    public private(set) var passwordTypeImageView = UIImageView(frame: .zero)
    public private(set) var moreActionsButton = ExpandedTapAreaButton(expandedTapAreaEdgeInsets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15), frame: .zero)
    
    private var titleLabelTopConstraint = NSLayoutConstraint()
    private var titleLabelCenterConstraint = NSLayoutConstraint()
    private var titleLabelLeftRightConstraints = [NSLayoutConstraint]()
    private var subtitleLabelConstraints = [NSLayoutConstraint]()
    private var passwordTypeImageViewConstraints = [NSLayoutConstraint]()
    private var moreActionsButtonConstraints = [NSLayoutConstraint]()
    
    private struct Constants {
        static let genericPasswordImage = UIImage(named: "GenericPassword Icon")
        static let internetPasswordImage = UIImage(named: "InternetPassword Icon")
        static let mobileAppPasswordImage = UIImage(named: "MobileAppPassword Icon")
        static let secureNoteImage = UIImage(named: "SecureNote Icon")
        static let moreActionsImage = UIImage(named: "MoreActions Icon")
        static let revealPasswordImage = UIImage(named: "RevealPassword Icon")
        static let hidePasswordImage = UIImage(named: "HidePassword Icon")
    }
    
    public override convenience init(frame: CGRect) {
        let emptyKeychainItem = InternetPasswordKeychainItem(password: "", accountName: "abhaycuram@gmail.com", website: URL(string: "Facebook.com")!)
        let emptyWalletItem = WalletItem(keychainItem: emptyKeychainItem, secureNote: SecureNote.emptyNote(), itemType: .webPasswords)
        self.init(frame: frame, walletItem: emptyWalletItem, delegate: nil)
    }
    
    public init(frame: CGRect, walletItem: WalletItem, delegate: PasswordSummaryCardCellViewDelegate?)
    {
        self.delegate = delegate
        self.walletItem = walletItem
        super.init(frame: frame)
        
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont.systemFont(ofSize: 18)
        self.titleLabel.adjustsFontForContentSizeCategory = true
        
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.textColor = UIColor(colorLiteralRed: 100/255, green: 110/255, blue: 105/255, alpha: 1.0)
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        self.subtitleLabel.adjustsFontForContentSizeCategory = true
        
        self.moreActionsButton.addTarget(self, action: #selector(handleMoreActionsButtonTap(_ :)), for: .touchUpInside)
        
        self.addSubviews([titleLabel, subtitleLabel, passwordTypeImageView, moreActionsButton])
        setupConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleMoreActionsButtonTap(_ sender: UIButton) {
        if let observer = delegate {
            observer.moreActionsButtonWasTapped(for: walletItem, cell: self)
        }
    }
    
    private func updateViewState(with newWalletItem: WalletItem) {
        if newWalletItem.itemType == .webPasswords, let internetPassword = newWalletItem.keychainItem as? InternetPasswordKeychainItem {
            self.titleLabel.text = internetPassword.website.absoluteString
            self.subtitleLabel.text = internetPassword.accountName
            self.passwordTypeImageView.image = Constants.internetPasswordImage
        } else if newWalletItem.itemType == .mobileAppPasswords, let mobileAppPassword = newWalletItem.keychainItem as? MobileAppPasswordKeychainItem {
            self.titleLabel.text = mobileAppPassword.applicationName
            self.subtitleLabel.text = mobileAppPassword.accountName
            self.passwordTypeImageView.image = Constants.mobileAppPasswordImage
        }
        else if newWalletItem.itemType == .genericPasswords, let genericPassword = newWalletItem.keychainItem as? PasswordKeychainItem {
            self.titleLabel.text = genericPassword.identifier
            self.subtitleLabel.text = genericPassword.itemDescription
            self.passwordTypeImageView.image = Constants.genericPasswordImage
        } else if newWalletItem.itemType == .secureNotes, let secureNote = newWalletItem.secureNote {
            self.titleLabel.text = secureNote.title
            self.subtitleLabel.text = ""
            self.passwordTypeImageView.image = Constants.secureNoteImage
        }
        
        self.moreActionsButton.setBackgroundImage(Constants.moreActionsImage, for: .normal)
    }
    
    private func setupConstraints()
    {
        passwordTypeImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        passwordTypeImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        passwordTypeImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        moreActionsButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        moreActionsButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        PWConstraint.disableAutoresize(forViews: [titleLabel, subtitleLabel, passwordTypeImageView, moreActionsButton])
        
        passwordTypeImageViewConstraints.append(passwordTypeImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        passwordTypeImageViewConstraints.append(passwordTypeImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15))
        
        moreActionsButtonConstraints.append(moreActionsButton.topAnchor.constraint(equalTo: passwordTypeImageView.topAnchor))
        moreActionsButtonConstraints.append(moreActionsButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15))
        
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: passwordTypeImageView.topAnchor)
        titleLabelCenterConstraint = titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleLabelLeftRightConstraints.append(titleLabel.leftAnchor.constraint(equalTo: passwordTypeImageView.rightAnchor, constant: 13.5))
        titleLabelLeftRightConstraints.append(titleLabel.rightAnchor.constraint(equalTo: moreActionsButton.leftAnchor, constant: -13.5))
        subtitleLabelConstraints.append(subtitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor))
        subtitleLabelConstraints.append(subtitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor))
        subtitleLabelConstraints.append(subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5))
        
        var constraintsToActivate = titleLabelLeftRightConstraints + passwordTypeImageViewConstraints + moreActionsButtonConstraints
        if let subtitleText = self.subtitleLabel.text, !subtitleText.isEmpty {
            constraintsToActivate += [titleLabelTopConstraint] + subtitleLabelConstraints
        } else {
            constraintsToActivate += [titleLabelCenterConstraint]
        }
        
        NSLayoutConstraint.activate(constraintsToActivate)
        
    }
    
    public override func updateConstraints() {
        var constraintsToActivate = [NSLayoutConstraint]()
        var constraintsToDeactivate = [NSLayoutConstraint]()
        
        if let subtitleText = self.subtitleLabel.text, !subtitleText.isEmpty {
            constraintsToActivate = [titleLabelTopConstraint] + subtitleLabelConstraints
            constraintsToDeactivate = [titleLabelCenterConstraint]
        } else {
            constraintsToActivate = [titleLabelCenterConstraint]
            constraintsToDeactivate = [titleLabelTopConstraint] + subtitleLabelConstraints
        }
        
        NSLayoutConstraint.deactivate(constraintsToDeactivate)
        NSLayoutConstraint.activate(constraintsToActivate)
        super.updateConstraints()
    }
    
}
