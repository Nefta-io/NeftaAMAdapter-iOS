//
//  Banner.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Banner : NSObject, GADBannerViewDelegate {
    
    let _showButton: UIButton
    let _hideButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    let _bannerPlaceholder: UIView
    
    var _bannerView: GADBannerView!
    
    init(showButton: UIButton, hideButton: UIButton, status: UILabel, viewController: UIViewController, bannerPlaceholder: UIView) {
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _viewController = viewController
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(Hide), for: .touchUpInside)
        _hideButton.isEnabled = false
    }
    
    @objc func Show() {
        _bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        _bannerPlaceholder.addSubview(_bannerView)

        _bannerView.adUnitID = "ca-app-pub-1193175835908241/7280922042"
        _bannerView.rootViewController = _viewController
        _bannerView.delegate = self
        _bannerView.load(GADRequest())
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    @objc func Hide() {
        _bannerView.removeFromSuperview()
        _bannerView.delegate = nil
        _bannerView = nil
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
    }
    
    func bannerViewDidReceiveAd(_ ad: GADBannerView) {
        SetInfo("bannerViewDidReceiveAd \(ad)")
    }

    func bannerView(_ ad: GADBannerView, didFailToReceiveAdWithError error: Error) {
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        SetInfo("didFailToReceiveAdWithError \(ad): \(error)")
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
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}

