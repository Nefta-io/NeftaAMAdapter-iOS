//
//  InterstitialDefault.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 12. 5. 26.
//

public class InterstitialDefault : NSObject, @unchecked Sendable, GADFullScreenContentDelegate, Interstitial {
    private var _ui: InterstitialUi!
    private var _adUnitId: String!
    
    public var _request: GADRequest?
    public var _interstitial: GADInterstitialAd?
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        _adUnitId = InterstitialUi.AdUnitA
    }
    
    public func Load() {
        _request = GADRequest()
        
        GADNeftaAdapter.onExternalMediationRequest(.interstitial, request: _request!, adUnitId: _adUnitId)
        
        Log("Loading \(_adUnitId!)")
        Task {
            do {
                _interstitial = try await GADInterstitialAd.load(withAdUnitID: _adUnitId, request: _request)
                DispatchQueue.main.async {
                    GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: self._interstitial!, request: self._request!)
                    
                    self.Log("OnLoad \(InterstitialUi.AdUnitA)")
                    
                    self._interstitial!.fullScreenContentDelegate = self
                    self._interstitial!.paidEventHandler = self.onPaid
                    
                    self._request = nil
                    self._ui.SetAvailable(available: true)
                }
            } catch {
                Log("Load failed \(_adUnitId!)")
                _request = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if self._ui.IsAutoLoad {
                        self.Load()
                    }
                }
            }
        }
    }
    
    public func Show() {
        do {
            try _interstitial!.canPresent(fromRootViewController: _ui.ViewController!)
            Log("Show \(_adUnitId!)")
            _interstitial!.present(fromRootViewController: _ui.ViewController!)
        } catch let error as NSError {
            Log("Error showing \(_adUnitId!): \(error.description)")
            if _ui.IsAutoLoad {
                Load()
            }
        }
        _ui.SetAvailable(available: false)
    }
    
    public func onPaid(adValue: GADAdValue) {
        GADNeftaAdapter.onExternalMediationImpression(withInterstitial: _interstitial!, adValue: adValue)
        
        Log("onPaid \(adValue)")
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        GADNeftaAdapter.onExternalMediationClick(withInterstitial: _interstitial!)
        
        Log("onClick \(ad)")
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Log("didFailToPresentFullScreenContentWithError \(error)")
        
        _interstitial = nil
        if _ui.IsAutoLoad {
            Load()
        }
    }

    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Log("adWillPresentFullScreenContent")
    }

    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Log("adDidDismissFullScreenContent")
        
        _interstitial = nil
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
