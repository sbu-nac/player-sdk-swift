//
// YbridSpecialActionTests.swift
// player-sdk-swiftTests
//
// Copyright (c) 2021 nacamar GmbH - Ybrid®, a Hybrid Dynamic Live Audio Technology
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import XCTest
@testable import YbridPlayerSDK

class YbridSpecialActionTests: XCTestCase {
    
    let maxCtrlCompleteUs:useconds_t = 1_500_000
    
    var listener = ErrorListener()
    override func setUpWithError() throws {
    }
    override func tearDownWithError() throws {
        listener.cleanUp()
    }

    func test01_ReconnectSession_ok() throws {
        let semaphore = DispatchSemaphore(value: 0)
        
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: listener,
            playbackControl: { (c) in return },
            ybridControl: { (ybridControl) in
            guard let ybrid = ybridControl as? YbridAudioPlayer,
                  let state = ybrid.session.mediaState,
                  let v2 = ybrid.session.driver as? YbridV2Driver else {
                      XCTFail(); semaphore.signal(); return
                  }
            
            print("base uri is \(state.baseUrl)")
            let baseUrlOrig = state.baseUrl
            
            
            // forcing to reconnect
            do {
                try v2.reconnect()
            } catch {
                Logger.session.error(error.localizedDescription)
                XCTFail("should work, but \(error.localizedDescription)")
            }
            print("base uri is \(state.baseUrl)")
            let baseUrlReconnected = state.baseUrl
            XCTAssertEqual(baseUrlOrig, baseUrlReconnected)
            
            ybrid.play()
            print("base uri is \(state.baseUrl)")
            
            
            sleep(4)
            ybridControl.close()
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: .distantFuture)
        let errCount = listener.errors.count
        guard errCount == 0 else {
            XCTFail("error during recreating session \(listener.errors)")
            return
        }
    }

    
    func test02_limitBitrates_AllMp3Supported() throws {
        let bitrates = [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112,
                        128, 160, 192, 224, 256, 320, 352, 384, 416, 448]
        
        let semaphore = DispatchSemaphore(value: 0)
        var adoptedRates:[Int32] = []
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: listener,
             playbackControl: { (c) in
                return },
             ybridControl: { (ybridControl) in
                guard let ybrid = ybridControl as? YbridAudioPlayer else {
                    XCTFail(); semaphore.signal(); return
                }
                ybrid.play()
                sleep(4)
                
                bitrates.forEach{
                    let kbps = Int32($0)*1000
                    ybrid.maxBitRate(to:kbps)
                    usleep(self.maxCtrlCompleteUs)
                    XCTAssertEqual(kbps, ybrid.session.mediaState?.maxBitRate)
                    if kbps == ybrid.session.mediaState?.maxBitRate {
                        adoptedRates.append(kbps)
                    }
                }
                
                ybridControl.close()
                sleep(1)
                semaphore.signal()
             })
        _ = semaphore.wait(timeout: .distantFuture)
        let errCount = listener.errors.count
        guard errCount == 0 else {
            XCTFail("set max bit-rate raised error \(listener.errors)")
            return
        }
        print("adopted bit rates are \(adoptedRates)")
    }

    func test03_limitBitrateVague_ok() throws {
        let semaphore = DispatchSemaphore(value: 0)
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: listener,
             playbackControl: { (_) in
                return },
             ybridControl: { [self] (ybridControl) in
                guard let ybrid = ybridControl as? YbridAudioPlayer else {
                    XCTFail(); semaphore.signal(); return
                }
                ybrid.play()
                sleep(4)
                XCTAssertNil(ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:77)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(8_000, ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:31_000)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(32_000, ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:57_000)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(64_000, ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:191_999)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(192_000, ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:447_000)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(448_000, ybrid.session.mediaState?.maxBitRate)
                
                
                ybrid.maxBitRate(to:449_000)
                usleep(maxCtrlCompleteUs)
                // unchanged
                XCTAssertEqual(448_000, ybrid.session.mediaState?.maxBitRate)
                
                ybrid.maxBitRate(to:390291781)
                usleep(maxCtrlCompleteUs)
                XCTAssertEqual(448_000, ybrid.session.mediaState?.maxBitRate)
                
                ybridControl.close()
                usleep(maxCtrlCompleteUs)
                semaphore.signal()
             })
        _ = semaphore.wait(timeout: .distantFuture)
        let errCount = listener.errors.count
        guard errCount == 0 else {
            XCTFail("set max bit-rate raised error \(listener.errors)")
            return
        }
    }    
    
}

