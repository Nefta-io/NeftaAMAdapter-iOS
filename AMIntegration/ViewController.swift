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

    var _banner: Banner!
    var _interstitial: Interstitial!
    var _rewardedVideo: RewardedVideo!
    
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

        _ = NeftaPlugin.Init(appId: "5661184053215232")
        NeftaPlugin.EnableLogging(enable: true)
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        _title.text = "Nefta Adapter for AdMob"
        _banner = Banner(showButton: _showBanner, hideButton: _hideBanner, status: _bannerStatus, viewController: self, bannerPlaceholder: _bannerPlaceholder)
        _interstitial = Interstitial(loadButton: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewardedVideo = RewardedVideo(loadButton: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
    }
}

