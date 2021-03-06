//
//  SettingsViewController.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/7/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import UIKit

/// PassWallet's User Settings TableViewController
public class SettingsTableViewController: ClientDependencyViewController, UITableViewDelegate, UITableViewDataSource, SecureCodeEntryViewControllerDelegate
{
    /// MARK: Properties and Constants
    private var pwStyle = PWAppearance.sharedAppearance
    private var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    private var tableViewModelProvider = SettingsViewControllerModelProvider()
    private var userPreferencesService: UserPreferencesServiceInterface!
    private var keychainService: KeychainServiceInterface!
    
    private struct Constants
    {
        static let viewControllerTitle = "Settings"
    }
    
    /// MARK: Public methods
    /// Dependency Injection
    override public func serviceDependencies() -> [Any.Type] {
        return [UserPreferencesServiceInterface.self, KeychainServiceInterface.self]
    }
    
    override public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is UserPreferencesServiceInterface {
                userPreferencesService = dependency as? UserPreferencesServiceInterface
            }
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    override public init() {
        super.init()
        title = Constants.viewControllerTitle
        navigationItem.title = Constants.viewControllerTitle
        tabBarItem = TabBarItemFactory.makeTabBarItem(title: Constants.viewControllerTitle, selectedAppearance: ("SettingsGear Icon Green", pwStyle.appThemeColor), unselectedAppearance: ("SettingsGear Icon Gray", pwStyle.tabBarItemFontColor))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// ViewController lifecycle + layout
    override public func viewDidLoad() {
        configureTableView()
        view.addSubview(tableView)
        setupTableViewConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        super.viewDidLoad()
    }
    
    /// MARK: Secure Code Entry
    public func secureCodeEntryFailed(context: SecureCodeEntryContext) {
        dismissPinEntry(withCompletion: nil)
    }
    
    public func secureCodeEntrySucceeded(context: SecureCodeEntryContext) {
        dismissPinEntry(withCompletion: nil)
    }

    /// MARK: TableViewDelegate + Data Source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3;
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let indexPath = IndexPath(row: 0, section: section)
        guard let numRows = tableViewModelProvider.groupSectionModelForIndexPath(indexPath: indexPath).numRows else {
            return 0
        }
        
        return numRows
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && tableViewModelProvider.groupSectionModelForIndexPath(indexPath: IndexPath(row: 0, section: section)).numRows == 2 {
            let indexPath = IndexPath(row: 0, section: section)
            let sizingLabel = UILabel()
            sizingLabel.font = UIFont.systemFont(ofSize: 13)
            sizingLabel.numberOfLines = 0
            sizingLabel.lineBreakMode = .byWordWrapping
            sizingLabel.text = tableViewModelProvider.groupSectionModelForIndexPath(indexPath: indexPath).footerTitle
            sizingLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude)
            sizingLabel.sizeToFit()
            return sizingLabel.bounds.height + 15
        }
        
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UITableViewHeaderFooterView()
        return footerView
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as? UITableViewHeaderFooterView
        let indexPath = IndexPath(row: 0, section: section)
        headerView?.textLabel?.textColor = pwStyle.appThemeColor
        headerView?.textLabel?.text = tableViewModelProvider.groupSectionModelForIndexPath(indexPath: indexPath).headerTitle
    }
    
    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if section == 0 && tableViewModelProvider.groupSectionModelForIndexPath(indexPath: IndexPath(row: 0, section: section)).numRows == 2 {
            let headerView = view as! UITableViewHeaderFooterView
            let indexPath = IndexPath(row: 0, section: section)
            headerView.textLabel?.font = UIFont.systemFont(ofSize: 13)
            headerView.textLabel?.adjustsFontForContentSizeCategory = true
            headerView.textLabel?.text = tableViewModelProvider.groupSectionModelForIndexPath(indexPath: indexPath).footerTitle
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "SettingsTableViewCell")
            cell?.textLabel?.font = pwStyle.tableViewCellLabelFont
        }
        
        let tableViewCell = cell!
        let cellModel = tableViewModelProvider.cellModelForIndexPath(indexPath: indexPath)
        tableViewCell.textLabel?.text = cellModel.cellTitle
        tableViewCell.accessoryType = .none
        tableViewCell.accessoryView = nil
        tableViewCell.selectionStyle = .default
        configureAccessoryViewForTableViewCell(indexPath: indexPath, tableViewCell: tableViewCell, cellModel: cellModel)
        return tableViewCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                userPreferencesService.restoreStandardPreferences()
                tableView.reloadSections(IndexSet([0, 1]), with: .fade)
            } else if indexPath.row == 1 {
                let alertController = AlertControllerFactory.clearAllItemsAlert(.genericPasswords) { [weak self] (_) in
                    if let strongSelf = self {
                        let currentPassword = PWCredentials().currentPassword
                        let currentSalt = PWCredentials().currentSalt
                        strongSelf.keychainService.clearPasswordKeychainItems()
                        strongSelf.keychainService.clearInternetPasswordKeychainItems()
                        strongSelf.keychainService.clearAllKeychainItems()
                        PWCredentials().update(password: currentPassword!, salt: currentSalt!)
                        let currentItemStoreType = WalletItemStore.shared.itemType
                        WalletItemStore.shared.itemType = .genericPasswords
                        let _ = WalletItemStore.shared.clear()
                        WalletItemStore.shared.itemType = .webPasswords
                        let _ = WalletItemStore.shared.clear()
                        WalletItemStore.shared.itemType = .mobileAppPasswords
                        let _ = WalletItemStore.shared.clear()
                        WalletItemStore.shared.itemType = currentItemStoreType
                        NotificationCenter.default.post(Notification(name: Notification.Name.init("walletItemsChangedNotification")))
                    }
                }
                self.present(alertController, animated: true, completion: nil)
            } else {
                let alertController = AlertControllerFactory.clearAllItemsAlert(.secureNotes) { [weak self] (_) in
                    if let _ = self {
                        let currentItemStoreType = WalletItemStore.shared.itemType
                        WalletItemStore.shared.itemType = .secureNotes
                        let _ = WalletItemStore.shared.clear()
                        WalletItemStore.shared.itemType = currentItemStoreType
                        NotificationCenter.default.post(Notification(name: Notification.Name.init("walletItemsChangedNotification")))
                    }
                }
                self.present(alertController, animated: true, completion: nil)
            }
        } else if indexPath.section == 0 {
            if indexPath.row == 0 {
                present(SecureCodeEntryViewController.navigationController(context: .changeSecureCode, secureCodeEntryType: .pin, secureCodeEntryLength: .fourDigitCode, delegate: self), animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    /// MARK: Helpers
    private func configureTableView()
    {
        tableView.rowHeight = 45
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.01))
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.bounces = true
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

    private func configureAccessoryViewForTableViewCell(indexPath: IndexPath,
                                                        tableViewCell: UITableViewCell,
                                                        cellModel: SettingsTableViewCellModel)
    {
        let accessoryAttributes = cellModel.accessoryViewAttributes
        let accessoryViewType = (accessoryAttributes?[kAccessoryViewTypeAttribute] as? SettingsCellAccessoryViewType)
        
        if accessoryViewType == SettingsCellAccessoryViewType.navigationArrow {
            tableViewCell.accessoryType = .disclosureIndicator
        } else if accessoryViewType == SettingsCellAccessoryViewType.switchControl {
            let switchControl = UISwitch()
            switchControl.onTintColor = pwStyle.appThemeColor
            if let switchEnabled = accessoryAttributes?[kSwitchEnabledAttribute] {
                switchControl.setOn(switchEnabled as! Bool, animated: false)
            }
            tableViewCell.accessoryView = switchControl
            tableViewCell.selectionStyle = .none
            bindTargetResponderForSwitch(switchControl: switchControl, indexPath: indexPath)
        } else if accessoryViewType == SettingsCellAccessoryViewType.segmentedControl {
            guard let selectedSegmentIndex = (accessoryAttributes?[kSelectedSegmentIndexAttribute] as! Int?), let segmentTitles = (accessoryAttributes?[kSegmentTitlesAttribute] as! [Any]?) else {
                return
            }
            let segmentedControl = UISegmentedControl(items: segmentTitles)
            segmentedControl.tintColor = pwStyle.appThemeColor
            segmentedControl.selectedSegmentIndex = selectedSegmentIndex
            tableViewCell.accessoryView = segmentedControl
            tableViewCell.selectionStyle = .none
            segmentedControl.addTarget(self, action: #selector(autoLockSegmentedControlValueDidChange(_:)), for: .valueChanged)
        }
        
    }
    
    private func bindTargetResponderForSwitch(switchControl: UISwitch, indexPath: IndexPath)
    {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                //2FA
                switchControl.addTarget(self, action: #selector(_2FASwitchControlValueDidChange(_:)), for: .valueChanged)
                return
            }
        }
        
        //Lock on exit
        switchControl.addTarget(self, action: #selector(lockOnExitSwitchControlValueDidChange(_:)), for: .valueChanged)
    }
    
    @objc private func autoLockSegmentedControlValueDidChange(_ segmentedControl: UISegmentedControl)
    {
        if segmentedControl.selectedSegmentIndex == 0 {
        userPreferencesService.updateAutoLockTimeout(timeout: .thirtySeconds)
        } else {
            userPreferencesService.updateAutoLockTimeout(timeout: .twoMinutes)
        }
    }
    
    
    @objc private func _2FASwitchControlValueDidChange(_ switchControl: UISwitch)
    {
        userPreferencesService.update2FAStatus(enabled: switchControl.isOn)
    }
    
    @objc private func lockOnExitSwitchControlValueDidChange(_ switchControl: UISwitch)
    {
        userPreferencesService.updateShouldLockOnExitStatus(enabled: switchControl.isOn)
    }
    
    @objc private func willEnterForeground()
    {
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    private func dismissPinEntry(withCompletion: (() -> Void)?)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.dismiss(animated: true, completion: withCompletion)
        }
    }

}

