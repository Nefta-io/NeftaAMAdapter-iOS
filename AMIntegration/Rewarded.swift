//
//  Rewarded.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Rewarded : NSObject, GADFullScreenContentDelegate {
    
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/3090611193"
    
    private var _rewarded: GADRewardedAd!
    private var _usedInsight: AdInsight?
    private var _isLoading = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._rewarded
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }
        let adUnitToLoad = selectedAdUnitId
        
        SetInfo("Loading Rewarded \(adUnitToLoad)")
        Task {
            do {
                _rewarded = try await GADRewardedAd.load(withAdUnitID: adUnitToLoad, request: GADRequest())
                _rewarded!.paidEventHandler = onPaid
                _rewarded!.fullScreenContentDelegate = self
                
                GADNeftaAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, usedInsight: _usedInsight)
                
                DispatchQueue.main.async {
                    self.SetInfo("Loaded Rewarded \(adUnitToLoad)")
                    
                    self.SetLoadingButton(isLoading: false)
                    self._loadButton.isEnabled = false
                    self._showButton.isEnabled = true
                }
            } catch {
                GADNeftaAdapter.onExternalMediationRequestFail(.rewarded, adUnitId: adUnitToLoad, usedInsight: _usedInsight, error: error)
                
                DispatchQueue.main.async {
                    self.SetInfo("Failed to load Rewarded \(adUnitToLoad) with error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if self._isLoading {
                            self.GetInsightsAndLoad()
                        }
                    }
                }
            }
        }
    }
    
    func onPaid(adValue: GADAdValue) {
        GADNeftaAdapter.onExternalMediationImpression(withRewarded: _rewarded, adValue: adValue)
        
        SetInfo("onPaid \(adValue)")
    }

    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func OnLoadClick() {
        if _isLoading {
            SetLoadingButton(isLoading: false)
        } else {
            SetInfo("GetInsightsAndLoad...")
            GetInsightsAndLoad()
            SetLoadingButton(isLoading: true)
        }
    }
    
    @objc func OnShowClick() {
        _rewarded.present(fromRootViewController: _viewController) {
            let reward = self._rewarded.adReward
            self.SetInfo("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
        }
        
        _loadButton.isEnabled = true
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
    
    private func SetLoadingButton(isLoading: Bool) {
        _isLoading = isLoading
        if isLoading {
            _loadButton.setTitle("Cancel", for: .normal)
        } else {
            _loadButton.setTitle("Load Rewarded", for: .normal)
        }
    }
}
