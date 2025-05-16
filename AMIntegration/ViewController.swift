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

    private var _banner: Banner!
    private var _interstitial: Interstitial!
    private var _rewarded: Rewarded!
    
    private var _plugin: NeftaPlugin!
    
    @IBOutlet weak var _bannerPlaceholder: UIView!
    @IBOutlet weak var _showBanner: UIButton!
    @IBOutlet weak var _hideBanner: UIButton!
    @IBOutlet weak var _loadInterstitial: UIButton!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UIButton!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _bannerStatus: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    @IBOutlet weak var _impressionStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NeftaPlugin.EnableLogging(enable: true)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        _plugin = NeftaPlugin.Init(appId: "5661184053215232")
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.maxAdContentRating = .teen
        
        _title.text = "Nefta Adapter for AdMob"
        _banner = Banner(showButton: _showBanner, hideButton: _hideBanner, status: _bannerStatus, viewController: self, bannerPlaceholder: _bannerPlaceholder)
        _interstitial = Interstitial(loadButton: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewarded = Rewarded(loadButton: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
    }
}

