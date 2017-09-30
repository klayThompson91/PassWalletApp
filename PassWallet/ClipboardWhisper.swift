//
//  ClipboardWhisper.swift
//  PassWallet
//
//  Created by Abhay Curam on 9/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import UIKit
import Whisper

public class ClipboardWhisper
{
    public class func showCopiedMessage(for navigationController: UINavigationController)
    {
        let message = Message(title: "Copied to clipboard!", backgroundColor: PWAppearance.sharedAppearance.appThemeColor)
        Whisper.show(whisper: message, to: navigationController, action: .show)
    }
}
