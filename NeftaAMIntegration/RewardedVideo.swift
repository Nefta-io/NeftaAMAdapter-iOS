//
//  RewardedVideo.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class RewardedVideo : NSObject, GADFullScreenContentDelegate {
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    
    var _rewarded: GADRewardedAd!

    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func Load() {
        self.SetInfo("Started loading rewarded ad loaded")
        Task {
            do {
                _rewarded = try await GADRewardedAd.load(withAdUnitID: "ca-app-pub-1193175835908241/3090611193", request: GADRequest())
                _rewarded?.fullScreenContentDelegate = self
                
                DispatchQueue.main.async {
                    self.SetInfo("Rewarded ad loaded")
                    self._showButton.isEnabled = true
                }
            } catch {
                SetInfo("Rewarded ad failed to load with error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func Show() {
        _rewarded.present(fromRootViewController: _viewController) {
            let reward = self._rewarded.adReward
            self.SetInfo("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
        }
        
        _showButton.isEnabled = false
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        SetInfo("Rewarded Ad did fail to present full screen content.")
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("Rewarded Ad will present full screen content.")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("Rewarded Ad did dismiss full screen content.")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
