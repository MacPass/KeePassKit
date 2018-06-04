Pod::Spec.new do |s|
  s.name         = "KeePassKit"
  s.version      = "1.12"
  s.summary      = "KeePass Database loading, storing and manipulation framework."
  s.homepage     = "https://github.com/MacPass/KeePassKit"
  s.license      = "GPLv3"
  s.author       = { "Michael Starke" => "michael.starke@hicknhack-software.com" }
  s.source        = { :git => "https://github.com/MacPass/KeePassKit.git", :tag => s.version.to_s, :submodules => true }
  s.requires_arc  = true
  s.default_subspec = 'Core'

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.resources = "KeePassKit/Localization/*.lproj"

  s.subspec 'Core' do |ss|
    ss.source_files  = "KeePassKit/**/*.{h,m}"
    ss.private_header_files = "KeePassKit/**/*_Private.h", "KPKXmlTreeReader.h", "NSDate+KPKPacked.h"
    ss.dependency 'KissXML', '5.2.3'
    ss.dependency 'KeePassKit/Argon2'
    ss.dependency 'KeePassKit/ChaCha20'
    ss.dependency 'KeePassKit/TwoFish'

    ss.libraries = 'z'
  end

  s.subspec 'Argon2' do |ss|
    ss.source_files = "Argon2/src/*.{h,c}", "Argon2/include/*.h", "Argon2/src/blake2/*.{h,c}"
    ss.exclude_files = "Argon2/src/test.c", "Argon2/src/run.c", "Argon2/src/bench.c"
    ss.osx.exclude_files = "Argon2/src/ref.c", "Argon2/src/blake2/blamka-round-ref.h"
    ss.ios.exclude_files = "Argon2/src/opt.c", "Argon2/src/blake2/blamka-round-opt.h"
    ss.watchos.exclude_files = "Argon2/src/opt.c", "Argon2/src/blake2/blamka-round-opt.h"
    ss.tvos.exclude_files = "Argon2/src/opt.c", "Argon2/src/blake2/blamka-round-opt.h"
  end

  s.subspec 'ChaCha20' do |ss|
    ss.source_files = "ChaCha20/chacha20_simple.{h,c}"
  end

  s.subspec 'TwoFish' do |ss|
    ss.source_files = "TwoFish/twofish.{h,c}"
  end
end
