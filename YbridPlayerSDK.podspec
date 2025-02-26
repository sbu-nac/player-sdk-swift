#
# Run `pod_check.sh` to ensure this is a valid spec before submitting.
# 
# Submit this version to Cocoapod with 'pod_push.sh'.
#
Pod::Spec.new do |s|
  s.name             = 'YbridPlayerSDK'
  s.version          = '0.13.2'
  s.summary          = 'Audio player SDK for iOS.'
  s.description      = <<-DESC
Audio player SDK written in Swift supports audio codecs mp3, acc and opus.
This XCFramework runs on iOS devices and simulators version 9 to 14.
                       DESC
  s.homepage         = 'https://github.com/ybrid/player-sdk-swift'
  s.license          = { :type => 'MIT', :text => <<-LICENSE
  MIT License

  Copyright (c) 2021 nacamar GmbH - Ybrid®, a Hybrid Dynamic Live Audio Technology
  
      Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  
      The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  
  3rd party licenses
  This project uses [ogg-swift](https://github.com/ybrid/ogg-swift) and [opus-swift](https://github.com/ybrid/opus-swift).
  
  ogg
  Project ogg-swift makes use of the sources for ogg from [xiph.org/downloads](https://xiph.org/downloads/). 
  Ogg is licensed under the [New BSD License](https://wiki.xiph.org/XiphWiki:Copyrights).
  
      Copyright (c) 2002, Xiph.org Foundation
  
      The New BSD License states that:
  
      Redistribution and use in source and binary forms [of this work], with or without modification, are permitted provided that the following conditions are met:
      Redistributions of source code must retain the copyright notice, this list of conditions, and the following disclaimer.
      Redistributions in binary form must reproduce the copyright notice, this list of conditions, and the following disclaimer in the documentation, and/or other materials provided with the distribution.
      Neither the name of the Xiph.Org Foundation nor the names of its contributors may be used to endorse or promote products derived from this work without specific prior written permission.
      THIS WORK IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS WORK, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
  opus
  Project opus-swift creates the opus binaries from [opus-codec.org/downloads](https://opus-codec.org/downloads/).
  Both the reference implementation and the revised implementations on opus-codec.org are available under the three-clause BSD license. This BSD license is compatible with all common open source and commercial software licenses, see [details](https://opus-codec.org/license).
  
      Copyright 2001-2011 Xiph.Org, Skype Limited, Octasic, Jean-Marc Valin, Timothy B. Terriberry,
                          CSIRO, Gregory Maxwell, Mark Borgerding, Erik de Castro Lopo
  
      Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
      Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
      Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
      Neither the name of Internet Society, IETF or IETF Trust, nor the names of specific contributors, may be used to endorse or promote products derived from this software without specific prior written permission.
      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
      Opus is subject to the royalty-free patent licenses which are specified at:
  
      Xiph.Org Foundation:
      https://datatracker.ietf.org/ipr/1524/
  
      Microsoft Corporation:
      https://datatracker.ietf.org/ipr/1914/
  
      Broadcom Corporation:
      https://datatracker.ietf.org/ipr/1526/  
  
                      LICENSE
                  }
  s.author = { 'Florian Nowotny' => 'Florian.Nowotny@nacamar.de' }
  s.source = { :http => 'https://github.com/ybrid/player-sdk-swift/releases/download/'+s.version.to_s+'/YbridPlayerSDK.xcframework.zip'}
  
  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  # helpful for development pods, but submitting fails
  # s.source_files = 'player-sdk-swift/**/*.{swift}'
  # s.module_name = 'YbridPlayerSDK'

  s.framework    = 'YbridPlayerSDK'
  s.vendored_frameworks = 'YbridPlayerSDK.xcframework'

  s.dependency 'YbridOgg', '0.8.0'
  s.dependency 'YbridOpus', '0.8.0'
end
