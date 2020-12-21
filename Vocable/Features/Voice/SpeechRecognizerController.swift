//
//  SpeechRecognizerController.swift
//  Vocable
//
//  Created by Steve Foster on 12/15/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import UIKit
import Speech
import Combine

protocol SpeechRecognizerControllerDelegate: AnyObject {
    func didReceivePartialTranscription(_ transcription: String)
    func didGetFinalResult(_ speechRecognitionResult: SFSpeechRecognitionResult)
    func didReceiveRequiredPhrase()
    func transcriptionDidCancel()
}

class SpeechRecognizerController: NSObject, SFSpeechRecognitionTaskDelegate {

    weak var delegate: SpeechRecognizerControllerDelegate?
    var timeoutInterval: TimeInterval = 1.2
    var requiredPhrase: String?

    static private let speechRecognizer: SFSpeechRecognizer? = {
        let recognizer = SFSpeechRecognizer()
        recognizer?.supportsOnDeviceRecognition = true
        return recognizer
    }()

    private var bufferCancellable: AnyCancellable?
    private var recognitionTasks = Set<SFSpeechRecognitionTask>()

    private var recognitionBuffer: SFSpeechAudioBufferRecognitionRequest?

    private var timeout: Timer?

    private var lastErrorDate = Date.distantPast

    @Published private(set) var isListening = false
    @Published private(set) var isHearingWords = false

    private func countOfRecognitionTasks(matching states: SFSpeechRecognitionTaskState...) -> Int {
        return recognitionTasks.filter { task in
            states.contains(task.state)
        }.count
    }

    func startListening() {
        print("START LISTENING...")
        isListening = true
        AudioEngineController.shared.register(speechRecognizer: self)

        SFSpeechRecognizer.requestAuthorization { [weak self] (authStatus) in
            guard let self = self else { return }
            switch authStatus {
            case .authorized:

                let audioSession = AVAudioSession.sharedInstance()
                audioSession.requestRecordPermission { (canRecord) in
                    guard canRecord else {
                        assertionFailure("Recording permission denied")
                        return
                    }
                    guard SyntheticInput.values == nil else { return }
                    self.requestTranscription()
                }
            default:
                NSLog("Voice recognition not authorized")
            }
        }
    }

    func stopListening() {
        print("STOP LISTENING...")
        isListening = false

        for task in recognitionTasks {
            task.finish()
        }
        recognitionTasks.removeAll()

        AudioEngineController.shared.unregister(speechRecognizer: self)
    }

    private func startTimer() {
        print("STARTING TIMER...")

        timeout?.invalidate()
        timeout = Timer.scheduledTimer(timeInterval: timeoutInterval,
                                       target: self,
                                       selector: #selector(self.handleTimeout),
                                       userInfo: nil,
                                       repeats: false)
    }

    @objc private func handleTimeout() {
        print("HANDLE TIMEOUT...")

        timeout?.invalidate()

        for task in recognitionTasks {
            task.finish()
        }
    }

    private func prepareSpeechBuffer() {

        if bufferCancellable == nil {
            bufferCancellable = AudioEngineController.shared.$audioBuffer
                .compactMap { $0 }
                .sink { [weak self] in
                    self?.recognitionBuffer?.append($0.buffer)
                }
        }
    }

    private func requestTranscription() {

        guard countOfRecognitionTasks(matching: .starting, .running) == 0 else {
            return
        }

        prepareSpeechBuffer()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        request.taskHint = .dictation

        if let phrase = requiredPhrase {
            request.contextualStrings = [phrase]
        }

        recognitionBuffer = request

        if let task = SpeechRecognizerController.speechRecognizer?.recognitionTask(with: request, delegate: self) {
            recognitionTasks.insert(task)
        }

    }

    private func transcribeAgainIfNeeded() {
        guard isListening else {
            return
        }
        requestTranscription()
    }

    //
    // Called when the task first detects speech in the source audio
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        // TODO: May be useful for UI to indicate when speech is detected (hot word)
        isHearingWords = true
    }

    // Called for all recognitions, including non-final hypothesis
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        print("didHypothesizeTranscription: \(transcription.formattedString.lowercased())")
        if let requiredPhrase = requiredPhrase, transcription.formattedString.lowercased().contains(requiredPhrase.lowercased()) {
            delegate?.didReceiveRequiredPhrase()
        }
        startTimer()
        delegate?.didReceivePartialTranscription(transcription.formattedString)
    }

    // Called only for final recognitions of utterances. No more about the utterance will be reported
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("didFinishRecognition: \(recognitionResult.bestTranscription.formattedString.lowercased())")
        if let requiredPhrase = requiredPhrase, recognitionResult.bestTranscription.formattedString.lowercased().contains(requiredPhrase.lowercased()) {
            delegate?.didReceiveRequiredPhrase()
        }
        delegate?.didGetFinalResult(recognitionResult)
    }

    // Called when the task is no longer accepting new audio but may be finishing final processing
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        // TODO: Potentially buffer the next task? Probably not necessary
        transcribeAgainIfNeeded()
    }

    // Called when the task has been cancelled, either by client app, the user, or the system
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("speechRecognitionTaskWasCancelled")
        transcribeAgainIfNeeded()
        recognitionTasks.remove(task)
    }

    // Called when recognition of all requested utterances is finished.
    // If successfully is false, the error property of the task will contain error information
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("speechRecognitionTaskDidFinish \(successfully ? "successfully" : "unsuccessfully")")
        if successfully {
            transcribeAgainIfNeeded()
        } else {

            // If we get spammed with errors, stop trying to obtain a transcription.
            // This can occur for a number of reasons and it's difficult to enumerate
            // the possible error codes ahead of time
            if Date().timeIntervalSince(lastErrorDate) < 0.05 {
                stopListening()
            }
            lastErrorDate = Date()
        }
        recognitionTasks.remove(task)
    }
}

