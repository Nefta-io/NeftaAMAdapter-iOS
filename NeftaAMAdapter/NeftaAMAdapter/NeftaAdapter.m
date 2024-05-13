#import "NeftaAdapter.h"
#import "AdBannerNeftaRequest.h"
#import "InterstitialNeftaRequest.h"
#import "RewardedVideoNeftaRequest.h"

@implementation NeftaAdapter

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [NeftaExtras class];
}

NSString *_errorDomain = @"NeftaAMAdapter";
NSString *_idKey = @"parameter";

static NeftaPlugin_iOS *_plugin;
static NSMutableArray *_requests;

+ (GADVersionNumber)adSDKVersion {
    NSString *versionString = NeftaPlugin_iOS.Version;
    NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {
        versionComponents[0].integerValue,
        versionComponents[1].integerValue,
        versionComponents[2].integerValue};
    return version;
}

+ (GADVersionNumber)adapterVersion {
    GADVersionNumber version = {1, 1, 0};
    return version;
}

+ (void) setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    if (_plugin != nil) {
        completionHandler(nil);
        return;
    }

    _plugin = NeftaPlugin_iOS._instance;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_plugin == nil) {
            completionHandler([NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
            return;
        }
        [NeftaAdapter Init];
        
        completionHandler(nil);
    });
}

+ (void) Init {
    _plugin.OnLoadFail = ^(Placement *placement, NSString *error) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 0) {
                [r OnLoadFail: error];
                [_requests removeObject: r];
                return;
            }
        }
    };
    _plugin.OnLoad = ^(Placement *placement) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 0) {
                r._state = 1;
                [r OnLoad: placement];
                return;
            }
        }
    };
    _plugin.OnShow = ^(Placement *placement, NSInteger width, NSInteger height) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 1) {
                r._state = 2;
                [r OnShow: width height: height];
                return;
            }
        }
    };
    _plugin.OnClick = ^(Placement *placement) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 2) {
                [r OnClick];
                return;
            }
        }
    };
    _plugin.OnReward = ^(Placement *placement) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 2) {
                [r OnRewarded];
                return;
            }
        }
    };
    _plugin.OnClose = ^(Placement *placement) {
        for (int i = 0; i < _requests.count; i++) {
            id<NeftaRequest> r = _requests[i];
            if ([r._placementId isEqualToString: placement._id] && r._state == 2) {
                [r OnClose];
                [_requests removeObject: r];
                return;
            }
        }
    };
    
    _requests = [NSMutableArray array];
    
    [_plugin EnableAds: true];
}

- (void) loadBannerForAdConfiguration: (GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler: (GADMediationBannerLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }
    
    _ErrorDomain = _errorDomain;
    _Plugin = _plugin;

    AdBannerNeftaRequest *request = [AdBannerNeftaRequest Init: self placementId: placementId callback: completionHandler];
    [_requests addObject: request];

    UIApplication *application = [UIApplication sharedApplication];
    UIWindow *keyWindow = application.keyWindow;
    [_plugin PrepareRendererWithViewController: keyWindow.rootViewController];
    
    [_plugin LoadWithId: placementId];
}

- (void) loadInterstitialForAdConfiguration: (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler: (GADMediationInterstitialLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }
    
    _ErrorDomain = _errorDomain;
    _Plugin = _plugin;
    
    InterstitialNeftaRequest *request = [InterstitialNeftaRequest Init: self placementId: placementId callback: completionHandler];
    [_requests addObject: request];
    
    [_plugin LoadWithId: placementId];
}

- (void) loadRewardedAdForAdConfiguration: (GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler: (GADMediationRewardedLoadCompletionHandler)completionHandler {
    NSString* placementId = adConfiguration.credentials.settings[_idKey];
    if (placementId == nil || placementId.length == 0) {
        completionHandler(nil, [NSError errorWithDomain: _errorDomain code: NeftaAdapterErrorCodeInvalidServerParameters userInfo: nil]);
        return;
    }
    
    _ErrorDomain = _errorDomain;
    _Plugin = _plugin;
    
    RewardedVideoNeftaRequest *request = [RewardedVideoNeftaRequest Init: self placementId: placementId callback: completionHandler];
    NeftaExtras *extras = adConfiguration.extras;
    if (extras != nil) {
        request.muteAudio = extras.muteAudio;
    }
    [_requests addObject: request];
    
    [_plugin LoadWithId: placementId];
}

- (void) loadNativeAdForAdConfiguration: (GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler: (GADMediationNativeLoadCompletionHandler)completionHandler {
}

@end
