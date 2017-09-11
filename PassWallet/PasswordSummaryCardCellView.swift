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
    func moreActionsButtonWasTapped(for keychainItem: PasswordKeychainItem)
}

public class PasswordSummaryCardCellView : CardCellView {
    
    public var keychainItem: KeychainItem {
        didSet {
            updateViewState(with: keychainItem)
            setNeedsUpdateConstraints()
        }
    }
    
    public weak var delegate: PasswordSummaryCardCellViewDelegate?
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var subtitleLabel = UILabel(frame: .zero)
    public private(set) var passwordTypeImageView = UIImageView(frame: .zero)
    public private(set) var moreActionsButton = UIButton(type: .custom)
    
    private var titleLabelTopConstraint = NSLayoutConstraint()
    private var titleLabelCenterConstraint = NSLayoutConstraint()
    private var titleLabelLeftRightConstraints = [NSLayoutConstraint]()
    private var subtitleLabelConstraints = [NSLayoutConstraint]()
    private var passwordTypeImageViewConstraints = [NSLayoutConstraint]()
    private var moreActionsButtonConstraints = [NSLayoutConstraint]()
    
    private struct Constants {
        static let genericPasswordImage = UIImage(named: "GenericPassword Icon")
        static let internetPasswordImage = UIImage(named: "InternetPassword Icon")
        static let moreActionsImage = UIImage(named: "MoreActions Icon")
    }
    
    public override convenience init(frame: CGRect) {
        let emptyKeychainItem = InternetPasswordKeychainItem(password: "", accountName: "abhaycuram@gmail.com", website: URL(string: "Facebook.com")!)
        self.init(frame: frame, keychainItem: emptyKeychainItem, delegate: nil)
    }
    
    public init(frame: CGRect, keychainItem: KeychainItem, delegate: PasswordSummaryCardCellViewDelegate?)
    {
        self.delegate = delegate
        self.keychainItem = keychainItem
        super.init(frame: frame)
        
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular)
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.textColor = UIColor(colorLiteralRed: 100/255, green: 110/255, blue: 105/255, alpha: 1.0)
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        self.moreActionsButton.addTarget(self, action: #selector(handleMoreActionsButtonTap(_ :)), for: .touchUpInside)
        
        self.addSubviews([titleLabel, subtitleLabel, passwordTypeImageView, moreActionsButton])
        setupConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleMoreActionsButtonTap(_ sender: UIButton) {
        if let observer = delegate, let passwordKeychainItem = keychainItem as? PasswordKeychainItem {
            observer.moreActionsButtonWasTapped(for: passwordKeychainItem)
        }
    }
    
    private func updateViewState(with newKeychainItem: KeychainItem) {
        if let internetPassword = newKeychainItem as? InternetPasswordKeychainItem {
            self.titleLabel.text = internetPassword.website.absoluteString
            self.subtitleLabel.text = internetPassword.accountName
            self.passwordTypeImageView.image = Constants.internetPasswordImage
        } else if let genericPassword = newKeychainItem as? PasswordKeychainItem {
            self.titleLabel.text = genericPassword.identifier
            self.subtitleLabel.text = genericPassword.itemDescription
            self.passwordTypeImageView.image = Constants.genericPasswordImage
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
