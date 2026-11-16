# Randevumcepte softphone iOS koprusu. Yalnizca `tool/softphone.sh ac` ile
# uygulamaya girer; kapaliyken pod hic kurulmaz.
Pod::Spec.new do |s|
  s.name             = 'rc_softphone'
  s.version          = '1.0.0'
  s.summary          = 'CallKit ses koprusu + PushKit VoIP push (gelen cagri).'
  s.homepage         = 'https://randevumcepte.com.tr'
  s.license          = { :type => 'Proprietary', :text => 'Randevumcepte' }
  s.author           = { 'Randevumcepte' => 'destek@randevumcepte.com.tr' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  # Surum yazilmaz: flutter_webrtc'nin kilitledigi WebRTC-SDK surumu kullanilir.
  s.dependency 'WebRTC-SDK'
  # PushKit ile gelen cagriyi callkit'in CXProvider'i uzerinden gostermek icin.
  s.dependency 'flutter_callkit_incoming'
  s.static_framework = true
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
