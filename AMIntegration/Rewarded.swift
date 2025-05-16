//
//  RewardedVideo.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Rewarded : NSObject, GADFullScreenContentDelegate {
    
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/3090611193"
    
    private let AdUnitIdInsightName = "recommended_rewarded_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_rewarded"
    
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    
    private var _rewarded: GADRewardedAd!
    
    private func GetInsightsAndLoad() {
        _isLoadRequested = true
        
        NeftaPlugin._instance.GetBehaviourInsight([AdUnitIdInsightName, FloorPriceInsightName], callback: OnBehaviourInsight)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._isLoadRequested {
                self._recommendedAdUnitId = nil
                self._calculatedBidFloor = 0
                self.Load()
            }
        }
    }
    
    func OnBehaviourInsight(insights: [String: Insight]) {
        _recommendedAdUnitId = nil
        _calculatedBidFloor = 0
        if let recommendedAdUnitInsight = insights[AdUnitIdInsightName] {
            _recommendedAdUnitId = recommendedAdUnitInsight._string
        }
        if let floorPriceInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = floorPriceInsight._float
        }
        
        print("OnBehaviourInsight for Rewarded recommended AdUnit: \(String(describing: _recommendedAdUnitId)) calculated bid floor:\(_calculatedBidFloor)")

        if _isLoadRequested {
            Load()
        }
    }
    
    private func Load() {
        _isLoadRequested = false
        
        var adUnitId = DefaultAdUnitId
        if let _recommendedAdUnitId = _recommendedAdUnitId {
            adUnitId = _recommendedAdUnitId
        }
        
        Task {
            do {
                _rewarded = try await GADRewardedAd.load(withAdUnitID: adUnitId, request: GADRequest())
                _rewarded!.paidEventHandler = onPaid
                _rewarded!.fullScreenContentDelegate = self
                
                DispatchQueue.main.async {
                    NeftaAdapter.onExternalMediationRequestLoad(AdType.rewarded, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._rewarded.adUnitID)
                    
                    self.SetInfo("Rewarded ad loaded")
                    self._showButton.isEnabled = true
                }
            } catch {
                DispatchQueue.main.async {
                    NeftaAdapter.onExternalMediationRequestFail(AdType.rewarded, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._rewarded.adUnitID, error: error)
                    
                    self.SetInfo("Rewarded ad failed to load with error: \(error.localizedDescription)")
                }
            }
        }
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
        GetInsightsAndLoad()
    }
    
    @objc func OnShowClick() {
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
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(adValue)
        
        SetInfo("onPaid \(adValue)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
