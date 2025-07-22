#import "NeftaAdapter.h"
#import "NeftaBanner.h"
#import "NeftaInterstitial.h"
#import "NeftaRewarded.h"

NSString * const _mediationProvider = @"google-admob";

@implementation NeftaAdapter

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADNeftaExtras class];
}

+(void) OnExternalMediationRequestLoadWithBanner:(GADBannerView * _Nonnull)banner usedInsight:(AdInsight * _Nullable)usedInsight {
    [NeftaAdapter OnExternalMediationRequest: AdTypeBanner adUnitId: banner.adUnitID insight: usedInsight status: 1 providerStatus: nil networkStatus: nil];
}

+(void) OnExternalMediationRequestLoadWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial usedInsight:(AdInsight * _Nullable)usedInsight {
    [NeftaAdapter OnExternalMediationRequest: AdTypeInterstitial adUnitId: interstitial.adUnitID insight: usedInsight status: 1 providerStatus: nil networkStatus: nil];
}

+(void) OnExternalMediationRequestLoadWithRewarded:(GADRewardedAd * _Nonnull)rewarded usedInsight:(AdInsight * _Nullable)usedInsight {
    [NeftaAdapter OnExternalMediationRequest: AdTypeRewarded adUnitId: rewarded.adUnitID insight: usedInsight status: 1 providerStatus: nil networkStatus: nil];
}

+(void) OnExternalMediationRequestFail:(AdType)adType adUnitId:(NSString *)adUnitId usedInsight:(AdInsight * _Nullable)usedInsight error:(NSError *)error {
    int status = 0;
    if (error != nil && error.code == GADErrorNoFill) {
        status = 2;
    }
    NSString *providerStatus = [NSString stringWithFormat:@"%ld", error.code];
    NSString *networkStatus = nil;
    GADResponseInfo *responseInfo = error.userInfo[GADErrorUserInfoKeyResponseInfo];
    if (responseInfo != nil) {
        GADAdNetworkResponseInfo *adapterResponse = responseInfo.loadedAdNetworkResponseInfo;
        if (adapterResponse != nil) {
            NSError *adapterError = adapterResponse.error;
            if (adapterError != nil) {
                networkStatus = [NSString stringWithFormat:@"%ld", adapterError.code];
            }
        }
    }
    
    [NeftaAdapter OnExternalMediationRequest: adType adUnitId: adUnitId insight: usedInsight status: status providerStatus: providerStatus networkStatus: networkStatus];
}

+(void) OnExternalMediationRequest:(AdType)adType adUnitId:(NSString *)adUnitId insight:(AdInsight * _Nullable)insight status:(int)status providerStatus:(NSString *)providerStatus networkStatus:(NSString *)networkStatus {
    NSString *recommendedAdUnitId = nil;
    double calculatedFloorPrice = 0;
    if (insight != nil) {
        recommendedAdUnitId = insight._adUnit;
        calculatedFloorPrice = insight._floorPrice;
        
        if ((int)adType != insight._type) {
            NSLog(@"OnExternalMediationRequest reported adType: %ld doesn't match insight adType: %ld", adType, insight._type);
        }
    }
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: (int)adType recommendedAdUnitId: recommendedAdUnitId requestedFloorPrice: -1 calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: -1 precision: nil status: status providerStatus: providerStatus networkStatus: networkStatus];
}

+(void) OnExternalMediationImpressionWithBanner:(GADBannerView * _Nonnull)banner adValue:(GADAdValue*)adValue {
    [NeftaAdapter OnExternalMediationImpression: 1 adUnitId: banner.adUnitID responseInfo: banner.responseInfo adValue: adValue];
}

+(void) OnExternalMediationImpressionWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial adValue:(GADAdValue*)adValue {
    [NeftaAdapter OnExternalMediationImpression: 2 adUnitId: interstitial.adUnitID responseInfo: interstitial.responseInfo adValue: adValue];
}

