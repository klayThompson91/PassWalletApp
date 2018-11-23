//
//  EditablePasswordCardView.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class EditablePasswordCardViewAttributes {
    
    public var numberOfFieldSections = 3
    public var containsMultiLineSection = false
    
    public class func secureNote() -> EditablePasswordCardViewAttributes {
        let attributes = EditablePasswordCardViewAttributes()
        attributes.numberOfFieldSections = 2
        attributes.containsMultiLineSection = true
        return attributes
    }

}

public protocol EditablePasswordCardViewDelegate: class {
    func supplementaryButtonWasTapped(_ supplementaryButton: UIButton, for fieldSectionIndex: Int)
    func fieldSectionTextFieldsTextDidChange(_ textFields: [UITextField])
}

public class EditablePasswordCardView: CardView {
    
    public override var intrinsicContentSize: CGSize {
        let spacingPadding: CGFloat = 20
        var intrinsicHeight: CGFloat = spacingPadding
        intrinsicHeight += iconImageView.intrinsicContentSize.height + spacingPadding
        var didLayOutFieldSections = false
        if let fields = fieldSections {
            for field in fields {
                intrinsicHeight += field.intrinsicContentSize.height + spacingPadding
                if !didLayOutFieldSections { didLayOutFieldSections = true }
            }
        }
        if let multiLineField = multiLineSection {
            let multiLinePadding = (didLayOutFieldSections) ? (spacingPadding * 2) : (spacingPadding)
            intrinsicHeight += multiLineField.intrinsicContentSize.height + multiLinePadding
        }
        
        return CGSize(width: UIViewNoIntrinsicMetric, height: intrinsicHeight)
    }
    
    private var _isEditable = true
    public var isEditable: Bool {
        
        get {
            return _isEditable
        }
        
        set {
            if (_isEditable != newValue) {
                _isEditable = newValue
                updateFieldsForEditing()
                if _isEditable {
                    notifyDelegateTextFieldsDidChange()
                }
            }
        }
    }
    
    public weak var delegate: EditablePasswordCardViewDelegate?
    public private(set) var iconImageView = UIImageView(frame: .zero)
    public private(set) var fieldSections: [EditableFieldSectionView]?
    public private(set) var multiLineSection: EditableMultiLineSectionView?
    
    private var attributes = EditablePasswordCardViewAttributes()
    
    public override convenience init(frame: CGRect) {
        self.init(frame: frame, attributes: EditablePasswordCardViewAttributes())
    }
    
    public init(frame: CGRect, attributes: EditablePasswordCardViewAttributes) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.attributes = attributes
        
