//
//  ExpandedTapAreaButton.swift
//  PassWallet
//
//  Created by Abhay Curam on 11/18/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class ExpandedTapAreaButton: UIButton
{
    public var expandedTapAreaEdgeInsets: UIEdgeInsets
    
    public init(expandedTapAreaEdgeInsets: UIEdgeInsets, frame: CGRect) {
        self.expandedTapAreaEdgeInsets  = expandedTapAreaEdgeInsets
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newX = bounds.origin.x - expandedTapAreaEdgeInsets.left
        let newY = bounds.origin.y - expandedTapAreaEdgeInsets.top
        let expandedHeight = bounds.height + expandedTapAreaEdgeInsets.top + expandedTapAreaEdgeInsets.bottom
        let expandedWidth = bounds.width + expandedTapAreaEdgeInsets.left + expandedTapAreaEdgeInsets.right
        let expandedAreaRect = CGRect(x: newX, y: newY, width: expandedWidth, height: expandedHeight)
        return expandedAreaRect.contains(point)
    }
}
