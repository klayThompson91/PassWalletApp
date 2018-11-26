//
//  WalletItemMenuViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 9/9/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import UIKit

public class WalletItemMenuViewController : UIViewController, UITableViewDelegate, UITableViewDataSource
{
    /// MARK: Properties and Constants
    private var pwStyle = PWAppearance.sharedAppearance
    private var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    
    private struct Constants
    {
        static let title = "Wallet"
        static let cellReuseId = "PasswordType-Cell"
        static let cellOneTitle = "Web Passwords"
        static let cellTwoTitle = "Mobile Passwords"
        static let cellThreeTitle = "Generic Passwords"
        static let cellFourTitle = "Secure Notes"
        static let sectionHeader = "PASSWORD TYPES"
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        title = Constants.title
        navigationItem.title = Constants.title
        let backButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        tabBarItem = TabBarItemFactory.makeTabBarItem(title: Constants.title, selectedAppearance: ("PassWallet Icon Green", pwStyle.appThemeColor), unselectedAppearance: ("PassWallet Icon Gray", pwStyle.tabBarItemFontColor))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// ViewController lifecycle + layout
    override public func viewDidLoad() {
        configureTableView()
        view.addSubview(tableView)
        setupTableViewConstraints()
        super.viewDidLoad()
    }
    
    /// MARK: Helpers
    private func configureTableView()
    {
        tableView.rowHeight = 45
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor = pwStyle.tableViewBackgroundColor
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupTableViewConstraints()
    {
        let constraint = PWConstraint()
        PWConstraint.disableAutoresize(forView: tableView)
        constraint.addConstraint( tableView.leftAnchor.constraint(equalTo: view.leftAnchor))
        constraint.addConstraint( tableView.rightAnchor.constraint(equalTo: view.rightAnchor))
        constraint.addConstraint( tableView.topAnchor.constraint(equalTo: view.topAnchor))
        constraint.addConstraint( tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        NSLayoutConstraint.activate(constraint.constraints)
    }
    
    /// MARK: TableViewDelegate + Data Source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseId)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: Constants.cellReuseId)
            cell?.textLabel?.font = pwStyle.tableViewCellLabelFont
        }
        
        if let tableViewCell = cell {
            if indexPath.row == 0 {
                tableViewCell.textLabel?.text = Constants.cellOneTitle
            } else if indexPath.row == 1 {
                tableViewCell.textLabel?.text = Constants.cellTwoTitle
            } else if indexPath.row == 2 {
                tableViewCell.textLabel?.text = Constants.cellThreeTitle
            } else {
                tableViewCell.textLabel?.text = Constants.cellFourTitle
            }
            
            
            tableViewCell.accessoryType = .disclosureIndicator
            tableViewCell.accessoryView = nil
            tableViewCell.selectionStyle = .default
            return tableViewCell
        }
    
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let walletItemType = WalletItemType(rawValue: indexPath.row) else {
            return
        }
        navigationController?.pushViewController(WalletItemListViewController(walletItemType: walletItemType), animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as? UITableViewHeaderFooterView
        headerView?.textLabel?.textColor = pwStyle.appThemeColor
        headerView?.textLabel?.text = Constants.sectionHeader
    }
    
}
