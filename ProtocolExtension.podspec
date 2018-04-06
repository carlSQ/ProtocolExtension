
Pod::Spec.new do |s|
  s.name             = 'ProtocolExtension'
  s.version          = '0.2.0'
  s.summary          = 'protocol extension for Objective-C like Swift'



  s.description      = <<-DESC
                        protocol extension for Objective-C like Swift
                        protocol 参数目前只支持Object
                       DESC

  s.homepage         = 'https://github.com/carlSQ/ProtocolExtension'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '83515077@qq.com' => 'carlSQ' }
  s.source           = { :git => 'https://github.com/carlSQ/ProtocolExtension.git', :tag => s.version.to_s }


  s.ios.deployment_target = '8.0'

  s.source_files = 'ProtocolExtension/Classes/**/*.{h,m}'
  s.ios.public_header_files = 'ProtocolExtension/Classes/*.h'
  s.vendored_libraries = 'ProtocolExtension/Classes/libffi/libffi.a'
end
