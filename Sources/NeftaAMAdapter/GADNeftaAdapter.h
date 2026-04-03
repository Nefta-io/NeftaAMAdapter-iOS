#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <NeftaSDK/NeftaSDK-Swift.h>

@interface GADNeftaAdapter : NSObject
typedef NS_ENUM(NSInteger, AdType) {
    AdTypeOther = 0,
    AdTypeBanner = 1,
    AdTypeInterstitial = 2,
    AdTypeRewarded = 3
};

+ (void)InitWithAppId:(NSString *_Nonnull)appId onReady:(void (^ _Nullable)(InitConfiguration * _Nonnull))onReady NS_SWIFT_NAME(Init(appId:onReady:));
+ (void)InitWithClientId:(NSString *_Nonnull)clientId onReady:(void (^ _Nullable)(InitConfiguration * _Nonnull))onReady NS_SWIFT_NAME(Init(clientId:onReady:));
+ (double) GetRetryDelayInSeconds:(AdInsight * _Nullable)insight NS_SWIFT_NAME(GetRetryDelayInSeconds(insight:));
+ (void) OnExternalMediationRequestWithInsight:(AdInsight * _Nonnull)insight request:(GADRequest * _Nonnull)request adUnitId:(NSString * _Nonnull)adUnitId;
+ (void) OnExternalMediationRequestWithInsight:(AdInsight * _Nonnull)insight request:(GADRequest * _Nonnull)request adUnitId:(NSString * _Nonnull)adUnitId customBidFloor:(double)customBidFloor;
+ (void) OnExternalMediationRequest:(AdType)adType request:(GADRequest * _Nonnull)request adUnitId:(NSString * _Nonnull)adUnitId;
+ (void) OnExternalMediationRequest:(AdType)adType request:(GADRequest * _Nonnull)request adUnitId:(NSString * _Nonnull)adUnitId customBidFloor:(double)customBidFloor;

+ (void) OnExternalMediationRequestLoadWithBanner:(GADBannerView * _Nonnull)banner request:(GADRequest * _Nonnull)request;
+ (void) OnExternalMediationRequestLoadWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial request:(GADRequest * _Nonnull)request;
+ (void) OnExternalMediationRequestLoadWithRewarded:(GADRewardedAd * _Nonnull)rewarded request:(GADRequest * _Nonnull)request;
+ (void) OnExternalMediationRequestFail:(GADRequest * _Nonnull)request error:(NSError * _Nonnull)error;

+ (void)OnExternalMediationImpressionWithBanner:(GADBannerView * _Nonnull)banner adValue:(GADAdValue* _Nonnull)adValue;
+ (void)OnExternalMediationImpressionWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial adValue:(GADAdValue* _Nonnull)adValue;
+ (void)OnExternalMediationImpressionWithRewarded:(GADRewardedAd * _Nonnull)rewarded adValue:(GADAdValue* _Nonnull)adValue;

+ (void)OnExternalMediationClickWithBanner:(GADBannerView * _Nonnull)banner;
+ (void)OnExternalMediationClickWithInterstitial:(GADInterstitialAd * _Nonnull)interstitial;
+ (void)OnExternalMediationClickWithRewarded:(GADRewardedAd * _Nonnull)rewarded;

+ (NSString * _Nullable) TryParseResponseInfo:(GADResponseInfo * _Nullable)responseInfo data:(NSMutableDictionary * _Nonnull)data;
@end
