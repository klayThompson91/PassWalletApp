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
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.systemFont(ofSize: 16)
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
        let lowerHeight = max(textField.intrinsicContentSize.height + dividerView.intrinsicContentSize.height + 1, supplementaryButton.intrinsicContentSize.height)
        let subviewHeights = titleLabel.intrinsicContentSize.height + lowerHeight
        return CGSize(width: UIViewNoIntrinsicMetric, height: subviewHeights + 6)
    }
    
    public private(set) var textField = UITextField(frame: .zero)
    public private(set) var titleLabel = UILabel(frame: .zero)
    public private(set) var supplementaryButton = UIButton(frame: .zero)
    public private(set) var dividerView = UIView(frame: .zero)
    
    public var hideSupplementaryButton = false {
        didSet {
            if hideSupplementaryButton {
                supplementaryButton.removeFromSuperview()
                setNeedsUpdateConstraints()
            }
        }
    }
    
    private var fieldTapGestureRecognizer = UITapGestureRecognizer()
    private var previouslyAppliedTextFieldLeftAnchorConstraint = [NSLayoutConstraint]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor(colorLiteralRed: 145/255, green: 155/255, blue: 150/255, alpha: 1.0)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.isUserInteractionEnabled = true
        textField.font = UIFont.systemFont(ofSize: 16)
        supplementaryButton.backgroundColor = UIColor.clear
        supplementaryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        supplementaryButton.setTitleColor(PWAppearance.sharedAppearance.appThemeColor, for: .normal)
        supplementaryButton.setTitleColor(PWAppearance.sharedAppearance.appThemeColorWhenSelected, for: .highlighted)
        dividerView.backgroundColor = UIColor(colorLiteralRed: 216/255, green: 216/255, blue: 216/255, alpha: 1.0)
        self.addSubviews([titleLabel, textField, supplementaryButton, dividerView])
        setupConstraints()
        
        fieldTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(fieldLabelTapped(_:)))
        titleLabel.addGestureRecognizer(fieldTapGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateConstraints() {
        if hideSupplementaryButton {
            var updatedTextFieldRightAnchorConstraints = [NSLayoutConstraint]()
            updatedTextFieldRightAnchorConstraints.append(textField.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20))
            NSLayoutConstraint.deactivate(previouslyAppliedTextFieldLeftAnchorConstraint)
            NSLayoutConstraint.activate(updatedTextFieldRightAnchorConstraints)
        }
        super.updateConstraints()
    }
    
    private func setupConstraints() {
        var constraints = [NSLayoutConstraint]()
        supplementaryButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        supplementaryButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        PWConstraint.disableAutoresize(forViews: [textField, titleLabel, supplementaryButton, dividerView])
        constraints.append(titleLabel.topAnchor.constraint(equalTo: self.topAnchor))
        constraints.append(titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor))
        constraints.append(supplementaryButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor))
        constraints.append(supplementaryButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20))
        constraints.append(textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6))
        constraints.append(textField.leftAnchor.constraint(equalTo: titleLabel.leftAnchor))
        previouslyAppliedTextFieldLeftAnchorConstraint.append(textField.rightAnchor.constraint(equalTo: supplementaryButton.leftAnchor, constant: -20))
        constraints.append(dividerView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 1))
        constraints.append(dividerView.leftAnchor.constraint(equalTo: textField.leftAnchor))
        constraints.append(dividerView.rightAnchor.constraint(equalTo: self.rightAnchor))
        constraints.append(dividerView.heightAnchor.constraint(equalToConstant: 0.5))
        NSLayoutConstraint.activate(constraints + previouslyAppliedTextFieldLeftAnchorConstraint)
    }
    
    @objc private func fieldLabelTapped(_ sender: UITapGestureRecognizer) {
        if !textField.isFirstResponder {
            textField.becomeFirstResponder()
        }
    }
    
}
