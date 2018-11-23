//
//  EditablePasswordCardSectionViews.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class EditableMultiLineSectionView: UIView, UITextViewDelegate {
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: titleLabel.intrinsicContentSize.height + textViewHeightConstraint.constant + 6)
    }
    
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var textView = UITextView(frame: .zero)
    
    private var textViewHeightConstraint = NSLayoutConstraint()
    private var multiLineSectionTapGestureRecognizer = UITapGestureRecognizer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor(colorLiteralRed: 145/255, green: 155/255, blue: 150/255, alpha: 1.0)
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.delegate = self
        addSubviews([titleLabel, textView])
        setupConstraints()
        
        multiLineSectionTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(multiLineTextSectionTapped(_:)))
        titleLabel.addGestureRecognizer(multiLineSectionTapGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        /**
         * UITextView's intrinsicContentSize pose a problem because they are multi-line text.
         * As a result size constraints to apply in both the horizontal and vertical direction
         * are ambiguous once text overflows one line. To solve this we let the constraint pass
         * do its thing and compute out how much width MultiLineSectionView will be, once it does
         * that we get the actual frame set here in the layout pass with the appropriate width.
         * We use this to then get the vertical length (size) needed to fit the text inside of the
         * TextView with the currently set frame width. Once determining this height we apply it
         * as a constraint on the UITextView and invalidate the current view and its ancestors
         * intrinsicContentSize which will force new constraints to be measured based on these 
         * new updates and then re-layed out.
         */
        updateTextViewHeightConstraintsAndRelayoutIfNeeded()
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeightConstraintsAndRelayoutIfNeeded()
        
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.textColor == UIColor.lightGray {
            //remove place holder text if present
            textView.text = ""
            textView.textColor = UIColor.black
        }
        return true
    }
    
    private func updateTextViewHeightConstraintsAndRelayoutIfNeeded() {
        let heightNeededForTextView = textView.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        let currentTextViewHeight = textViewHeightConstraint.constant
        if heightNeededForTextView != currentTextViewHeight {
            if textViewHeightConstraint.isActive == false {
                textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: heightNeededForTextView)
                textViewHeightConstraint.isActive = true
            } else {
                textViewHeightConstraint.constant = heightNeededForTextView
            }
            invalidateIntrinsicContentSizeOfSuperViews(true)
        }
    }
    
    private func setupConstraints() {
        var constraints = [NSLayoutConstraint]()
        PWConstraint.disableAutoresize(forViews: [titleLabel, textView])
        constraints.append(titleLabel.topAnchor.constraint(equalTo: self.topAnchor))
        constraints.append(titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor))
        constraints.append(textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6))
        constraints.append(textView.leftAnchor.constraint(equalTo: self.leftAnchor))
        constraints.append(textView.rightAnchor.constraint(equalTo: self.rightAnchor))
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func multiLineTextSectionTapped(_ sender: UITapGestureRecognizer) {
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }
}

public class EditableFieldSectionView: UIView {
    
    public override var intrinsicContentSize: CGSize {
        let lowerHeight = max(textField.intrinsicContentSize.height + dividerView.intrinsicContentSize.height + 1, supplementaryCopyButton.intrinsicContentSize.height)
        let subviewHeights = titleLabel.intrinsicContentSize.height + lowerHeight
        return CGSize(width: UIViewNoIntrinsicMetric, height: subviewHeights + 6)
    }
    
    public private(set) var textField = UITextField(frame: .zero)
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var supplementaryPasswordRevealButton = UIButton(type: .custom)
    public private(set) var supplementaryCopyButton = UIButton(frame: .zero)
    public private(set) var dividerView = UIView(frame: .zero)
    
