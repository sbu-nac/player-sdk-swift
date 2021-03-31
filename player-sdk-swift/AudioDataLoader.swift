//
// AudioDataLoader.swift
// player-sdk-swift
//
// Copyright (c) 2020 nacamar GmbH - Ybrid®, a Hybrid Dynamic Live Audio Technology
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


import Foundation
import AVFoundation
import Network

class AudioDataLoader: NSObject, URLSessionDataDelegate, NetworkListener, MemoryListener {

    let url: URL
    let pipeline: AudioPipeline
    private let withMetadata: Bool
    private let configuration: URLSessionConfiguration
    
    private var session: URLSession?
    private var taskState:SessionTaskState?
    private var stalled:Bool = false {
        didSet {
            if oldValue != stalled {
                Logger.loading.notice("loading data stalled \(stalled)")
            }
        }
    }
    private var sessionStarted: Date?
    
    var completed:Bool { get {
        guard let state = taskState else {
            return false
        }
        return state.completed
    }}
    
    init(mediaUrl: URL, pipeline: AudioPipeline, inclMetadata: Bool = true) {
        self.url = mediaUrl
        self.pipeline = pipeline
        self.withMetadata = inclMetadata
        configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.networkServiceType = NSURLRequest.NetworkServiceType.avStreaming
        configuration.timeoutIntervalForRequest = 10.0
        super.init()
    }
    
    deinit {
        Logger.loading.debug()
        stopRequestData()
    }
    
    func requestData(from url: URL) {
        Logger.loading.debug()
        PlayerContext.register(listener: self)
        PlayerContext.registerMemoryListener(listener: self)
        startSession(configuration: configuration)
    }
    
    func stopRequestData() {
        Logger.loading.debug()
        endSession()
        PlayerContext.unregister(listener: self)
        PlayerContext.unregisterMemoryListener(listener: self)
        stalled = false
    }
    
    fileprivate func startSession(configuration: URLSessionConfiguration) {
        Logger.loading.debug()
        sessionStarted = Date()
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        var request: URLRequest = URLRequest(url: url)
        if withMetadata {
            request.setValue("1", forHTTPHeaderField: "Icy-MetaData")
        }
        let sessionTask = session?.dataTask(with: request)
        sessionTask?.resume()
    }
    
    fileprivate func endSession() {
        if let session = session {
            session.invalidateAndCancel()
            self.session = nil
        }
    }
    
    // MARK: handle memory
    
    func notifyExceedsMemoryLimit() {
        Logger.loading.notice("stop loading due to memory limit")
        stopRequestData()
    }
    
    
    // MARK: handling network
    
    func notifyNetworkChanged(_ connected: Bool) {
        Logger.loading.notice("connected=\(connected), stalled=\(stalled)")
        if !connected {
            return
        }
        if stalled {
            resumeRequestData()
        }
    }
    
    fileprivate func resumeRequestData() {
        Logger.loading.debug()
        endSession()
        startSession(configuration: configuration)
        pipeline.resume() /// also buffer is cleared
        pipeline.pipelineListener.error(ErrorSeverity.notice, LoadingError( ErrorKind.noError, "resume loading data"))
    }
    
    fileprivate func networkStalled(_ cause:SessionTaskState) {
        guard PlayerContext.networkMonitor.isConnectedToNetwork() == false else {
            resumeRequestData()
            return
        }
        stalled = true
        let error = LoadingError(ErrorKind.networkStall, cause)
        pipeline.pipelineListener.error(ErrorSeverity.recoverable, error)
    }
    
    // MARK: session begins
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        Logger.loading.notice("didReceive response for task \(dataTask.taskIdentifier)")
        if let started = sessionStarted {
            pipeline.playerListener?.durationConnected(Date().timeIntervalSince(started))
        }
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
        
        if response is HTTPURLResponse {
            handleMetadata(response as! HTTPURLResponse)
        }
        
