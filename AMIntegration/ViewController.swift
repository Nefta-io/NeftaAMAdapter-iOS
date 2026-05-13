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
    
    public var _log = Logger(subsystem: "com.nefta.am", category: "general")
    
    @IBOutlet weak var _title: UILabel!
    
    @IBOutlet weak var _groupView: UIView!
    @IBOutlet weak var _controlButton: UIButton!
    @IBOutlet weak var _optimizedButton: UIButton!
    @IBOutlet weak var _simulatorButton: UIButton!
    
    @IBOutlet weak var _interstitialUi: InterstitialUi!
    @IBOutlet weak var _rewardedUi: RewardedUi!
    @IBOutlet weak var _interstitialSim: InterstitialSim!
    @IBOutlet weak var _rewardedSim: RewardedSim!
    
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
        _title!.text = "AdMob \(GADMobileAds.sharedInstance().versionNumber.majorVersion)"
        
        _controlButton.addTarget(self, action: #selector(OnControlClick), for: .touchUpInside)
        _optimizedButton.addTarget(self, action: #selector(OnOptimizedClick), for: .touchUpInside)
        _simulatorButton.addTarget(self, action: #selector(OnSimulatorClick), for: .touchUpInside)
    }
    
    @objc func OnControlClick() {
        _groupView.isHidden = true
        
        _interstitialUi.Init(logic: InterstitialDefault(), viewController: self)
        _rewardedUi.Init(logic: RewardedDefault(), viewController: self)
    }
    
    @objc func OnOptimizedClick() {
        _groupView.isHidden = true
        
        _interstitialUi.Init(logic: InterstitialOptimized(), viewController: self)
        _rewardedUi.Init(logic: RewardedOptimized(), viewController: self)
    }
    
    @objc func OnSimulatorClick() {
        _groupView.isHidden = true
        
        _interstitialSim.Init(viewController: self)
        _rewardedSim.Init(viewController: self)
    }
}
