Pod::Spec.new do |s|
  s.name         = 'NeftaAMAdapter'
  s.version      = '1.0.0'
  s.summary      = 'Custom mediation adapter for Google AdMob SDK.'
  s.homepage     = 'https://docs-adnetwork.nefta.io/docs/admob-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaAMAdapter.git', :tag => '1.0.0' }

  s.ios.deployment_target = '11.0'

  s.dependency 'NeftaSDK', '~> 3.2.3'
  s.source_files = 'NeftaAMAdapter/NeftaAMAdapter/*.{h,m}'
end
