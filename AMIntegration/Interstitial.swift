//
//  Interstitial.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Interstitial : NSObject, GADFullScreenContentDelegate {
    
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    
    var _interstitial: GADInterstitialAd!
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func Load() {
        self.SetInfo("Started loading interstitial ad loaded")
        Task {
            do {
                _interstitial = try await GADInterstitialAd.load(withAdUnitID: "ca-app-pub-1193175835908241/7029856207", request: GADRequest())
                _interstitial?.fullScreenContentDelegate = self
                
                DispatchQueue.main.async {
                    self.SetInfo("Interstitial ad loaded")
                    self._showButton.isEnabled = true
                }
            } catch {
                SetInfo("Failed to load interstitial ad with error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func Show() {
        _showButton.isEnabled = false
        
        if let interstitial = _interstitial {
            interstitial.present(fromRootViewController: _viewController)
        }
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
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
