#import "GADNeftaAdapter.h"

NSString * const _mediationProvider = @"google-admob";

@implementation GADNeftaAdapter

+ (void)InitWithAppId:(NSString *)appId onReady:(void (^ _Nullable)(InitConfiguration * _Nonnull))onReady {
    GADVersionNumber version = GADMobileAds.sharedInstance.versionNumber;
    NSString * mediationVersion = [NSString stringWithFormat:@"%ld.%ld.%ld",(long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
    (void)[NeftaPlugin NativeInitWithAppId: appId clientId: nil onReady: onReady integration: @"native-google-admob" mediationVersion: mediationVersion];
}
+ (void)InitWithClientId:(NSString *)clientId onReady:(void (^ _Nullable)(InitConfiguration * _Nonnull))onReady {
    GADVersionNumber version = GADMobileAds.sharedInstance.versionNumber;
    NSString * mediationVersion = [NSString stringWithFormat:@"%ld.%ld.%ld",(long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
    (void)[NeftaPlugin NativeInitWithAppId: nil clientId: clientId onReady: onReady integration: @"native-google-admob" mediationVersion: mediationVersion];
}

+ (double) GetRetryDelayInSeconds:(AdInsight * _Nullable)insight {
    return (double)[NeftaPlugin GetRetryDelayInSeconds: insight];
}

+ (void) OnExternalMediationRequestWithInsight:(AdInsight * _Nonnull)insight request:(GADRequest * _Nonnull)request adUnitId:(NSString *)adUnitId {
    [GADNeftaAdapter OnExternalMediationRequestWithInsight: insight request: request adUnitId: adUnitId customBidFloor: insight._floorPrice];
}

+ (void) OnExternalMediationRequestWithInsight:(AdInsight * _Nonnull)insight request:(GADRequest * _Nonnull)request adUnitId:(NSString *)adUnitId customBidFloor:(double)customBidFloor {
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    int adType = (int) insight._type;
    int requestId = (int)insight._requestId;
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: adType id: id0 requestedAdUnitId: adUnitId requestedFloorPrice: customBidFloor requestId:requestId];
}

+ (void) OnExternalMediationRequest:(AdType)adType request:(GADRequest * _Nonnull)request adUnitId:(NSString *)adUnitId {
    [GADNeftaAdapter OnExternalMediationRequest: adType request: request adUnitId: adUnitId customBidFloor: -1];
}

+ (void) OnExternalMediationRequest:(AdType)adType request:(GADRequest * _Nonnull)request adUnitId:(NSString *)adUnitId customBidFloor:(double)customBidFloor {
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: (int)adType id: id0 requestedAdUnitId: adUnitId requestedFloorPrice: customBidFloor requestId: -1];
}

+ (void) OnExternalMediationRequestLoadWithBanner:(GADBannerView * _Nonnull)banner request:(GADRequest * _Nonnull)request {
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[banner hash]];
    [GADNeftaAdapter OnExternalMediationResponse: id0 id2: id2 responseInfo: banner.responseInfo];
}
+ (void) OnExternalMediationRequestLoadWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial request:(GADRequest * _Nonnull)request {
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[interstitial hash]];
    [GADNeftaAdapter OnExternalMediationResponse: id0 id2: id2 responseInfo: interstitial.responseInfo];
}
+ (void) OnExternalMediationRequestLoadWithRewarded:(GADRewardedAd * _Nonnull)rewarded request:(GADRequest * _Nonnull)request {
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[rewarded hash]];
    [GADNeftaAdapter OnExternalMediationResponse: id0 id2: id2 responseInfo: rewarded.responseInfo];
}
+ (void) OnExternalMediationResponse:(NSString *)id0 id2:(NSString * _Nonnull)id2 responseInfo:(GADResponseInfo *)responseInfo {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [GADNeftaAdapter TryParseResponseInfo: responseInfo data: data];
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: id0 id2: id2 revenue: -1 precision: nil status: 1 providerStatus: nil networkStatus: nil baseObject: nil];
}

+ (void) OnExternalMediationRequestFail:(GADRequest * _Nonnull)request error:(NSError *)error {
    int status = 0;
    if (error != nil && error.code == GADErrorNoFill) {
        status = 2;
    }
    NSString *providerStatus = [NSString stringWithFormat:@"%ld", error.code];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSString *networkStatus = [GADNeftaAdapter TryParseResponseInfo: error.userInfo[GADErrorUserInfoKeyResponseInfo] data: data];
    
    NSString *id0 = [NSString stringWithFormat:@"%lu", (unsigned long)[request hash]];
    
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: id0 id2: nil revenue: -1 precision: nil status: status providerStatus: providerStatus networkStatus: networkStatus baseObject: data];
}

