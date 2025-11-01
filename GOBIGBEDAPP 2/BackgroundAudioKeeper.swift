import Foundation
import AVFoundation


final class BackgroundAudioKeeper {
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    func start() {
        if engine != nil { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            let engine = AVAudioEngine()

            let source = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buf in abl {
                    if let mData = buf.mData {
                        memset(mData, 0, Int(buf.mDataByteSize))
                    }
                }
                return noErr
            }

            engine.attach(source)
            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            engine.connect(source, to: engine.mainMixerNode, format: format)

            try engine.start()

            self.engine = engine
            self.sourceNode = source
        } catch {
            print("BackgroundAudioKeeper: start error →", error.localizedDescription)
            stop()
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
        }
    }
}