+(void) OnExternalMediationImpressionWithRewarded:(GADRewardedAd * _Nonnull)rewarded adValue:(GADAdValue*)adValue {
    [NeftaAdapter OnExternalMediationImpression: 3 adUnitId: rewarded.adUnitID responseInfo: rewarded.responseInfo adValue: adValue];
}

+(void) OnExternalMediationImpression:(int)type adUnitId:(NSString *)adUnitId responseInfo:(GADResponseInfo * _Nullable)responseInfo adValue:(GADAdValue*)adValue {
    NSString *adType = @"";
    if (type == 0) {
        adType = @"banner";
    } else if (type == 1) {
        adType = @"interstitial";
    } else if (type == 2) {
        adType = @"rewarded";
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject: adType forKey: adType];
    [data setObject: adUnitId forKey: @"ad_unit_id"];
    [data setObject: adValue.value forKey: @"value"];
    [data setObject: @(adValue.precision) forKey: @"precision"];
    [data setObject: adValue.currencyCode forKey: @"currency_code"];
    
    NSString *networkName = nil;
    if (responseInfo != nil) {
        if (responseInfo.extrasDictionary != nil) {
            NSString* placement = responseInfo.extrasDictionary[@"mediation_group_name"];
            if (placement != nil) {
                [data setObject: placement forKey: @"placement_name"];
            }
        }
        
        GADAdNetworkResponseInfo *adapterResponse = responseInfo.loadedAdNetworkResponseInfo;
        if (adapterResponse != nil) {
            networkName = adapterResponse.adSourceInstanceName;
            [data setObject: networkName forKey: @"network_name"];
        }
        
        NSMutableArray *waterfalls = [NSMutableArray array];
        for (GADAdNetworkResponseInfo *other in responseInfo.adNetworkInfoArray) {
            [waterfalls addObject: other.adSourceInstanceName];
        }
        [data setObject: waterfalls forKey: @"waterfall"];
    }
    
    NSString* auctionId = nil;
    NSString* creativeId = nil;
    bool isNeftaNetwork = [networkName caseInsensitiveCompare: @"nefta"] == NSOrderedSame;
    if (isNeftaNetwork) {
        if (type == 1) {
            auctionId = NeftaBanner.GetLastAuctionId;
            creativeId = NeftaBanner.GetLastCreativeId;
        } else if (type == 2) {
            auctionId = NeftaInterstitial.GetLastAuctionId;
            creativeId = NeftaInterstitial.GetLastCreativeId;
        } else if (type == 3) {
            auctionId = NeftaRewarded.GetLastAuctionId;
            creativeId = NeftaRewarded.GetLastCreativeId;
        }
    }
    if (auctionId != nil) {
        [data setObject: auctionId forKey: @"ad_opportunity_id"];
    }
    if (creativeId != nil) {
        [data setObject: creativeId forKey: @"creative_id"];
    }

    NSString *precisionAsString = [NSString stringWithFormat:@"%ld", adValue.precision];
    [NeftaPlugin OnExternalMediationImpression: _mediationProvider data: data adType: type revenue: [adValue.value doubleValue] precision: precisionAsString];
}

+ (void) OnExternalMediationImpressionAsString:(int)adType network:(NSString*)network data:(NSString *)data revenue:(double)revenue precision:(NSString *)precision {
    NSString *auctionId = nil;
    NSString *creativeId = nil;
    if ([network caseInsensitiveCompare: @"nefta"] == NSOrderedSame) {
        if (adType == 1) {
            auctionId = NeftaBanner.GetLastAuctionId;
            creativeId = NeftaBanner.GetLastCreativeId;
        } else if (adType == 2) {
            auctionId = NeftaInterstitial.GetLastAuctionId;
            creativeId = NeftaInterstitial.GetLastCreativeId;
        } else if (adType == 3) {
            auctionId = NeftaRewarded.GetLastAuctionId;
            creativeId = NeftaRewarded.GetLastCreativeId;
        }
    }
    
    NSMutableString *sb = [[NSMutableString alloc] initWithString: data];
    [sb appendString: @",\"network_name\":\""];
    [sb appendString: network];
    if (auctionId != nil) {
        [sb appendString: @"\",\"ad_opportunity_id\":\""];
        [sb appendString: auctionId];
    }
    if (creativeId != nil) {
        [sb appendString: @"\",\"creative_id\":\""];
        [sb appendString: creativeId];
    }
    [sb appendString: @"\",\"precision\":"];
    [sb appendString: precision];
    [sb appendString: @",\"revenue\":"];
    [sb appendFormat: @"%f", revenue];
    
    [NeftaPlugin OnExternalMediationImpressionAsString: _mediationProvider data: sb adType: adType revenue: revenue precision: precision];
}

