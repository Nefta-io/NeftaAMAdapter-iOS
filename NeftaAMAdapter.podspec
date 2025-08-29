Pod::Spec.new do |s|
  s.name         = 'NeftaAMAdapter'
  s.version      = '4.3.2'
  s.summary      = 'Nefta Ad Network SDK for AdMob Mediation.'
  s.homepage     = 'https://docs.nefta.io/update/docs/admob-os'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaAMAdapter-iOS.git', :tag => 'REL_4.3.2' }

  s.ios.deployment_target = '10.0'

  s.swift_version = '5.0'

  s.source_files     = 'NeftaAMAdapter/**/GAD*.{h,m}'

  s.static_framework = true

  s.dependency 'NeftaSDK', '= 4.3.2'
  s.dependency 'Google-Mobile-Ads-SDK', '>= 8.0.0'
end
