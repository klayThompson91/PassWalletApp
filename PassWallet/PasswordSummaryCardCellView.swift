//
//  PasswordSummaryCardView.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/11/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class PasswordSummaryCardCellView : CardCellView {
    
    public var keychainItem: KeychainItem {
        didSet {
            updateViewState(with: keychainItem)
            setNeedsUpdateConstraints()
        }
    }
    
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var subtitleLabel = UILabel(frame: .zero)
    public private(set) var passwordTypeImageView = UIImageView(frame: .zero)
    
    private var titleLabelTopConstraint = NSLayoutConstraint()
    private var titleLabelCenterConstraint = NSLayoutConstraint()
    private var titleLabelLeftRightConstraints = [NSLayoutConstraint]()
    private var subtitleLabelConstraints = [NSLayoutConstraint]()
    private var passwordTypeImageViewConstraints = [NSLayoutConstraint]()
    
    private struct Constants {
        static let genericPasswordImage = UIImage(named: "GenericPassword Icon")
        static let internetPasswordImage = UIImage(named: "InternetPassword Icon")
    }
    
    public override convenience init(frame: CGRect) {
        let emptyKeychainItem = InternetPasswordKeychainItem(password: "", accountName: "abhaycuram@gmail.com", website: URL(string: "Facebook.com")!)
        self.init(frame: frame, keychainItem: emptyKeychainItem)
    }
    
    public init(frame: CGRect, keychainItem: KeychainItem)
    {
        self.keychainItem = keychainItem
        super.init(frame: frame)
        
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular)
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.textColor = UIColor(colorLiteralRed: 100/255, green: 110/255, blue: 105/255, alpha: 1.0)
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        
        self.addSubviews([titleLabel, subtitleLabel, passwordTypeImageView])
        setupConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    private func setupConstraints()
    {
        passwordTypeImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        passwordTypeImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        PWConstraint.disableAutoresize(forViews: [titleLabel, subtitleLabel, passwordTypeImageView])
        
        passwordTypeImageViewConstraints.append(passwordTypeImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        passwordTypeImageViewConstraints.append(passwordTypeImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15))
        
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: passwordTypeImageView.topAnchor)
        titleLabelCenterConstraint = titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleLabelLeftRightConstraints.append(titleLabel.leftAnchor.constraint(equalTo: passwordTypeImageView.rightAnchor, constant: 13.5))
        titleLabelLeftRightConstraints.append(titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -30))
        subtitleLabelConstraints.append(subtitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor))
        subtitleLabelConstraints.append(subtitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor))
        subtitleLabelConstraints.append(subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5))
        
        var constraintsToActivate = [NSLayoutConstraint]()
        if let subtitleText = self.subtitleLabel.text, !subtitleText.isEmpty {
            constraintsToActivate = [titleLabelTopConstraint] + titleLabelLeftRightConstraints + passwordTypeImageViewConstraints + subtitleLabelConstraints
        } else {
            constraintsToActivate = [titleLabelCenterConstraint] + passwordTypeImageViewConstraints + titleLabelLeftRightConstraints
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
