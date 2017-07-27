//
//  PinDigitView.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/5/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public enum PinDigitContext
{
    case pinDigitEmpty
    case pinDigitCollected
}

public class PinDigitView : UIView
{
    private var _pinDigitColor: UIColor = UIColor.black
    private var _pinDigitContext: PinDigitContext = .pinDigitEmpty
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
    
    public var context: PinDigitContext {
        set {
            if newValue != _pinDigitContext {
                _pinDigitContext = newValue
                setNeedsDisplay()
            }
        }
        get {
            return _pinDigitContext
        }
    }
    
    public var color: UIColor {
        set {
            if newValue != _pinDigitColor {
                _pinDigitColor = newValue
                setNeedsDisplay()
            }
        }
        get {
            return _pinDigitColor
        }
    }
    
    public init(frame: CGRect, context: PinDigitContext, color: UIColor) {
        super.init(frame: frame)
        self.context = context
        self.color = color
        self.backgroundColor = UIColor.clear
    }
    
    override public convenience init(frame: CGRect) {
        self.init(frame: frame, context: .pinDigitEmpty, color: UIColor.black)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func draw(_ rect: CGRect) {
        self.color.set()
        if context == .pinDigitEmpty {
            let path = UIBezierPath()
            let startPoint = CGPoint(x: rect.minX, y: rect.midY)
            let endPoint = CGPoint(x: rect.maxX, y: rect.midY)
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            path.lineWidth = (rect.height / 7)
            path.stroke()
        } else {
            let radius = (rect.height <= rect.width) ? (rect.height / 2) : (rect.width / 2)
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            circlePath.fill()
        }
    }
    
}
