//
//  MicInput.swift
//  ARTest
//
//  Created by Shuhei Yukawa on 2018/07/03.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation
import AVFoundation
import AudioUnit


class MicInput {
    var level: Float  = 0.0
    
    private var audioUnit: AudioUnit?
    private var audioBufferList: AudioBufferList?

    private let kInputBus: UInt32 =  1
    private let kNumberOfChannels: Int =  1
    
    func setUpAudio() {
        // AudioSession セットアップ
        do {
            try self.setUpSession()
            try self.setUpAudioComponent()
            try self.setUpMicrophone()
            try self.setUpDataFormat()
            try self.setupCallback()
            
            guard let au = self.audioUnit else {
                throw NSError(domain: "AudioError", code: 1, userInfo: nil);
            }
            
            AudioUnitInitialize(au)
            AudioOutputUnitStart(au)
        } catch {
            exit(-1);
        }
    }
    
    private func setUpSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true)
        } catch let err {
            throw err
        }
    }
    
    
    private func setUpAudioComponent() throws {
        // CoreAudio セットアップ
        var componentDesc: AudioComponentDescription
            = AudioComponentDescription(
                componentType:          OSType(kAudioUnitType_Output),
                componentSubType:       OSType(kAudioUnitSubType_RemoteIO),
                componentManufacturer:  OSType(kAudioUnitManufacturer_Apple),
                componentFlags:         UInt32(0),
                componentFlagsMask:     UInt32(0) )
        
        let component: AudioComponent! = AudioComponentFindNext(nil, &componentDesc)
        let status = AudioComponentInstanceNew(component, &self.audioUnit)
        if status != errSecSuccess {
            throw NSError(domain: "AudioError", code: 2, userInfo: nil);
        }
    }
    
    private func setUpMicrophone() throws {
        // RemoteIO のマイクを有効にする
        guard let au = self.audioUnit else {
            throw NSError(domain: "AudioError", code: 3, userInfo: nil);
        }
        
        var status: OSStatus;
        var enable: UInt32 = 1
        status = AudioUnitSetProperty(au,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             kInputBus,
                             &enable,
                             UInt32(MemoryLayout<UInt32>.size))

        if status != errSecSuccess {
            throw NSError(domain: "AudioError", code: 4, userInfo: nil);
        }
    }
    
    private func setUpDataFormat() throws {
        guard let au = self.audioUnit else {
            throw NSError(domain: "AudioError", code: 5, userInfo: nil);
        }
        // マイクから取り出すデータフォーマット
        // 32bit float, linear PCM
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100,
                                      channels: UInt32(kNumberOfChannels)) else {
                                        return
        }
        
        // データ取り出し時に使う AudioBufferListの設定
        self.audioBufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: fmt.channelCount,
                mDataByteSize: fmt.streamDescription.pointee.mBytesPerFrame,
                mData: nil))
        
        // RemoteIO のマイクバスから取り出すフォーマットを設定
        let status = AudioUnitSetProperty(au,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             kInputBus,
                             fmt.streamDescription,
                             UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        if status != errSecSuccess {
            throw NSError(domain: "AudioError", code: 6, userInfo: nil);
        }
        
    }
    
    private func setupCallback() throws {
        guard let au = self.audioUnit else {
            throw NSError(domain: "AudioError", code: 7, userInfo: nil);
        }
        // AudioUnit に録音コールバックを設定
        var inputCallbackStruct
            = AURenderCallbackStruct(inputProc: recordingCallback,
                                     inputProcRefCon:
                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        let status = AudioUnitSetProperty(au,
                             AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback),
                             AudioUnitScope(kAudioUnitScope_Global),
                             kInputBus,
                             &inputCallbackStruct,
                             UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        if status != errSecSuccess {
            throw NSError(domain: "Error", code: 8, userInfo: nil);
        }
        
    }
    
    
    let recordingCallback: AURenderCallback = { (
        inRefCon,
        ioActionFlags,
        inTimeStamp,
        inBusNumber,
        frameCount,
        ioData ) -> OSStatus in
        
        let audioObject = unsafeBitCast(inRefCon, to: MicInput.self)
        
        if let au = audioObject.audioUnit {
            // マイクから取得したデータを取り出す
            AudioUnitRender(audioObject.audioUnit!,
                            ioActionFlags,
                            inTimeStamp,
                            inBusNumber,
                            frameCount,
                            &audioObject.audioBufferList!)
        }
        let inputDataPtr = UnsafeMutableAudioBufferListPointer(&audioObject.audioBufferList!)
        let mBuffers: AudioBuffer = inputDataPtr[0]
        let bufferPointer = UnsafeMutableRawPointer(mBuffers.mData)
        if let bptr = bufferPointer {
            let dataArray = bptr.assumingMemoryBound(to: Float.self)
            // マイクから取得したデータからRMS(RootMeanSquare)レベルを計算する
            var sum:Float = 0.0
            if frameCount > 0 {
                for i in 0 ..< Int(frameCount) {
                    sum += (dataArray[i]*dataArray[i])
                }
                audioObject.level = sqrt(sum / Float(frameCount))
            }
        }
        return 0
    }
}
