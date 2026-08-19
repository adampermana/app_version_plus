#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint app_version_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'app_version_plus'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter package for checking app version updates across app stores.'
  s.description      = <<-DESC
A Flutter package for checking app version updates across Android, iOS, and Huawei app stores.
                       DESC
  s.homepage         = 'https://github.com/adampermana/app_version_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Adam Permana' => 'adampermana@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'

  s.resource_bundles = {'app_version_plus_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
