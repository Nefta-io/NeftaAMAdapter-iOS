//
//  ViewController.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import UIKit
import NeftaSDK
import GoogleMobileAds
import OSLog

class ViewController: UIViewController {
    
    public static var _log = Logger(subsystem: "com.nefta.am", category: "general")
    
    private var _isSimulator = false
    private var _plugin: NeftaPlugin!
    
    @IBOutlet weak var _titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        InitializeUI()
        //DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        GADNeftaAdapter.Init(appId: "5731414989340672", onReady: { initConfig in
            print("[NeftaPluginAM] Should skip Nefta optimization: \(initConfig._skipOptimization) for: \(initConfig._nuid)")
        })
        
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "87b6abe09a8764496b8c5d1c1b4ac23d",
            "284dcf66160f8ea305826b4cc2abe58e",
            "b78b6e076ab7de99a8eb15adb2ab2634"
        ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.maxAdContentRating = .teen
    }
    
    private func InitializeUI() {
        _titleLabel.text = "AdMob \(GADMobileAds.sharedInstance().versionNumber.majorVersion)"
        let onClickHandler = UITapGestureRecognizer(target: self, action: #selector(onTitleClick))
        _titleLabel!.isUserInteractionEnabled = true
        _titleLabel!.addGestureRecognizer(onClickHandler)
        
        var isSimulator: Bool = false
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            isSimulator = dict["IS_SIMULATOR"] as? Bool ?? false
        }
        ToggleUI(isSimulator: isSimulator)
    }
    
    @objc func onTitleClick() {
        ToggleUI(isSimulator: !_isSimulator)
    }
    
    private func ToggleUI(isSimulator: Bool) {
        _isSimulator = isSimulator
        
        (view.viewWithTag(11) as! InterstitialSim).isHidden = !isSimulator
        (view.viewWithTag(12) as! RewardedSim).isHidden = !isSimulator
        
        (view.viewWithTag(13) as! Interstitial).isHidden = isSimulator
        (view.viewWithTag(14) as! Rewarded).isHidden = isSimulator
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
