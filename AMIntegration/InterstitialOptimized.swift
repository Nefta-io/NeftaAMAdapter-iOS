//
//  InterstitialOptimized.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 12. 5. 26.
//

public class InterstitialOptimized : Interstitial {
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
        private let _controller: InterstitialOptimized
        
        public let _adUnitId: String
        public var _floorPrice: Double = 0
        public var _request: GADRequest?
        public var _interstitial: GADInterstitialAd?
        public var _state = State.Idle
        public var _insight: AdInsight?
        
        init(controller: InterstitialOptimized, adUnitId: String) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + GADNeftaAdapter.GetRetryDelayInSeconds(insight: _insight)) {
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
        
        public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
            GADNeftaAdapter.onExternalMediationClick(withInterstitial: _interstitial!)
            
            _controller.Log("onClick \(ad)")
        }
        
        public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            _controller.Log("didFailToPresentFullScreenContentWithError \(error)")
            
            _state = .Idle
            _interstitial = nil
            _controller.RetryLoadTracks()
        }

        public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            _controller.Log("adWillPresentFullScreenContent")
        }

        public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            _controller.Log("adDidDismissFullScreenContent")
            
            _state = .Idle
            _interstitial = nil
            _controller.RetryLoadTracks()
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    private var _ui: InterstitialUi!
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        
        _trackA = Track(controller: self, adUnitId: InterstitialUi.AdUnitA)
        _trackB = Track(controller: self, adUnitId: InterstitialUi.AdUnitB)
    }
    
    public func Load() {
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
        })
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
    
    public func Show() {
        var isShown = false
        if _trackA._state == State.Ready {
            if _trackB._state == State.Ready && _trackB._floorPrice > _trackA._floorPrice {
                isShown = _trackB.TryShow(viewController: _ui.ViewController)
            }
            if !isShown {
                isShown = _trackA.TryShow(viewController: _ui.ViewController)
            }
        }
        if !isShown && _trackB._state == State.Ready {
            isShown = _trackB.TryShow(viewController: _ui.ViewController)
        }
        
        UpdateAvailability()
    }
    
    private func RetryLoadTracks() {
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateAvailability()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    private func UpdateAvailability() {
        _ui.SetAvailable(available: _trackA._state == .Ready || _trackB._state == .Ready)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