        if self.attributes.numberOfFieldSections > 0 {
            fieldSections = [EditableFieldSectionView]()
            for i in 0..<self.attributes.numberOfFieldSections {
                fieldSections?.append(EditableFieldSectionView(frame: .zero))
                addSubview((fieldSections?[i])!)
            }
            for i in 0..<fieldSections!.count {
                let fieldSection = fieldSections?[i]
                fieldSection?.textField.addTarget(self, action: #selector(fieldSectionTextDidChange(_:)), for: .editingChanged)
                if i == 0 {
                    fieldSection?.supplementaryCopyButton.addTarget(self, action: #selector(firstFieldSectionSupplementaryButtonPressed(_:)), for: .touchUpInside)
                } else if i == 1 {
                    fieldSection?.supplementaryCopyButton.addTarget(self, action: #selector(secondFieldSectionSupplementaryButtonPressed(_:)), for: .touchUpInside)
                } else if i == 2 {
                    fieldSection?.supplementaryCopyButton.addTarget(self, action: #selector(thirdFieldSectionSupplementaryButtonPressed(_:)), for: .touchUpInside)
                    break
                }
            }
        }
        
        if self.attributes.containsMultiLineSection {
            multiLineSection = EditableMultiLineSectionView(frame: .zero)
            addSubview(multiLineSection!)
        }
        
        addSubview(iconImageView)
        setupConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func securePasswordFieldIfApplicable(_ shouldSecure: Bool) {
        if let fields = fieldSections {
            if fields.count >= 3 {
                fields[2].textField.isSecureTextEntry = shouldSecure
            }
        }
    }
    
    private func setupConstraints() {
        var constraints = [NSLayoutConstraint]()
        disableAutoresizeMasksForViews()
        constraints += constraintsForIconImageView()
        constraints += constraintsForFieldSections()
        constraints += constraintsForMultiLineFieldSection()
        NSLayoutConstraint.activate(constraints)
    }
    
    private func disableAutoresizeMasksForViews() {
        var viewsToDisable = [UIView]()
        viewsToDisable.append(iconImageView)
        if let fields = fieldSections {
            viewsToDisable = viewsToDisable + fields
        }
        if let multiLineField = multiLineSection {
            viewsToDisable.append(multiLineField)
        }
        PWConstraint.disableAutoresize(forViews: viewsToDisable)
    }
    
    private func constraintsForIconImageView() -> [NSLayoutConstraint] {
        return [iconImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                iconImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20)]
    }
    
    private func constraintsForFieldSections() -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        if let fields = fieldSections {
            constraints += constraintsByPinning(fields[0], under: iconImageView)
            for i in 1..<fields.count {
                constraints += constraintsByPinning(fields[i], under: fields[i-1])
            }
        }
        return constraints
    }
    
    private func constraintsForMultiLineFieldSection() -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        if let multiLineField = multiLineSection {
            if let fields = fieldSections {
                constraints += constraintsByPinning(multiLineField, under: fields[fields.count - 1])
            } else {
                constraints += constraintsByPinning(multiLineField, under: iconImageView)
            }
        }
        return constraints
    }
    
    private func constraintsByPinning(_ fieldView: UIView, under iconImageView: UIImageView) -> [NSLayoutConstraint] {
        return [fieldView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
                fieldView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
                fieldView.rightAnchor.constraint(equalTo: self.rightAnchor)]
    }
    
    private func constraintsByPinning(_ childFieldView: UIView, under parentFieldView: UIView) -> [NSLayoutConstraint] {
        return [childFieldView.topAnchor.constraint(equalTo: parentFieldView.bottomAnchor, constant: 25),
                childFieldView.leftAnchor.constraint(equalTo: parentFieldView.leftAnchor),
                childFieldView.rightAnchor.constraint(equalTo: parentFieldView.rightAnchor)]
    }
    
    private func updateFieldsForEditing() {
        if let sections = fieldSections {
            for i in 0..<sections.count {
                let fieldSection = sections[i]
                fieldSection.textField.isUserInteractionEnabled = isEditable
            }
            for fieldSection in sections {
                fieldSection.textField.isUserInteractionEnabled = isEditable
            }
        }
        if let multiSection = multiLineSection {
            multiSection.textView.isEditable = isEditable
        }
    }
    
    @objc private func fieldSectionTextDidChange(_ sender: UITextField) {
        notifyDelegateTextFieldsDidChange()
    }
    
    @objc private func firstFieldSectionSupplementaryButtonPressed(_ sender: UIButton) {
        notifyDelegateSupplementaryButtonWasTapped(sender, for: 0)
    }
    
    @objc private func secondFieldSectionSupplementaryButtonPressed(_ sender: UIButton) {
        notifyDelegateSupplementaryButtonWasTapped(sender, for: 1)
    }
    
    @objc private func thirdFieldSectionSupplementaryButtonPressed(_ sender: UIButton) {
        notifyDelegateSupplementaryButtonWasTapped(sender, for: 2)
    }
    
    private func notifyDelegateSupplementaryButtonWasTapped(_ sender: UIButton, for fieldSectionIndex: Int) {
        if let unwrappedDelegate = delegate {
            unwrappedDelegate.supplementaryButtonWasTapped(sender, for: fieldSectionIndex)
        }
    }
    
    private func notifyDelegateTextFieldsDidChange() {
        if let unwrappedDelegate = delegate, let sections = fieldSections {
            unwrappedDelegate.fieldSectionTextFieldsTextDidChange(sections.map{$0.textField})
        }
    }
}
