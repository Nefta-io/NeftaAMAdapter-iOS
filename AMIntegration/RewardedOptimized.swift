//
//  RewardedOptimized.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 12. 5. 26.
//

public class RewardedOptimized : Rewarded {
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
        private let _controller: RewardedOptimized
        
        public let _adUnitId: String
        public var _floorPrice: Double = 0
        public var _request: GADRequest?
        public var _rewarded: GADRewardedAd?
        public var _state = State.Idle
        public var _insight: AdInsight?
        
        public init(controller: RewardedOptimized, adUnitId: String) {
            _adUnitId = adUnitId
            _controller = controller
        }
        
        func OnLoad(rewarded: GADRewardedAd) {
            _rewarded = rewarded
            GADNeftaAdapter.onExternalMediationRequestLoad(withRewarded: rewarded, request: _request!)
            
            _controller.Log("OnLoad \(_adUnitId)")
            
            rewarded.fullScreenContentDelegate = self
            rewarded.paidEventHandler = onPaid
            
            _insight = nil
            _request = nil
            _state = .Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func OnLoadFail(error: Error) {
            GADNeftaAdapter.onExternalMediationRequestFail(_request!, error: error)
            
            _controller.Log("OnLoadFail \(_adUnitId): \(error.localizedDescription)")
            
            _request = nil
            _rewarded = nil
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
                try _rewarded!.canPresent(fromRootViewController: viewController!)
                _controller.Log("Show \(_adUnitId)")
                _state = .Shown
                _rewarded!.present(fromRootViewController: viewController!) {
                    let reward = self._rewarded!.adReward
                    self._controller.Log("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
                }
            } catch let error as NSError {
                _controller.Log("Error showing \(String(describing: _adUnitId)): \(error.description)")
                _state = .Idle
                _controller.RetryLoadTracks()
                return false
            }
            return true
        }
        
        func onPaid(adValue: GADAdValue) {
            GADNeftaAdapter.onExternalMediationImpression(withRewarded: _rewarded!, adValue: adValue)
            
            _controller.Log("onPaid \(adValue)")
        }
        
        public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
            GADNeftaAdapter.onExternalMediationClick(withRewarded: ad as! GADRewardedAd)
            
            _controller.Log("onClick \(ad)")
        }
        
        public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            _controller.Log("didFailToPresentFullScreenContentWithError: \(error)")
            
            _state = .Idle
            _rewarded = nil
            _controller.RetryLoadTracks()
        }
        
        public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            _controller.Log("adWillPresentFullScreenContent")
        }
        
        public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            _controller.Log("adDidDismissFullScreenContent")
            
            _state = .Idle
            _rewarded = nil
            _controller.RetryLoadTracks()
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    private var _ui: RewardedUi!
    
    func Init(ui: RewardedUi) {
        _ui = ui
        
        _trackA = Track(controller: self, adUnitId: RewardedUi.AdUnitA)
        _trackB = Track(controller: self, adUnitId: RewardedUi.AdUnitB)
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
        track._state = .LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights \(insights)")
            if let insight = insights._rewarded {
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
                        let rewarded = try await GADRewardedAd.load(withAdUnitID: track._adUnitId, request: track._request)
                        DispatchQueue.main.async {
                            track.OnLoad(rewarded: rewarded)
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
        
        GADNeftaAdapter.onExternalMediationRequest(.rewarded, request: track._request!, adUnitId: track._adUnitId)
        
        Task {
            do {
                let rewarded = try await GADRewardedAd.load(withAdUnitID: track._adUnitId, request: track._request)
                DispatchQueue.main.async {
                    track.OnLoad(rewarded: rewarded)
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
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._floorPrice > _trackA._floorPrice {
                isShown = _trackB.TryShow(viewController: _ui.ViewController)
            }
            if !isShown {
                isShown = _trackA.TryShow(viewController: _ui.ViewController)
            }
        }
        if !isShown && _trackB._state == .Ready {
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
