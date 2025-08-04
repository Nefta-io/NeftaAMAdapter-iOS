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
    
    private var _interstitial: GADInterstitialAd!
    private var _usedInsight: AdInsight?
    private var _isLoading = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private var _status: UILabel
    private let _viewController: UIViewController
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._interstitial
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }
        let adUnitToLoad = selectedAdUnitId
        
        SetInfo("Loading Interstitial \(adUnitToLoad)")
        Task {
            do {
                _interstitial = try await GADInterstitialAd.load(withAdUnitID: adUnitToLoad, request: GADRequest())
                _interstitial!.paidEventHandler = onPaid
                _interstitial!.fullScreenContentDelegate = self
                
                GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: _interstitial, usedInsight: _usedInsight)
                
                DispatchQueue.main.async {
                    self.SetInfo("Loaded interstitial \(adUnitToLoad)")
                    
                    self.SetLoadingButton(isLoading: false)
                    self._loadButton.isEnabled = false
                    self._showButton.isEnabled = true
                }
            } catch {
                GADNeftaAdapter.onExternalMediationRequestFail(.interstitial, adUnitId: adUnitToLoad, usedInsight: _usedInsight, error: error)
                
                DispatchQueue.main.async {
                    self.SetInfo("Failed to load Interstitial \(adUnitToLoad) with error: \(error.localizedDescription)")
                    
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
        GADNeftaAdapter.onExternalMediationImpression(withInterstitial: _interstitial, adValue: adValue)
        
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
        _interstitial.present(fromRootViewController: _viewController)
        
        _loadButton.isEnabled = true
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
    
    private func SetLoadingButton(isLoading: Bool) {
        _isLoading = isLoading
        if isLoading {
            _loadButton.setTitle("Cancel", for: .normal)
        } else {
            _loadButton.setTitle("Load Interstitial", for: .normal)
        }
    }
}
