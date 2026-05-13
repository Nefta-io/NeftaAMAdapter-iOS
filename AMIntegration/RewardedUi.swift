//
//  Rewarded.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class RewardedUi : UIView {
    
    public static let AdUnitA = "ca-app-pub-1193175835908241/3090611193"
    public static let AdUnitB = "ca-app-pub-1193175835908241/3556677953"
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    private var _viewController: UIViewController!
    
    private var _logic : Rewarded!
    
    public var IsAutoLoad: Bool = false
    public var ViewController: ViewController!
    
    public func Init(logic: Rewarded, viewController: ViewController) {
        _logic = logic
        _logic.Init(ui: self)
        
        ViewController = viewController
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        isHidden = false
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        IsAutoLoad = sender.isOn
        if IsAutoLoad {
            _logic.Load()
        }
    }
    
    public func SetAvailable(available: Bool) {
        _showButton.isEnabled = available
    }
    
    @objc private func OnShowClick() {
        _logic.Show()
    }
    
    public func Log(_ log: String) {
        _status.text = log
        ViewController._log.notice("Rewarded: \(log, privacy: .public)")
    }
}