NSString *_errorDomain = @"NeftaAMAdapter";
NSString *_idKey = @"parameter";

static NeftaPlugin *_plugin;

+ (GADVersionNumber)adSDKVersion {
    NSString *versionString = NeftaPlugin.Version;
    NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {
        versionComponents[0].integerValue,
        versionComponents[1].integerValue,
        versionComponents[2].integerValue};
    return version;
}

+ (GADVersionNumber)adapterVersion {
    GADVersionNumber version = {4, 3, 0};
    return version;
}

+ (void) setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    if (_plugin != nil) {
        completionHandler(nil);
        return;
    }

    _plugin = NeftaPlugin._instance;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_plugin == nil) {
            completionHandler([NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
            return;
        }
        
        completionHandler(nil);
    });
}

- (void) loadBannerForAdConfiguration: (GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler: (GADMediationBannerLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }

    NeftaBanner *banner = [NeftaBanner Init: placementId listener: completionHandler errorDomain: _errorDomain];
    [banner Load];
}

- (void) loadInterstitialForAdConfiguration: (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler: (GADMediationInterstitialLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }
    
    NeftaInterstitial *interstitial = [NeftaInterstitial Init: placementId listener: completionHandler errorDomain: _errorDomain];
    interstitial.extras = adConfiguration.extras;
    [interstitial Load];
}

- (void) loadRewardedAdForAdConfiguration: (GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler: (GADMediationRewardedLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }
    
    NeftaRewarded *rewaded = [NeftaRewarded Init: placementId listener: completionHandler errorDomain: _errorDomain];
    rewaded.extras = adConfiguration.extras;
    [rewaded Load];
}

