source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
workspace 'NeftaAMIntegration'

target 'NeftaAMIntegration' do
  project 'NeftaAMIntegration.xcodeproj'
  pod 'Google-Mobile-Ads-SDK', '~> 10.4'
  pod 'NeftaAMAdapter', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'NeftaAMAdapter'
      framework_ref = installer.pods_project.reference_for_path(File.dirname(__FILE__) + '/Pods/Google-Mobile-Ads-SDK/Frameworks/GoogleMobileAdsFramework/GoogleMobileAds.xcframework')
      target.frameworks_build_phase.add_file_reference(framework_ref, true)
    end
  end
end
