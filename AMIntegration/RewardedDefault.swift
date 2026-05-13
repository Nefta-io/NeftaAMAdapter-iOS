//
//  RewardedDefault.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 12. 5. 26.
//

public class RewardedDefault : NSObject, @unchecked Sendable, GADFullScreenContentDelegate, Rewarded {
    private var _ui: RewardedUi!
    private var _adUnitId: String!
    
    public var _request: GADRequest?
    public var _rewarded: GADRewardedAd?
    
    func Init(ui: RewardedUi) {
        _ui = ui
        _adUnitId = InterstitialUi.AdUnitA
    }
    
    public func Load() {
        _request = GADRequest()
        
        GADNeftaAdapter.onExternalMediationRequest(.rewarded, request: _request!, adUnitId: _adUnitId)
        
        Log("Loading \(_adUnitId!)")
        Task {
            do {
                let rewarded = try await GADRewardedAd.load(withAdUnitID: _adUnitId, request: _request)
                DispatchQueue.main.async {
                    GADNeftaAdapter.onExternalMediationRequestLoad(withRewarded: self._rewarded!, request: self._request!)
                    
                    self.Log("OnLoad \(self._adUnitId!)")
                    
                    self._rewarded!.fullScreenContentDelegate = self
                    self._rewarded!.paidEventHandler = self.onPaid
                    
                    self._request = nil
                    self._ui.SetAvailable(available: true)
                }
            } catch {
                Log("Load failed \(_adUnitId!)")
                _request = nil
                DispatchQueue.main.async {
                    if self._ui.IsAutoLoad {
                        self.Load()
                    }
                }
            }
        }
    }
    
    public func Show() {
        do {
            try _rewarded!.canPresent(fromRootViewController: _ui.ViewController)
            Log("Show \(_adUnitId!)")
            _rewarded!.present(fromRootViewController: _ui.ViewController) {
                let reward = self._rewarded!.adReward
                self.Log("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
            }
        } catch let error as NSError {
            Log("Error showing \(String(describing: _adUnitId)): \(error.description)")
            if _ui.IsAutoLoad {
                Load()
            }
        }
    }
    
    func onPaid(adValue: GADAdValue) {
        GADNeftaAdapter.onExternalMediationImpression(withRewarded: _rewarded!, adValue: adValue)
        
        Log("onPaid \(adValue)")
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        GADNeftaAdapter.onExternalMediationClick(withRewarded: ad as! GADRewardedAd)
        
        Log("onClick \(ad)")
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Log("didFailToPresentFullScreenContentWithError: \(error)")
        
        _rewarded = nil
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Log("adWillPresentFullScreenContent")
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Log("adDidDismissFullScreenContent")
        
        _rewarded = nil
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
