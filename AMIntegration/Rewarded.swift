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
    
    private var _rewarded: GADRewardedAd!
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    private var _loadedAdUnitId: String? = nil
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    
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
        
        print("OnBehaviourInsight for Rewarded: \(String(describing: _recommendedAdUnitId)) calculated bid floor:\(_calculatedBidFloor)")

        if _isLoadRequested {
            Load()
        }
    }
    
    private func Load() {
        _isLoadRequested = false
        
        _loadedAdUnitId = DefaultAdUnitId
        if let recommendedAdUnitId = _recommendedAdUnitId, !recommendedAdUnitId.isEmpty {
            _loadedAdUnitId = recommendedAdUnitId
        }
        
        SetInfo("Loading Rewarded \(_loadedAdUnitId!)")
        
        let adUnitId = _loadedAdUnitId!
        Task {
            do {
                _rewarded = try await GADRewardedAd.load(withAdUnitID: adUnitId, request: GADRequest())
                _rewarded!.paidEventHandler = onPaid
                _rewarded!.fullScreenContentDelegate = self
                
                NeftaAdapter.onExternalMediationRequestLoad(AdType.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, rewarded: _rewarded)
                
                DispatchQueue.main.async {
                    self.SetInfo("Loaded Rewarded \(adUnitId)")
                    self._showButton.isEnabled = true
                }
            } catch {
                NeftaAdapter.onExternalMediationRequestFail(AdType.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitId: adUnitId, error: error)
                
                DispatchQueue.main.async {
                    self.SetInfo("Failed to load Rewarded \(adUnitId) with error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.GetInsightsAndLoad()
                    }
                }
            }
        }
    }
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(.rewarded, adUnitId: _loadedAdUnitId!, adValue: adValue)
        
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
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
