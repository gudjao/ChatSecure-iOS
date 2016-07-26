# Disable CocoaPods deterministic UUIDs as Pods are not checked in
ENV["COCOAPODS_DISABLE_DETERMINISTIC_UUIDS"] = "true"

# Disable Bitcode for all targets http://stackoverflow.com/a/32685434/805882
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

platform :ios, "8.0"

use_frameworks!
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

target 'ChatSecureCore' do
  pod 'AFNetworking', '~> 3.1'
  pod 'Appirater', '~> 2.0'
  pod 'OpenInChrome', '~> 0.0'
  pod 'MWFeedParser', '~> 1.0'
  pod 'CocoaLumberjack', '~> 2.0'
  pod 'HockeySDK-Source', '~> 3.7'
  pod 'MBProgressHUD', '~> 0.9'
  pod 'SSKeychain', '~> 1.2'
  # pod 'gtm-oauth2', '~> 0.1.0' # Trunk is outdated, using local podspec
  pod 'YapDatabase/SQLCipher', '~> 2.9'
  pod 'Mantle', '~> 2.0'
  pod 'Navajo', '~> 0.0'
  # wating on 8.0 https://github.com/jessesquires/JSQMessagesViewController/pull/840
  # using for in meantime
  # pod 'JSQMessagesViewController', '~> 8.0'
  pod 'BBlock', '~> 1.2'
  pod 'JVFloatLabeledTextField', '~> 1.0'
  pod 'TTTAttributedLabel', '~> 1.10'
  pod 'VTAcknowledgementsViewController', '~> 0.15'
  pod 'PureLayout', '~> 3.0'
  pod 'BButton', '~> 4.0'
  pod 'uservoice-iphone-sdk', '~> 3.2'
  pod 'TUSafariActivity', '~> 1.0'
  pod 'ARChromeActivity', '~> 1.0'
  # We need a commit from next release
  #pod 'CocoaAsyncSocket', '~> 7.4'
  #pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git', :commit => '071109901100334ad54ae704b4c644b6bb89ad21'
  pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git', :branch => 'master'
  
  pod 'JTSImageViewController', '~> 1.4'
  pod 'KVOController', '~> 1.0'
  #Reachability only needed for YapActionItems
  pod 'Reachability', '~> 3'
  pod 'XLForm', '~> 3.1'
  pod 'ParkedTextField', '~> 0.2'

  # QR Codes
  pod 'QRCodeReaderViewController', '~> 4.0'
  pod 'ZXingObjC', '~> 3.0'

  # Distribution
  pod 'Fabric'
  pod 'Crashlytics'
  
  # Local Podspecs
  pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec'
  pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec'
  #pod 'SQLCipher/fts', :podspec => 'Podspecs/SQLCipher.podspec.json'

  # Forks
  #pod 'JSQMessagesViewController', :git => 'https://github.com/ChatSecure/JSQMessagesViewController', :branch => '7.2.0-send_button'
  pod 'JSQMessagesViewController', :git => 'https://github.com/gudjao/JSQMessagesViewController.git', :branch => 'custom_7.3'
  pod 'JSQSystemSoundPlayer'
  
  # Submodules
  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'
  pod 'ProxyKit/Client', :path => 'Submodules/ProxyKit/ProxyKit.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'
  pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
  pod 'XMPPFramework', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'
  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
end
