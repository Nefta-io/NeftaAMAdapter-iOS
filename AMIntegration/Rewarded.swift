//
//  Rewarded.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Rewarded : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
    
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/3090611193"
    
    private var _dynamicRequest: GADRequest?
    private var _dynamicInsight: AdInsight?
    private var _dynamicRewarded: GADRewardedAd!
    private var _defaultRequest: GADRequest?
    private var _defaultRewarded: GADRewardedAd!
    private var _presentingRewarded: GADRewardedAd?
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
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
        
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: _dynamicInsight, callback: LoadWithInsights, timeout: 5)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._rewarded
        if let insight = _dynamicInsight, let recommendedAdUnit = insight._adUnit {
            SetInfo("Loading Dynamic \(recommendedAdUnit)")
            GADNeftaAdapter.onExternalMediationRequest(with: insight, request: _dynamicRequest!, adUnitId: recommendedAdUnit)
            Task {
                do {
                    _dynamicRewarded = try await GADRewardedAd.load(withAdUnitID: recommendedAdUnit, request: GADRequest())
                    _dynamicRewarded!.fullScreenContentDelegate = self
                    _dynamicRewarded!.paidEventHandler = onPaid
                    
                    _dynamicInsight = nil
                    
                    GADNeftaAdapter.onExternalMediationRequestLoad(withRewarded: _dynamicRewarded, request: _dynamicRequest!)
                    
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
        GADNeftaAdapter.onExternalMediationRequest(.rewarded, request: _defaultRequest!, adUnitId: DefaultAdUnitId)
        Task {
            do {
                self._defaultRewarded = try await GADRewardedAd.load(withAdUnitID: DefaultAdUnitId, request: _defaultRequest)
                _defaultRewarded!.fullScreenContentDelegate = self
                _defaultRewarded!.paidEventHandler = onPaid
                
                GADNeftaAdapter.onExternalMediationRequestLoad(withRewarded: _defaultRewarded, request: _defaultRequest!)
                
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
        GADNeftaAdapter.onExternalMediationImpression(withRewarded: _presentingRewarded!, adValue: adValue)
        
        SetInfo("onPaid \(adValue)")
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        GADNeftaAdapter.onExternalMediationClick(withRewarded: ad as! GADRewardedAd)
        
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
        if _dynamicRewarded != nil {
            SetInfo("Showing Dynamic")
            _dynamicRewarded.present(fromRootViewController: _viewController) {
                let reward = self._presentingRewarded!.adReward
                self.SetInfo("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
            }
            _presentingRewarded = _dynamicRewarded
            _dynamicRewarded = nil
            _dynamicRequest = nil
        } else if _defaultRewarded != nil {
            SetInfo("Showing Default")
            _defaultRewarded.present(fromRootViewController: _viewController) {
                let reward = self._presentingRewarded!.adReward
                self.SetInfo("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
            }
            _presentingRewarded = _defaultRewarded
            _defaultRewarded = nil
            _defaultRequest = nil
        }
        UpdateShowButton()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        SetInfo("didFailToPresentFullScreenContentWithError: \(error)")
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("adWillPresentFullScreenContent")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        SetInfo("adDidDismissFullScreenContent")
        
        _presentingRewarded = nil
        
        // start new load cycle
        if (_loadSwitch.isOn) {
            StartLoading();
        }
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicRewarded != nil || _defaultRewarded != nil
    }
    
    private func SetInfo(_ info: String) {
        print("NeftaPluginAM Rewarded \(info)")
        _status.text = info
    }
}
