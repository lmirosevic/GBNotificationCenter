Pod::Spec.new do |s|
  s.name         = 'GBNotificationCenter'
  s.version      = '1.0.2'
  s.summary      = 'A clean & elegant block based API for user notifications.'
  s.homepage     = 'https://github.com/lmirosevic/GBNotificationCenter'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Luka Mirosevic' => 'luka@goonbee.com' }
  s.platform     = :osx, '10.7'
  s.source       = { :git => 'https://github.com/lmirosevic/GBNotificationCenter.git', :tag => s.version.to_s }
  s.source_files  = 'GBNotificationCenter/*.{h,m}'
  s.public_header_files = 'GBNotificationCenter/*.h'
  s.requires_arc = true

  s.vendored_frameworks       = 'GBNotificationCenter/Growl.framework'
  s.preserve_paths            = 'GBNotificationCenter/Growl.framework'
  s.xcconfig                  = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited)' }

  s.dependency 'GBToolbox', '>= 3.13.2'
end