- (void) loadNativeAdForAdConfiguration: (GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler: (GADMediationNativeLoadCompletionHandler)completionHandler {
}

+ (NSError *) NLoadToAdapterError: (NError *)error {
    GADErrorCode code = GADErrorInternalError;
    if (error._code == CodeRequest) {
        code = GADErrorInvalidRequest;
    } else if (error._code == CodeNetwork) {
        code = GADErrorNetworkError;
    } else if (error._code == CodeNoFill) {
        code = GADErrorNoFill;
    } else if (error._code == CodeTimeout) {
        code = GADErrorTimeout;
    } else if (error._code == CodeResponse) {
        code = GADErrorInvalidArgument;
    }
    NSDictionary *userInfo = @ { NSLocalizedDescriptionKey: error._message };
    return [NSError errorWithDomain: _errorDomain code: error._code userInfo: userInfo];
}

@end

#ifdef __cplusplus
extern "C" {
#endif
    typedef void (*OnInsights)(int requestId, const char *insights);
    
    void EnableLogging(bool enable);
    void NeftaPlugin_Init(const char *appId, OnInsights onInsights);
    void NeftaPlugin_Record(int type, int category, int subCategory, const char *name, long value, const char *customPayload);
    void NeftaPlugin_OnExternalMediationRequest(const char *mediationProvider, int adType, const char *recommendedAdUnitId, double requestedFloorPrice, double calculatedFloorPrice, const char *adUnitId, double revenue, const char *precision, int status, const char *providerStatus, const char *networkStatus);
    void NeftaAdapter_OnExternalMediationImpressionAsString(int adType, const char *network, const char *data, double revenue, const char *precision);
    const char * NeftaPlugin_GetNuid(bool present);
    void NeftaPlugin_SetContentRating(const char *rating);
    void NeftaPlugin_GetInsights(int requestId, int insights, int timeoutInSeconds);
    void NeftaPlugin_SetOverride(const char *root);
#ifdef __cplusplus
}
#endif

void NeftaPlugin_EnableLogging(bool enable) {
    [NeftaPlugin EnableLogging: enable];
}

void NeftaPlugin_Init(const char *appId, OnInsights onInsights) {
    _plugin = [NeftaPlugin InitWithAppId: [NSString stringWithUTF8String: appId]];
    _plugin.OnInsightsAsString = ^void(NSInteger requestId, NSString * _Nullable insights) {
        const char *cBI = insights ? [insights UTF8String] : NULL;
        onInsights((int)requestId, cBI);
    };
}

void NeftaPlugin_Record(int type, int category, int subCategory, const char *name, long value, const char *customPayload) {
    NSString *n = name ? [NSString stringWithUTF8String: name] : nil;
    NSString *cp = customPayload ? [NSString stringWithUTF8String: customPayload] : nil;
    [_plugin RecordWithType: type category: category subCategory: subCategory name: n value: value customPayload: cp];
}

void NeftaPlugin_OnExternalMediationRequest(const char *mediationProvider, int adType, const char *recommendedAdUnitId, double requestedFloorPrice, double calculatedFloorPrice, const char *adUnitId, double revenue, const char *precision, int status, const char *providerStatus, const char *networkStatus) {
    NSString *mP = mediationProvider ? [NSString stringWithUTF8String: mediationProvider] : nil;
    NSString *r = recommendedAdUnitId ? [NSString stringWithUTF8String: recommendedAdUnitId] : nil;
    NSString *a = adUnitId ? [NSString stringWithUTF8String: adUnitId] : nil;
    NSString *p = precision ? [NSString stringWithUTF8String: precision] : nil;
    NSString *pS = providerStatus ? [NSString stringWithUTF8String: providerStatus] : nil;
    NSString *nS = networkStatus ? [NSString stringWithUTF8String: networkStatus] : nil;
    [NeftaPlugin OnExternalMediationRequest: mP adType: adType recommendedAdUnitId: r requestedFloorPrice: requestedFloorPrice calculatedFloorPrice: calculatedFloorPrice adUnitId: a revenue: revenue precision: p status: status providerStatus: pS networkStatus: nS];
}

void NeftaAdapter_OnExternalMediationImpressionAsString(int adType, const char *network, const char *data, double revenue, const char *precision) {
    NSString *n = network ? [NSString stringWithUTF8String: network] : nil;
    NSString *d = data ? [NSString stringWithUTF8String: data] : nil;
    NSString *p = precision ? [NSString stringWithUTF8String: precision] : nil;
    [NeftaAdapter OnExternalMediationImpressionAsString: adType network: n data: d revenue: revenue precision: p];
}

const char * NeftaPlugin_GetNuid(bool present) {
    const char *string = [[_plugin GetNuidWithPresent: present] UTF8String];
    char *returnString = (char *)malloc(strlen(string) + 1);
    strcpy(returnString, string);
    return returnString;
}

void NeftaPlugin_SetContentRating(const char *rating) {
    [_plugin SetContentRatingWithRating: [NSString stringWithUTF8String: rating]];
}

void NeftaPlugin_GetInsights(int requestId, int insights, int timeoutInSeconds) {
    [_plugin GetInsightsBridge: requestId insights: insights timeout: timeoutInSeconds];
}

void NeftaPlugin_SetOverride(const char *root) {
    [NeftaPlugin SetOverrideWithUrl: [NSString stringWithUTF8String: root]];
}
