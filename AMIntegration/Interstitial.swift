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
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private var _status: UILabel
    private let _viewController: UIViewController
    
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    
    private var _defaultInterstitial: GADInterstitialAd!
    private var _recommendedInterstitial: GADInterstitialAd!
    
    private func Load() {
        SetInfo("Loading...")
        
        Task {
            do {
                _defaultInterstitial = try await GADInterstitialAd.load(withAdUnitID: DefaultAdUnitId, request: GADRequest())
                _defaultInterstitial!.paidEventHandler = onPaid
                _defaultInterstitial!.fullScreenContentDelegate = self
                
                DispatchQueue.main.async {
                    NeftaAdapter.onExternalMediationRequestLoad(AdType.interstitial, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._defaultInterstitial.adUnitID)
                    
                    self.SetInfo("Loaded default interstitial")
                    self._showButton.isEnabled = true
                }
            } catch {
                NeftaAdapter.onExternalMediationRequestFail(AdType.interstitial, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._defaultInterstitial.adUnitID, error: error)
                
                SetInfo("Failed to load default interstitial ad with error: \(error.localizedDescription)")
                
                _defaultInterstitial = nil
                
                if _defaultInterstitial == nil && _recommendedAdUnitId != nil {
                    Load()
                }
            }
        }
        
        NeftaPlugin._instance.GetBehaviourInsight([AdUnitIdInsightName, FloorPriceInsightName], callback: OnBehaviourInsight)
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
        
        print("OnBehaviourInsight for Rewarded recommended AdUnit: \(String(describing: _recommendedAdUnitId)) calculated bid floor:\(_calculatedBidFloor)")

        if let recommendedAdUnitId = _recommendedAdUnitId, DefaultAdUnitId != recommendedAdUnitId {
            Task {
                do {
                    _recommendedInterstitial = try await GADInterstitialAd.load(withAdUnitID: recommendedAdUnitId, request: GADRequest())
                    _recommendedInterstitial!.paidEventHandler = onPaid
                    _recommendedInterstitial!.fullScreenContentDelegate = self
                    
                    DispatchQueue.main.async {
                        NeftaAdapter.onExternalMediationRequestLoad(AdType.interstitial, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._recommendedInterstitial.adUnitID)
                        
                        self.SetInfo("Loaded recommended interstitial")
                        self._showButton.isEnabled = true
                    }
                } catch {
                    NeftaAdapter.onExternalMediationRequestFail(AdType.interstitial, recommendedAdUnitId: self._recommendedAdUnitId, calculatedFloorPrice: self._calculatedBidFloor, adUnitId: self._recommendedInterstitial.adUnitID, error: error)
                    
                    SetInfo("Failed to load recommended interstitial ad with error: \(error.localizedDescription)")
                    
                    _recommendedInterstitial = nil
                    
                    if _defaultInterstitial == nil && _recommendedAdUnitId != nil {
                        Load()
                    }
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
        Load()
    }
    
    @objc func OnShowClick() {
        SetInfo("Show default: \(String(describing: _defaultInterstitial)) recommended: \(String(describing: _recommendedInterstitial))")
        
        if let recommendedInterstitial = _recommendedInterstitial {
            recommendedInterstitial.present(fromRootViewController: _viewController)
            _recommendedInterstitial = nil
        } else if let defaultInterstitial = _defaultInterstitial {
            defaultInterstitial.present(fromRootViewController: _viewController)
            _defaultInterstitial = nil
        }
        
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
    
    func onPaid(adValue: GADAdValue) {
        SetInfo("onPaid \(adValue)")
        NeftaAdapter.onExternalMediationImpression(adValue)
    }
    
    func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
