#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_classic_bluetooth.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_classic_bluetooth'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flutter_classic_bluetooth/Sources/**/*'
  s.resource_bundles = {'flutter_classic_bluetooth_privacy' => ['flutter_classic_bluetooth/Sources/flutter_classic_bluetooth/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.frameworks = ['IOBluetooth']
end
