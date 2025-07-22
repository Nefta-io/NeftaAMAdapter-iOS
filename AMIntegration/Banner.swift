//
//  Banner.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Banner : NSObject, GADBannerViewDelegate {
    private let DefaultAdUnitId = "ca-app-pub-1193175835908241/7280922042"
    
    private var _bannerView: GADBannerView!
    private var _usedInsight: AdInsight?
    
    private let _showButton: UIButton
    private let _hideButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private let _bannerPlaceholder: UIView
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Banner, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._banner
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }
        let adUnitToLoad = selectedAdUnitId
        
        SetInfo("Loading Banner: \(adUnitToLoad)")
        
        _bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        _bannerPlaceholder.addSubview(_bannerView)

        _bannerView.adUnitID = adUnitToLoad
        _bannerView.rootViewController = _viewController
        _bannerView.delegate = self
        _bannerView.paidEventHandler = onPaid
        _bannerView.load(GADRequest())
    }
    
    func bannerView(_ ad: GADBannerView, didFailToReceiveAdWithError error: Error) {
        NeftaAdapter.onExternalMediationRequestFail(.banner, adUnitId: ad.adUnitID!, usedInsight: _usedInsight, error: error)

        SetInfo("didFailToReceiveAdWithError \(ad): \(error)")
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        //    self.GetInsightsAndLoad()
        //}
    }
    
    func bannerViewDidReceiveAd(_ ad: GADBannerView) {
        NeftaAdapter.onExternalMediationRequestLoad(withBanner: ad, usedInsight: _usedInsight)
        
        SetInfo("bannerViewDidReceiveAd \(ad)")
    }
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(withBanner: _bannerView, adValue: adValue)
        
        SetInfo("onPaid \(adValue)")
    }
    
    init(showButton: UIButton, hideButton: UIButton, status: UILabel, viewController: UIViewController, bannerPlaceholder: UIView) {
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _viewController = viewController
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(OnHideClick), for: .touchUpInside)
        _hideButton.isEnabled = false
    }
    
    @objc func OnLoadClick() {
        GetInsightsAndLoad()
        
        SetInfo("Loading...")
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    @objc func OnHideClick() {
        _bannerView.removeFromSuperview()
        _bannerView.delegate = nil
        _bannerView = nil
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
    }

    func bannerViewDidRecordImpression(_ ad: GADBannerView) {
        SetInfo("bannerViewDidRecordImpression \(ad)")
    }

    func bannerViewWillPresentScreen(_ ad: GADBannerView) {
        SetInfo("bannerViewWillPresentScreen \(ad)")
    }

    func bannerViewWillDismissScreen(_ ad: GADBannerView) {
        SetInfo("bannerViewWillDismissScreen \(ad)")
    }

    func bannerViewDidDismissScreen(_ ad: GADBannerView) {
        SetInfo("bannerViewDidDismissScreen \(ad)")
    }
    
    func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}

