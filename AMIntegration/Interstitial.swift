//
//  Interstitial.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class Interstitial : UIView {
    
    private let AdUnitA = "ca-app-pub-1193175835908241/7029856207"
    private let AdUnitB = "ca-app-pub-1193175835908241/2987215201"
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
        private let _controller: Interstitial
        
        public let _adUnitId: String
        public var _floorPrice: Double = 0
        public var _request: GADRequest?
        public var _interstitial: GADInterstitialAd?
        public var _state = State.Idle
        public var _insight: AdInsight?
        
        init(adUnitId: String, controller: Interstitial) {
            _adUnitId = adUnitId
            _controller = controller
        }
        
        func OnLoad(interstitial: GADInterstitialAd) {
            _interstitial = interstitial
            GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: interstitial, request: _request!)
            
            _controller.Log("OnLoad \(_adUnitId)")
            
            interstitial.fullScreenContentDelegate = self
            interstitial.paidEventHandler = onPaid
            
            _insight = nil
            _request = nil
            _state = State.Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func OnLoadFail(error: Error) {
            GADNeftaAdapter.onExternalMediationRequestFail(_request!, error: error)
            
            _controller.Log("OnLoadFail \(_adUnitId): \(error.localizedDescription)")
            
            _request = nil
            _interstitial = nil
            AfterLoadFail()
        }
        
        func AfterLoadFail() {
            RetryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func RetryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self._state = State.Idle
                self._controller.RetryLoadTracks()
            }
        }
        
        func TryShow(viewController: UIViewController?) -> Bool {
            _floorPrice = 0
            
            do {
                try _interstitial!.canPresent(fromRootViewController: viewController!)
                self._controller.Log("Show \(_adUnitId)")
                _state = State.Shown
                _interstitial!.present(fromRootViewController: viewController!)
            } catch let error as NSError {
                _controller.Log("Error showing \(_adUnitId): \(error.description)")
                _state = State.Idle
                _controller.RetryLoadTracks()
                return false
            }
            return true
        }
        
        public func onPaid(adValue: GADAdValue) {
            GADNeftaAdapter.onExternalMediationImpression(withInterstitial: _interstitial!, adValue: adValue)
            
            _controller.Log("onPaid \(adValue)")
        }
        
        func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
            GADNeftaAdapter.onExternalMediationClick(withInterstitial: _interstitial!)
            
            _controller.Log("onClick \(ad)")
        }
        
        func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            _controller.Log("didFailToPresentFullScreenContentWithError \(error)")
            
            _state = .Idle
            _interstitial = nil
            _controller.RetryLoadTracks()
        }

        func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            _controller.Log("adWillPresentFullScreenContent")
        }

        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            Interstitial.Instance.Log("adDidDismissFullScreenContent")
            
            _state = .Idle
            _interstitial = nil
            _controller.RetryLoadTracks()
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    private var _viewController: UIViewController?
    
    public static var Instance: Interstitial!
    
    private func LoadTracks() {
        LoadTrack(track: _trackA, otherState: _trackB._state)
        LoadTrack(track: _trackB, otherState: _trackA._state)
    }
    
    private func LoadTrack(track: Track, otherState: State) {
        if track._state == .Idle {
            if otherState == .LoadingWithInsights || otherState == .Shown {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = State.LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                track._insight = insight
                track._floorPrice = insight._floorPrice
                
                // map floorPrice to your AdMob Pro mediation group configuration
                // sample KVP mapping:
                var mediationGroup = "low";
                if track._floorPrice > 100
                {
                    mediationGroup = "high";
                }
                else if track._floorPrice > 50
                {
                    mediationGroup = "medium";
                }
                let extras = GADExtras()
                extras.additionalParameters = [ "mediation group key": mediationGroup ]
                
                track._request = GADRequest()
                track._request!.register(extras)
                
                GADNeftaAdapter.onExternalMediationRequest(with: insight, request: track._request!, adUnitId: track._adUnitId)
                
                self.Log("Loading \(track._adUnitId) as Optimized with \(mediationGroup)")
                Task {
                    do {
                        let interstitial = try await GADInterstitialAd.load(withAdUnitID: track._adUnitId, request: track._request)
                        DispatchQueue.main.async {
                            track.OnLoad(interstitial: interstitial)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            track.OnLoadFail(error: error)
                        }
                    }
                }
            } else {
                track.AfterLoadFail()
            }
        }, timeout: 5)
    }
    
    private func LoadDefault(track: Track) {
        track._state = State.Loading
        
        track._floorPrice = 0
        track._request = GADRequest()
        
        GADNeftaAdapter.onExternalMediationRequest(.interstitial, request: track._request!, adUnitId: track._adUnitId)
        
        Log("Loading \(track._adUnitId) as Default")
        Task {
            do {
                let interstitial = try await GADInterstitialAd.load(withAdUnitID: track._adUnitId, request: track._request)
                DispatchQueue.main.async {
                    track.OnLoad(interstitial: interstitial)
                }
            } catch {
                DispatchQueue.main.async {
                    track.OnLoadFail(error: error)
                }
            }
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _viewController = findViewController()
        
        _trackA = Track(adUnitId: AdUnitA, controller: self)
        _trackB = Track(adUnitId: AdUnitB, controller: self)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
        
        Interstitial.Instance = self
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _trackA._state == State.Ready {
            if _trackB._state == State.Ready && _trackB._floorPrice > _trackA._floorPrice {
                isShown = _trackB.TryShow(viewController: _viewController)
            }
            if !isShown {
                isShown = _trackA.TryShow(viewController: _viewController)
            }
        }
        if !isShown && _trackB._state == State.Ready {
            isShown = _trackB.TryShow(viewController: _viewController)
        }
        UpdateShowButton()
    }
    
    private func RetryLoadTracks() {
        if _loadSwitch.isOn {
            LoadTracks()
        }
    }
    
    func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _trackA._state == State.Ready || _trackB._state == State.Ready
    }
    
    func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginAM Interstitial \(log, privacy: .public)")
    }
}
