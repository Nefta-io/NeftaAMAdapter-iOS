//
//  Interstitial.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Interstitial : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
    
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/7029856207"
    
    private var _dynamicRequest: GADRequest?
    private var _dynamicInsight: AdInsight?
    private var _dynamicInterstitial: GADInterstitialAd!
    private var _defaultRequest: GADRequest?
    private var _defaultInterstitial: GADInterstitialAd!
    private var _presentingInterstitial: GADInterstitialAd!
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private var _status: UILabel
    private let _viewController: UIViewController
    
    private func StartLoading() {
        if _dynamicRequest == nil {
            GetInsightsAndLoad()
        }
        if _defaultRequest == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad() {
        if _dynamicRequest != nil || !_loadSwitch.isOn {
            return
        }
        
        _dynamicRequest = GADRequest()
        
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, previousInsight: _dynamicInsight, callback: LoadWithInsights, timeout: 5)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._interstitial
        if let insight = _dynamicInsight, let recommendedAdUnit = insight._adUnit {
            SetInfo("Loading Dynamic \(recommendedAdUnit)")
            GADNeftaAdapter.onExternalMediationRequest(with: insight, request: _dynamicRequest!, adUnitId: recommendedAdUnit)
            Task {
                do {
                    _dynamicInterstitial = try await GADInterstitialAd.load(withAdUnitID: recommendedAdUnit, request: _dynamicRequest)
                    _dynamicInterstitial!.fullScreenContentDelegate = self
                    _dynamicInterstitial!.paidEventHandler = onPaid
                    
                    _dynamicInsight = nil
                    
                    GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: _dynamicInterstitial, request: _dynamicRequest!)
                    
                    DispatchQueue.main.async {
                        self.SetInfo("Loaded Dynamic \(recommendedAdUnit)")
                        self.UpdateShowButton()
                    }
                } catch {
                    GADNeftaAdapter.onExternalMediationRequestFail(_dynamicRequest!, error: error)
                    
                    _dynamicRequest = nil
                    
                    DispatchQueue.main.async {
                        self.SetInfo("Failed to load Dynamic \(recommendedAdUnit) with error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.GetInsightsAndLoad()
                        }
                    }
                }
            }
        } else {
            _dynamicRequest = nil
        }
    }
    
    private func LoadDefault() {
        if _defaultRequest != nil || !_loadSwitch.isOn {
            return
        }
        
        SetInfo("Loading Default \(DefaultAdUnitId)")
        
        _defaultRequest = GADRequest()
        GADNeftaAdapter.onExternalMediationRequest(.interstitial, request: _defaultRequest!, adUnitId: DefaultAdUnitId)
        Task {
            do {
                _defaultInterstitial = try await GADInterstitialAd.load(withAdUnitID: DefaultAdUnitId, request: GADRequest())
                _defaultInterstitial!.fullScreenContentDelegate = self
                _defaultInterstitial!.paidEventHandler = onPaid
                
                GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: _defaultInterstitial, request: _defaultRequest!)
                
                DispatchQueue.main.async {
                    self.SetInfo("Loaded Default \(self.DefaultAdUnitId)")
                    self.UpdateShowButton()
                }
            } catch {
                GADNeftaAdapter.onExternalMediationRequestFail(_defaultRequest!, error: error)
                
                _defaultRequest = nil
                
                DispatchQueue.main.async {
                    self.SetInfo("Failed to load Default \(self.DefaultAdUnitId) with error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.LoadDefault()
                    }
                }
            }
        }
    }
    
    func onPaid(adValue: GADAdValue) {
        GADNeftaAdapter.onExternalMediationImpression(withInterstitial: _presentingInterstitial, adValue: adValue)
        
        SetInfo("onPaid \(adValue)")
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        GADNeftaAdapter.onExternalMediationClick(withInterstitial: _presentingInterstitial)
        
        SetInfo("onClick \(ad)")
    }
    
    init(loadSwitch: UISwitch, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadSwitch = loadSwitch
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        } else {
            _dynamicInsight = nil
        }
    }
    
    @objc func OnShowClick() {
        if _dynamicInterstitial != nil {
            SetInfo("Show Dynamic")
            _dynamicInterstitial.present(fromRootViewController: _viewController)
            _presentingInterstitial = _dynamicInterstitial
            _dynamicInterstitial = nil
            _dynamicRequest = nil
        } else if _defaultInterstitial != nil {
            SetInfo("Show Default")
            _defaultInterstitial.present(fromRootViewController: _viewController)
            _presentingInterstitial = _defaultInterstitial
            _defaultInterstitial = nil
            _defaultRequest = nil
        }
        UpdateShowButton()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        SetInfo("didFailToPresentFullScreenContentWithError \(error)")
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("adWillPresentFullScreenContent")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("adDidDismissFullScreenContent")
        
        _presentingInterstitial = nil
        
        // start new load cycle
        if (_loadSwitch.isOn) {
            StartLoading();
        }
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicInterstitial != nil || _defaultInterstitial != nil
    }
    
    func SetInfo(_ info: String) {
        print("NeftaPluginAM Interstitial \(info)")
        _status.text = info
    }
}