    public var hideSupplementaryCopyButton = false {
        didSet {
            if hideSupplementaryCopyButton {
                supplementaryCopyButton.removeFromSuperview()
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var hideSupplementaryPasswordRevealButton = true {
        didSet {
            if hideSupplementaryPasswordRevealButton {
                supplementaryPasswordRevealButton.removeFromSuperview()
                setNeedsUpdateConstraints()
            }
        }
    }
    
    private var fieldTapGestureRecognizer = UITapGestureRecognizer()
    private var textFieldLeftConstraint = NSLayoutConstraint()
    private var isPasswordRevealed = false
    
    
    private struct Constants {
        static let revealPasswordImage = UIImage(named: "RevealPassword Icon")
        static let hidePasswordImage = UIImage(named: "HidePassword Icon")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor(colorLiteralRed: 145/255, green: 155/255, blue: 150/255, alpha: 1.0)
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.isUserInteractionEnabled = true
        textField.font = UIFont.systemFont(ofSize: 17)
        supplementaryPasswordRevealButton.setImage(Constants.revealPasswordImage, for: .normal)
        supplementaryPasswordRevealButton.addTarget(self, action: #selector(handlePasswordRevealButtonTap(_ :)), for: .touchUpInside)
        supplementaryCopyButton.backgroundColor = UIColor.clear
        supplementaryCopyButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
        supplementaryCopyButton.setTitleColor(PWAppearance.sharedAppearance.appThemeColor, for: .normal)
        supplementaryCopyButton.setTitleColor(PWAppearance.sharedAppearance.appThemeColorWhenSelected, for: .highlighted)
        dividerView.backgroundColor = UIColor(colorLiteralRed: 216/255, green: 216/255, blue: 216/255, alpha: 1.0)
        self.addSubviews([titleLabel, textField, supplementaryCopyButton, supplementaryPasswordRevealButton, dividerView])
        setupConstraints()
        
        fieldTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(fieldLabelTapped(_:)))
        titleLabel.addGestureRecognizer(fieldTapGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateConstraints() {
        NSLayoutConstraint.deactivate([textFieldLeftConstraint])
        textFieldLeftConstraint = generateTextFieldLeftConstraint()
        NSLayoutConstraint.activate([textFieldLeftConstraint])
        super.updateConstraints()
    }
    
    private func setupConstraints() {
        var constraints = [NSLayoutConstraint]()
        supplementaryCopyButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        supplementaryCopyButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        supplementaryPasswordRevealButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        supplementaryPasswordRevealButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        PWConstraint.disableAutoresize(forViews: [textField, titleLabel, supplementaryPasswordRevealButton, supplementaryCopyButton, dividerView])
        constraints.append(titleLabel.topAnchor.constraint(equalTo: self.topAnchor))
        constraints.append(titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor))
        constraints.append(supplementaryCopyButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor))
        constraints.append(supplementaryCopyButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20))
        constraints.append(supplementaryPasswordRevealButton.centerYAnchor.constraint(equalTo: supplementaryCopyButton.centerYAnchor))
        constraints.append(supplementaryPasswordRevealButton.rightAnchor.constraint(equalTo: supplementaryCopyButton.leftAnchor, constant: -10))
        constraints.append(textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6))
        constraints.append(textField.leftAnchor.constraint(equalTo: titleLabel.leftAnchor))
        textFieldLeftConstraint = generateTextFieldLeftConstraint()
        constraints.append(textFieldLeftConstraint)
        constraints.append(dividerView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 1))
        constraints.append(dividerView.leftAnchor.constraint(equalTo: textField.leftAnchor))
        constraints.append(dividerView.rightAnchor.constraint(equalTo: self.rightAnchor))
        constraints.append(dividerView.heightAnchor.constraint(equalToConstant: 0.5))
        NSLayoutConstraint.activate(constraints)
    }
    
    private func generateTextFieldLeftConstraint() -> NSLayoutConstraint
    {
        if !hideSupplementaryPasswordRevealButton {
            return textField.rightAnchor.constraint(equalTo: supplementaryPasswordRevealButton.leftAnchor, constant: -20)
        } else if !hideSupplementaryCopyButton {
            return textField.rightAnchor.constraint(equalTo: supplementaryCopyButton.leftAnchor, constant: -20)
        } else {
            return textField.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20)
        }
    }
    
    @objc private func fieldLabelTapped(_ sender: UITapGestureRecognizer) {
        if !textField.isFirstResponder {
            textField.becomeFirstResponder()
        }
    }
    
    @objc private func handlePasswordRevealButtonTap(_ sender: UIButton) {
        if !isPasswordRevealed {
            textField.isSecureTextEntry = false
            isPasswordRevealed = true
            supplementaryPasswordRevealButton.setImage(Constants.hidePasswordImage, for: .normal)
        } else {
            textField.isSecureTextEntry = true
            isPasswordRevealed = false
            supplementaryPasswordRevealButton.setImage(Constants.revealPasswordImage, for: .normal)
        }
    }
    
}
