//
//  PinEntryTextField.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/17/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public protocol PinEntryTextFieldDelegate : class
{
    func pinEntryTextFieldTextDidChange(_ pinEntryTextField: PinEntryTextField)
    func pinEntryTextFieldShouldEndEditing(_ pinEntryTextField: PinEntryTextField) -> Bool
    func pinEntryTextFieldShouldClearTextField(_ pinEntryTextField: PinEntryTextField) -> Bool
}

/**
 * PinEntryTextField is a custom UIView that displays an editable text area to collect
 * secure digits such as a user entered pin or passcode. PinEntryTextField is stylized for
 * secure code entry but is setup to behave just like UIKit's native UITextField, send 
 * PinEntryTextField the standard becomeFirstResponder() messages to have it launch the keyboard 
 * and process keyboard input. 
 *
 * Please adhere to the PinEntryTextFieldDelegate protocol and set the delegate to respond to
 * changes that occur during and after editing.
 */
public class PinEntryTextField : UIView, UIKeyInput
{
    private var pinDigitViews = [PinDigitView]()
    private var secureCodeLength: SecureCodeEntryLength = .fourDigitCode
    private var color: UIColor = UIColor.black
    
    private var pinDigitWidth: CGFloat = 0
    private let pinDigitSpacing: CGFloat = 25
    
    public private(set) var text: String = ""
    public weak var delegate: PinEntryTextFieldDelegate? = nil
    
    public var keyboardType: UIKeyboardType {
        
        get {
            return .numberPad
        }
        
        set { }
    }
    
    public var hasText: Bool {
        return !text.isEmpty
    }
    
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    public override var canResignFirstResponder: Bool {
        return true
    }
    
    // The intrinsic content size of the textField which is derived from the leaf PinDigitViews
    public override var intrinsicContentSize: CGSize {
        let pinDigitWidth = PinDigitView().intrinsicContentSize.width
        let pinDigitHeight = pinDigitWidth
        let textFieldWidth = (pinDigitWidth * secureCodeLength.toCGFloat()) + (pinDigitSpacing * (secureCodeLength.toCGFloat() - 1))
        return CGSize(width: textFieldWidth, height: pinDigitHeight)
    }
    
    public init(frame: CGRect, pinEntryLength: SecureCodeEntryLength, color: UIColor) {
        super.init(frame: frame)
        self.secureCodeLength = pinEntryLength
        self.color = color
        self.backgroundColor = UIColor.clear
        
        for _ in 0..<secureCodeLength.toInt() {
            let pinDigitView = PinDigitView()
            pinDigitViews.append(pinDigitView)
            self.addSubview(pinDigitView)
        }
        
        self.pinDigitWidth = PinDigitView().intrinsicContentSize.width
        setupConstraints()
    }
    
    override public convenience init(frame: CGRect) {
        self.init(frame: frame, pinEntryLength: .fourDigitCode, color: UIColor.black)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints()
    {
        let constraint = PWConstraint()
        PWConstraint.disableAutoresize(forViews: pinDigitViews)
        
        let isEven = ((pinDigitViews.count % 2) == 0)
        let constantOffset = (isEven) ? (-(pinDigitSpacing / 2 + pinDigitWidth / 2)) : 0
        let midPinDigitIndex = ((pinDigitViews.count - 1)/2)
        let midPinDigitView = pinDigitViews[((pinDigitViews.count - 1)/2)]
        constraint.addConstraint( midPinDigitView.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        constraint.addConstraint( midPinDigitView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: constantOffset))
        
        for i in 0..<pinDigitViews.count {
            guard i != midPinDigitIndex else {
                continue
            }
            constraint.addConstraint( pinDigitViews[i].centerYAnchor.constraint(equalTo: midPinDigitView.centerYAnchor))
        }
        
        //handle left pin digit views
        var index = midPinDigitIndex - 1
        while (index > -1) {
            constraint.addConstraint( pinDigitViews[index].rightAnchor.constraint(equalTo: pinDigitViews[index+1].leftAnchor, constant: -pinDigitSpacing))
            index = index - 1
        }
        
        //handle right pin digit views
        index = midPinDigitIndex + 1
        while (index < pinDigitViews.count) {
            constraint.addConstraint( pinDigitViews[index].leftAnchor.constraint(equalTo: pinDigitViews[index-1].rightAnchor, constant: pinDigitSpacing))
            index = index + 1
        }
        
        NSLayoutConstraint.activate(constraint.constraints)
    }
    
    public func insertText(_ text: String) {
        self.text.append(text)
        updatePinDigitViews(withContext: .pinDigitCollected)
        delegate?.pinEntryTextFieldTextDidChange(self)
        if self.text.characters.count == secureCodeLength.toInt() {
            if let delegateImplementer = delegate {
                if delegateImplementer.pinEntryTextFieldShouldEndEditing(self) {
                    self.resignFirstResponder()
                    
                }
                if delegateImplementer.pinEntryTextFieldShouldClearTextField(self) {
                    clear()
                }
            }
        }
    }
    
    public func deleteBackward() {
        if text.characters.count > 0 {
            updatePinDigitViews(withContext: .pinDigitEmpty)
            text.remove(at: text.index(before: text.endIndex))
            delegate?.pinEntryTextFieldTextDidChange(self)
        }
    }
    
    public func clear() {
        text = ""
        updateAllPinDigitViews(withContext: .pinDigitEmpty)
    }
    
    private func updatePinDigitViews(withContext: PinDigitContext) {
        let pinDigitViewIndex = text.characters.count - 1
        if pinDigitViewIndex < pinDigitViews.count {
            pinDigitViews[pinDigitViewIndex].context = withContext
        }
    }
    
    private func updateAllPinDigitViews(withContext: PinDigitContext) {
        for pinDigitView in pinDigitViews {
            pinDigitView.context = withContext
        }
    }
}
