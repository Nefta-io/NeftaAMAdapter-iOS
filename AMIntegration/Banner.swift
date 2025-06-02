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
    
    private var _bannerView: GADBannerView!
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    private var _loadedAdUnitId: String? = nil
    
    private let _showButton: UIButton
    private let _hideButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private let _bannerPlaceholder: UIView
    
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
        
        _loadedAdUnitId = DefaultAdUnitId
        if let recommendedAdUnitId = _recommendedAdUnitId, !recommendedAdUnitId.isEmpty {
            _loadedAdUnitId = recommendedAdUnitId
        }
        
        SetInfo("Loading Banner \(_loadedAdUnitId!)")
        
        _bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        _bannerPlaceholder.addSubview(_bannerView)

        _bannerView.adUnitID = _loadedAdUnitId
        _bannerView.rootViewController = _viewController
        _bannerView.delegate = self
        _bannerView.paidEventHandler = onPaid
        _bannerView.load(GADRequest())
    }
    
    func bannerView(_ ad: GADBannerView, didFailToReceiveAdWithError error: Error) {
        NeftaAdapter.onExternalMediationRequestFail(AdType.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitId: _loadedAdUnitId!, error: error)

        SetInfo("didFailToReceiveAdWithError \(ad): \(error)")
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.GetInsightsAndLoad()
        }
    }
    
    func bannerViewDidReceiveAd(_ ad: GADBannerView) {
        NeftaAdapter.onExternalMediationRequestLoad(AdType.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, banner: ad)
        
        SetInfo("bannerViewDidReceiveAd \(ad)")
    }
    
    func onPaid(adValue: GADAdValue) {
        NeftaAdapter.onExternalMediationImpression(AdType.banner, adUnitId: _loadedAdUnitId!, adValue: adValue)
        
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

