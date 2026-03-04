//
//  InterstitialSim.swift
//  AMIntegration
//
//  Created by Tomaz Treven on 28. 06. 24.
//

import Foundation
import GoogleMobileAds

class InterstitialSim : UIView {
    
    private let AdUnitA = "AdUnit-A"
    private let AdUnitB = "AdUnit-B"
    
    private let DefaultBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private let DefaultColor = UIColor(red: 0.6509804, green: 0.1490196, blue: 0.7490196, alpha: 1.0)
    private let FillColor = UIColor.green
    private let NoFillColor = UIColor.red
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, @unchecked Sendable, GADFullScreenContentDelegate {
        private let _controller: InterstitialSim
        
        public let _adUnitId: String
        public var _floorPrice: Double = 0
        public var _request: GADRequest?
        public var _interstitial: GADInterstitialAd?
        public var _state = State.Idle
        public var _insight: AdInsight?
        public var _loadSelection: Int = 0
        
        init(adUnitId: String, controller: InterstitialSim) {
            _adUnitId = adUnitId
            _controller = controller
        }
        
        func OnLoad(interstitial: GADInterstitialAd) {
            _interstitial = interstitial
            GADNeftaAdapter.onExternalMediationRequestLoad(withInterstitial: interstitial, request: _request!)
            
            _controller.Log("OnLoad \(_adUnitId)")
            
            interstitial.fullScreenContentDelegate = self
            (interstitial as! SGADInterstitialAd)._paidEventHandler = onPaid
            
            _insight = nil
            _request = nil
            _state = .Ready
            
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
                self._state = .Idle
                self._controller.RetryLoadTracks()
            }
        }
        
        func TryShow(viewController: UIViewController) -> Bool {
            _floorPrice = 0
            
            do {
                try _interstitial!.canPresent(fromRootViewController: _controller._viewController)
                _controller.Log("Show \(_adUnitId)")
                _state = .Shown
                _interstitial!.present(fromRootViewController: viewController)
            } catch let error as NSError {
                _controller.Log("Error showing \(_adUnitId)): \(error.description)")
                _state = .Idle
                _controller.RetryLoadTracks()
                return false
            }
            return true
        }
        
