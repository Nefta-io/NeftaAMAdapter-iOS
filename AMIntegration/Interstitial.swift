//
//  Interstitial.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Interstitial : NSObject, GADFullScreenContentDelegate {
    
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/7029856207"
    
    private let AdUnitIdInsightName = "recommended_interstitial_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_interstitial"
    
    private var _interstitial: GADInterstitialAd!
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    private var _loadedAdUnitId: String? = nil
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private var _status: UILabel
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
    
    private func OnBehaviourInsight(insights: [String: Insight]) {
        _recommendedAdUnitId = nil
        _calculatedBidFloor = 0
        if let recommendedAdUnitInsight = insights[AdUnitIdInsightName] {
            _recommendedAdUnitId = recommendedAdUnitInsight._string
        }
        if let floorPriceInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = floorPriceInsight._float
        }
        
        print("OnBehaviourInsight for Interstitial: \(String(describing: _recommendedAdUnitId)) calculated bid floor:\(_calculatedBidFloor)")

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
        
        SetInfo("Loading Interstitial \(_loadedAdUnitId!)")
        
        let adUnitId = _loadedAdUnitId!
        Task {
            do {
                _interstitial = try await GADInterstitialAd.load(withAdUnitID: adUnitId, request: GADRequest())
                _interstitial!.paidEventHandler = onPaid
                _interstitial!.fullScreenContentDelegate = self
                
                NeftaAdapter.onExternalMediationRequestLoad(AdType.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, interstitial: _interstitial)
                
                DispatchQueue.main.async {
                    self.SetInfo("Loaded interstitial \(adUnitId)")
                    self._showButton.isEnabled = true
                }
            } catch {
                NeftaAdapter.onExternalMediationRequestFail(AdType.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitId: adUnitId, error: error)
                
                DispatchQueue.main.async {
                    self.SetInfo("Failed to load Interstitial \(adUnitId) with error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.GetInsightsAndLoad()
                    }
                }
            }
        }
    }
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(.interstitial, adUnitId: _loadedAdUnitId!, adValue: adValue)
        
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
        _interstitial.present(fromRootViewController: _viewController)
        
        _showButton.isEnabled = false
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        SetInfo("Interstitial ad did fail to present full screen content.")
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("Interstitial ad will present full screen content.")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("Interstitial ad did dismiss full screen content.")
    }
    
    func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
