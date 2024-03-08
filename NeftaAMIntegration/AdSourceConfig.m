//
// Copyright (C) 2017 Google, Inc.
//
//  AdSourceConfig.m
//  MediationExample
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AdSourceConfig.h"

NSString *const kAdapterBannerAdUnitID = @"ca-app-pub-1193175835908241/3398232026";
NSString *const kAdapterInterstitialAdUnitID = @"ca-app-pub-1193175835908241/4054554173";
NSString *const kAdapterRewardedAdUnitID = @"ca-app-pub-1193175835908241/1353682293";

@implementation AdSourceConfig

- (instancetype)init {
  self = [super init];
  return self;
}

- (NSString *)bannerAdUnitID {
    return kAdapterBannerAdUnitID;
}

- (NSString *)interstitialAdUnitID {
    return kAdapterInterstitialAdUnitID;
}

- (NSString *)nativeAdUnitID {
    return nil;
}

- (NSString *)rewardedAdUnitID {
    return kAdapterRewardedAdUnitID;
}

- (NSString *)title {
    return @"Nefta AdMob Adapter";
}

@end