        @objc public func onPaid(adValue: GADAdValue) {
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
            _controller.Log("adDidDismissFullScreenContent")
            
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
    
    @IBOutlet weak var _aFill2: UIButton!
    @IBOutlet weak var _aFill1: UIButton!
    @IBOutlet weak var _aNoFill: UIButton!
    @IBOutlet weak var _aOther: UIButton!
    @IBOutlet weak var _aStatus: UILabel!
    
    @IBOutlet weak var _bFill2: UIButton!
    @IBOutlet weak var _bFill1: UIButton!
    @IBOutlet weak var _bNoFill: UIButton!
    @IBOutlet weak var _bOther: UIButton!
    @IBOutlet weak var _bStatus: UILabel!
    
    private var _viewController: UIViewController!
    @IBOutlet weak var _simulatorAd: SimulatorAd!
    
    private static var Instance: InterstitialSim!
    
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
        track._state = .LoadingWithInsights
        
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
                        let interstitial = try await SGADInterstitialAd.load(withAdUnitID: track._adUnitId, request: track._request)
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
        track._state = .Loading
        
        track._floorPrice = 0
        track._request = GADRequest()
        
        Log("Loading \(track._adUnitId) as Default")
        GADNeftaAdapter.onExternalMediationRequest(.interstitial, request: track._request!, adUnitId: AdUnitA)
        
        Task {
            do {
                let interstitial = try await SGADInterstitialAd.load(withAdUnitID: track._adUnitId, request: track._request!)
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
        InterstitialSim.Instance = self
        _viewController = findViewController()
        
        _trackA = Track(adUnitId: AdUnitA, controller: self)
        _trackB = Track(adUnitId: AdUnitB, controller: self)
        
        ToggleTrackA(isOn: false)
        _aFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: true)
        }, for: .touchUpInside)
        _aFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: false)
        }, for: .touchUpInside)
        _aNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 2)
        }, for: .touchUpInside)
        _aOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 0)
        }, for: .touchUpInside)
        
        ToggleTrackB(isOn: false)
        _bFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: true)
        }, for: .touchUpInside)
        _bFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: false)
        }, for: .touchUpInside)
        _bNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 2)
        }, for: .touchUpInside)
        _bOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 0)
        }, for: .touchUpInside)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._floorPrice > _trackA._floorPrice {
                isShown = _trackB.TryShow(viewController: _viewController)
            }
            if !isShown {
                isShown = _trackA.TryShow(viewController: _viewController)
            }
        }
        if !isShown && _trackB._state == .Ready {
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
        _showButton.isEnabled = _trackA._state == .Ready || _trackB._state == .Ready
    }
    
    func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginAM InterstitialSim \(log, privacy: .public)")
    }
    
    func SimOnAdLoadedEvent(request: Track, isHigh: Bool) {
        if let interstitial = request._interstitial as? SGADInterstitialAd, interstitial._hasFill {
            interstitial._hasFill = false
            
            if request._request == _trackA._request {
                if isHigh {
                    _aFill2.tintColor = DefaultColor
                    _aFill2.backgroundColor = DefaultColor
                    _aFill2.isEnabled = false
                } else {
                    _aFill1.tintColor = DefaultColor
                    _aFill1.backgroundColor = DefaultColor
                    _aFill1.isEnabled = false
                }
            } else {
                if isHigh {
                    _bFill2.tintColor = DefaultColor
                    _bFill2.backgroundColor = DefaultColor
                    _bFill2.isEnabled = false
                } else {
                    _bFill1.tintColor = DefaultColor
                    _bFill1.backgroundColor = DefaultColor
                    _bFill1.isEnabled = false
                }
            }
            return
        }
        
        if request._request == _trackA._request {
            ToggleTrackA(isOn: false)
            if isHigh {
                _aFill2.tintColor = FillColor
                _aFill2.backgroundColor = FillColor
                _aFill2.isEnabled = true
                
                request._loadSelection = 1
            } else {
                _aFill1.tintColor = FillColor
                _aFill1.backgroundColor = FillColor
                _aFill1.isEnabled = true
                
                request._loadSelection = 2
            }
            SetStatusA("\(request._adUnitId) loaded")
        } else {
            ToggleTrackB(isOn: false)
            if isHigh {
                _bFill2.tintColor = FillColor
                _bFill2.backgroundColor = FillColor
                _bFill2.isEnabled = true
                
                request._loadSelection = 1
            } else {
                _bFill1.tintColor = FillColor
                _bFill1.backgroundColor = FillColor
                _bFill1.isEnabled = true
                
                request._loadSelection = 2
            }
            SetStatusB("\(request._adUnitId) loaded")
        }
    }
    
    private func SimOnAdFailedEvent(request: Track, status: Int) {
        if request._request == _trackA._request {
            if status == 2 {
                _aNoFill.tintColor = NoFillColor
                _aNoFill.backgroundColor = NoFillColor
                
                request._loadSelection = 3
            } else {
                _aOther.tintColor = NoFillColor
                _aOther.backgroundColor = NoFillColor
                
                request._loadSelection = 4
            }
            ToggleTrackA(isOn: false)
            SetStatusA("\(request._adUnitId) failed")
        } else {
            if status == 2 {
                _bNoFill.tintColor = NoFillColor
                _bNoFill.backgroundColor = NoFillColor
                
                request._loadSelection = 3
            } else {
                _bOther.tintColor = NoFillColor
                _bOther.backgroundColor = NoFillColor
                
                request._loadSelection = 4
            }
            ToggleTrackB(isOn: false)
            SetStatusB("\(request._adUnitId) failed")
        }
    }
    
    private func ToggleTrackA(isOn: Bool) {
        _aFill2.isEnabled = isOn
        _aFill1.isEnabled = isOn
        _aNoFill.isEnabled = isOn
        _aOther.isEnabled = isOn
        
        if isOn {
            _aFill2.tintColor = DefaultColor
            _aFill2.backgroundColor = DefaultBackgroundColor
            _aFill1.tintColor = DefaultColor
            _aFill1.backgroundColor = DefaultBackgroundColor
            _aNoFill.tintColor = DefaultColor
            _aNoFill.backgroundColor = DefaultBackgroundColor
            _aOther.tintColor = DefaultColor
            _aOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    private func ToggleTrackB(isOn: Bool) {
        _bFill2.isEnabled = isOn
        _bFill1.isEnabled = isOn
        _bNoFill.isEnabled = isOn
        _bOther.isEnabled = isOn
        
        if isOn {
            _bFill2.tintColor = DefaultColor
            _bFill2.backgroundColor = DefaultBackgroundColor
            _bFill1.tintColor = DefaultColor
            _bFill1.backgroundColor = DefaultBackgroundColor
            _bNoFill.tintColor = DefaultColor
            _bNoFill.backgroundColor = DefaultBackgroundColor
            _bOther.tintColor = DefaultColor
            _bOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    public func SetStatusA(_ status: String) {
        _aStatus.text = status
    }
    
    public func SetStatusB(_ status: String) {
        _bStatus.text = status
    }
    
    public func Show(title: String, onShow: @escaping (() -> Void), onClick: @escaping (() -> Void), onReward: (() -> Void)!, onClose: @escaping (() -> Void)) {
        _simulatorAd.Show(title: title, onShow: onShow, onClick: onClick, onReward: onReward, onClose: onClose)
    }
    
    public class SGADInterstitialAd : GADInterstitialAd {
        
        private var _request: GADRequest?
        
        public let _adUnitId: String
        public var _paidEventHandler: GADPaidEventHandler?
        public var _hasFill: Bool = false
        
        override var adUnitID: String { return _adUnitId }
        
        init(adUnitId: String) {
            _adUnitId = adUnitId
        }
        
        static override func load(withAdUnitID: String, request: GADRequest?) async throws -> SGADInterstitialAd {
            var adRequest: Track?
            if await InterstitialSim.Instance._trackA._request == request {
                adRequest = await InterstitialSim.Instance._trackA
                await InterstitialSim.Instance.ToggleTrackA(isOn: true)
                await InterstitialSim.Instance.SetStatusA("\(adRequest!._adUnitId) loading")
            } else {
                adRequest = await InterstitialSim.Instance._trackB
                await InterstitialSim.Instance.ToggleTrackB(isOn: true)
                await InterstitialSim.Instance.SetStatusB("\(adRequest!._adUnitId) loading")
            }
            
            adRequest!._loadSelection = 0
            while adRequest!._loadSelection == 0 {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            
            if adRequest!._loadSelection == 1 {
                let ad = SGADInterstitialAd(adUnitId: adRequest!._adUnitId)
                ad._request = request
                ad._hasFill = true
                return ad
            }
            if adRequest!._loadSelection == 2 {
                let ad = SGADInterstitialAd(adUnitId: adRequest!._adUnitId)
                ad._request = request
                ad._hasFill = true
                return ad
            }
            throw NSError(domain: "com.google.ads.mediation", code: adRequest!._loadSelection == 3 ? 1002 : 1000, userInfo: [GADErrorUserInfoKeyResponseInfo: SGADResponseInfo(status: adRequest!._loadSelection == 3 ? 2 : 0)])
        }
        
        override func canPresent(fromRootViewController rootViewController: UIViewController?) throws {
            if !_hasFill {
                throw NSError(domain: "com.google.ads.mediation", code: 404, userInfo: nil)
            }
        }
        
        override func present(fromRootViewController: UIViewController?) {
            _paidEventHandler!(SGADAdValue(value: 0.001, currencyCode: "USD"))
            
            InterstitialSim.Instance.Show(title: "Interstitial",
                                          onShow: { self.fullScreenContentDelegate!.adWillPresentFullScreenContent!(self) },
                                          onClick: { self.fullScreenContentDelegate!.adDidRecordClick!(self) },
                                          onReward: nil,
                                          onClose: { self.fullScreenContentDelegate!.adDidDismissFullScreenContent!(self) }
            )
            
            if InterstitialSim.Instance._trackA._request == _request {
                InterstitialSim.Instance.SetStatusA("Showing A")
            } else {
                InterstitialSim.Instance.SetStatusB("Showing B")
            }
        }
    }
    
    public class SGADResponseInfo : GADResponseInfo {
        private let _loadedAdNetworkResponseInfo: GADAdNetworkResponseInfo
        override var loadedAdNetworkResponseInfo: GADAdNetworkResponseInfo { return _loadedAdNetworkResponseInfo }
        init(status: Int) {
            _loadedAdNetworkResponseInfo = SGADAdNetworkResponseInfo(status: status)
        }
    }
    
    public class SGADAdNetworkResponseInfo: GADAdNetworkResponseInfo {
        private let _error: Error
        override var error: Error { return _error }
        init(status: Int) {
            _error = NSError(domain: "com.google.ads.network", code: 1000 + status, userInfo: [NSLocalizedDescriptionKey : status == 2 ? "No fill" : "Other"])
        }
    }
    
    public class SGADAdValue : GADAdValue {
        private let _value: Float64
        private let _currencyCode: String
        
        override var value: NSDecimalNumber { return NSDecimalNumber(value: _value) }
        override var currencyCode: String { return _currencyCode }
        override var precision: GADAdValuePrecision { return GADAdValuePrecision.estimated; }
        
        init(value: Float64, currencyCode: String) {
            _value = value
            _currencyCode = currencyCode
        }
    }
}