+ (NSString *) TryParseResponseInfo:(GADResponseInfo *)responseInfo data:(NSMutableDictionary *)data {
    if (responseInfo != nil) {
        id placement = responseInfo.extrasDictionary[@"mediation_group_name"];
        if (placement != nil) {
            if ([placement isKindOfClass:[NSString class]]) {
                [data setObject: (NSString *)placement forKey: @"placement"];
            } else if ([placement respondsToSelector:@selector(stringValue)]) {
                [data setObject: [placement stringValue] forKey: @"placement"];
            }
        }
        
        NSArray<GADAdNetworkResponseInfo *> * networkArray = responseInfo.adNetworkInfoArray;
        if (networkArray != nil) {
            NSMutableArray *waterfall = [NSMutableArray array];
            for (GADAdNetworkResponseInfo *network in networkArray) {
                if (network.adSourceName != nil) {
                    [waterfall addObject: network.adSourceName];
                }
            }
            [data setObject: waterfall forKey: @"waterfall"];
        }
        
        GADAdNetworkResponseInfo *loadedAdapter = responseInfo.loadedAdNetworkResponseInfo;
        if (loadedAdapter != nil) {
            if (loadedAdapter.adSourceName != nil) {
                [data setObject: loadedAdapter.adSourceName forKey: @"network_name"];
            }
            NSError *adapterError = loadedAdapter.error;
            if (adapterError != nil) {
                return [NSString stringWithFormat:@"%ld", adapterError.code];
            }
        }
    }
    return nil;
}

+ (void) OnExternalMediationImpressionWithBanner:(GADBannerView * _Nonnull)banner adValue:(GADAdValue*)adValue {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[banner hash]];
    [GADNeftaAdapter OnExternalMediationImpression: false type: 1 adUnitId: banner.adUnitID id2: id2 responseInfo: banner.responseInfo adValue: adValue];
}
+ (void) OnExternalMediationImpressionWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial adValue:(GADAdValue*)adValue {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[interstitial hash]];
    [GADNeftaAdapter OnExternalMediationImpression: false type: 2 adUnitId: interstitial.adUnitID id2: id2 responseInfo: interstitial.responseInfo adValue: adValue];
}
+ (void) OnExternalMediationImpressionWithRewarded:(GADRewardedAd * _Nonnull)rewarded adValue:(GADAdValue*)adValue {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[rewarded hash]];
    [GADNeftaAdapter OnExternalMediationImpression: false type: 3 adUnitId: rewarded.adUnitID id2: id2 responseInfo: rewarded.responseInfo adValue: adValue];
}

+ (void) OnExternalMediationClickWithBanner:(GADBannerView * _Nonnull)banner {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[banner hash]];
    [GADNeftaAdapter OnExternalMediationImpression: true type: 1 adUnitId: banner.adUnitID id2: id2 responseInfo: banner.responseInfo adValue: nil];
}
+ (void) OnExternalMediationClickWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[interstitial hash]];
    [GADNeftaAdapter OnExternalMediationImpression: true type: 2 adUnitId: interstitial.adUnitID id2: id2 responseInfo: interstitial.responseInfo adValue: nil];
}
+ (void) OnExternalMediationClickWithRewarded:(GADRewardedAd * _Nonnull)rewarded {
    NSString *id2 = [NSString stringWithFormat:@"%lu", (unsigned long)[rewarded hash]];
    [GADNeftaAdapter OnExternalMediationImpression: true type: 3 adUnitId: rewarded.adUnitID id2: id2 responseInfo: rewarded.responseInfo adValue: nil];
}

+ (void) OnExternalMediationImpression:(BOOL)isClick type:(int)type adUnitId:(NSString *)adUnitId id2:(NSString * _Nonnull)id2 responseInfo:(GADResponseInfo * _Nullable)responseInfo adValue:(GADAdValue*)adValue {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject: adUnitId forKey: @"ad_unit_id"];
    if (adValue != nil) {
        [data setObject: adValue.value forKey: @"value"];
        [data setObject: @(adValue.precision) forKey: @"precision"];
        [data setObject: adValue.currencyCode forKey: @"currency_code"];
    }
    
    [GADNeftaAdapter TryParseResponseInfo: responseInfo data: data];
    
    [NeftaPlugin OnExternalMediationImpression: isClick provider: _mediationProvider data: data id: nil id2: id2];
}
@end