        do {
            try handleMediaType(response, session)
        } catch {
            if let playerError = error as? AudioPlayerError {
                pipeline.pipelineListener.error(ErrorSeverity.fatal, playerError)
            } else  {
                pipeline.pipelineListener.error(ErrorSeverity.fatal, LoadingError( ErrorKind.unknown, "cannot handle media type", error))
            }
            endSession()
        }
        return
    }
    
    private func handleMetadata(_ httpResp: HTTPURLResponse) {
        let icyMetadata = getHeaders(httpResp, fieldsStartingWith: "icy-")
        Logger.loading.debug("icy-fields: \(icyMetadata)")
        
        if withMetadata, let metaint = icyMetadata["icy-metaint"] {
            guard let metadataEveryBytes = Int(metaint) else {
                Logger.loading.error("invalid icy-metaint value '\(metaint)'")
                return
            }
            pipeline.prepareMetadata(metadataInverallB: metadataEveryBytes)
            Logger.loading.info("icy-metadata every \(metadataEveryBytes) bytes")
        }
    }
    
    private func getHeaders(_ httpResp: HTTPURLResponse, fieldsStartingWith:String) -> [String:String]  {
        var result:[String:String] = [:]
        httpResp.allHeaderFields.filter({
            let name = $0.0 as! NSString
            return String(name).starts(with: fieldsStartingWith)
        }).forEach({ result[String($0.0 as! NSString)]=String($0.1 as! NSString) })
        return result
    }
    
    private func handleMediaType(_ response: URLResponse, _ session: URLSession) throws {
        let expectedLength = response.expectedContentLength
        Logger.loading.debug("will recieve \(expectedLength) bytes")
        guard let mimeType = response.mimeType else {
            throw AudioDataError(.missingMimeType, "missing response.mimeType")
        }
        let type:AudioFileTypeID = try getAudioFileType(mimeType)
        Logger.loading.debug("mimeType \(mimeType) resolved to \(AudioData.describeFileTypeId(type))")
        try pipeline.prepareAudio(audioContentType: type)
    }
    
    private func getAudioFileType(_ mimeType:String) throws -> AudioFileTypeID {
        switch mimeType {
        case "audio/mpeg":
            return kAudioFileMP3Type
        case "audio/aac", "audio/aacp":
            return kAudioFileAAC_ADTSType
        case "application/ogg", "audio/ogg":
            return kAudioFormatOpus
        default:
            throw AudioDataError(.cannotProcessMimeType, "cannot process \(mimeType)")
        }
    }


    
    // MARK: session runs
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if Logger.verbose { Logger.loading.debug("recieved \(data.count) bytes, total \(dataTask.countOfBytesReceived)") }
        
        pipeline.decodingQueue.async {
            self.pipeline.process(data: data)
        }
        
        if dataTask.state == .running {
            stalled = false
        }
    }
    
    // MARK: session ends
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var logMessage = "task \(task.taskIdentifier) didComplete"
        if let errDesc = task.error?.localizedDescription {
            logMessage += " with \(errDesc)"
        }
        logMessage += ", state is \(describe(task.state))"
        Logger.loading.debug(logMessage)
        
        pipeline.decodingQueue.async {
            self.pipeline.flushAudio()
        }
        
        taskState = SessionTaskState.getSessionTaskState(task.state, error)
         
        guard let taskState = taskState else {
            Logger.loading.error(logMessage)
            return
        }
        
        if taskState.completed {
            Logger.loading.notice("task \(task.taskIdentifier) \(taskState.message)")
            return
        }
        
        switch taskState.severity {
        case .recoverable:
            networkStalled(taskState)
        case .fatal:
            let error = LoadingError(ErrorKind.networkFatal, taskState)
            pipeline.pipelineListener.error( stalled ? taskState.severityWhileStalling : taskState.severity, error)
        case .notice:
            let notice = LoadingError(ErrorKind.noError, taskState)
            pipeline.pipelineListener.error(taskState.severity,notice)
        }

    }
    
    /// not used but I want to see it
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity: URLSessionTask) {
        Logger.loading.notice("session waitingForConnectivity, task \(taskIsWaitingForConnectivity.taskIdentifier) state is \(describe(taskIsWaitingForConnectivity.state))")
    }
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        var logMessage = "session didBecomeInvalid"
        if let errDesc = error?.localizedDescription {
            logMessage += " with \(errDesc)"
        }
        Logger.loading.debug(logMessage)
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Logger.loading.notice("session did finish forBackgroundURLSession")
    }
}

fileprivate func describe(_ state: URLSessionTask.State? ) -> String {
    guard let state = state else {
        return "(nil)"
    }
    switch state {
    case .suspended: return "suspended"
    case .running : return "running"
    case .canceling: return "canceling"
    case .completed: return "completed"
    default: return "(unknown)"
    }
}
