//
//  ViewController.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import UIKit
import NeftaSDK
import GoogleMobileAds

class ViewController: UIViewController {

    private var _interstitial: Interstitial!
    private var _rewarded: Rewarded!
    
    private var _plugin: NeftaPlugin!
    
    @IBOutlet weak var _loadInterstitial: UISwitch!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UISwitch!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    @IBOutlet weak var _impressionStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        NeftaPlugin.EnableLogging(enable: true)
        NeftaPlugin.SetExtraParameter(key: NeftaPlugin.ExtParam_TestGroup, value: "split-am")
        _plugin = NeftaPlugin.Init(appId: "5731414989340672")
        
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "87b6abe09a8764496b8c5d1c1b4ac23d",
            "284dcf66160f8ea305826b4cc2abe58e",
            "b78b6e076ab7de99a8eb15adb2ab2634"
        ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.maxAdContentRating = .teen
        
        _title.text = "Nefta Adapter for AdMob"
        _interstitial = Interstitial(loadSwitch: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewarded = Rewarded(loadSwitch: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
    }
}

