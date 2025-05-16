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
    private let AdUnitIdInsightName = "recommended_banner_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_banner"
    
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    
    private let _showButton: UIButton
    private let _hideButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private let _bannerPlaceholder: UIView
    
    var _bannerView: GADBannerView!
    
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
        if let bidFloorInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = bidFloorInsight._float
        }
        
        print("OnBehaviourInsight for Banner: \(String(describing: _recommendedAdUnitId)), calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    private func Load() {
        _isLoadRequested = false
        
        var adUnitId = DefaultAdUnitId
        if let _recommendedAdUnitId = _recommendedAdUnitId {
            adUnitId = _recommendedAdUnitId
        }
        
        _bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        _bannerPlaceholder.addSubview(_bannerView)

        _bannerView.adUnitID = adUnitId
        _bannerView.rootViewController = _viewController
        _bannerView.delegate = self
        _bannerView.paidEventHandler = onPaid
        _bannerView.load(GADRequest())
    }
    
    func bannerView(_ ad: GADBannerView, didFailToReceiveAdWithError error: Error) {
        NeftaAdapter.onExternalMediationRequestFail(AdType.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitId: ad.adUnitID ?? "", error: error)

        SetInfo("didFailToReceiveAdWithError \(ad): \(error)")
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
    }
    
    func bannerViewDidReceiveAd(_ ad: GADBannerView) {
        NeftaAdapter.onExternalMediationRequestLoad(AdType.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitId: ad.adUnitID ?? "")
        
        SetInfo("bannerViewDidReceiveAd \(ad)")
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
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(adValue)
        
        SetInfo("onPaid \(adValue)")
    }
    
    func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}

