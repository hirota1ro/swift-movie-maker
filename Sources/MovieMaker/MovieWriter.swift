import Cocoa
import AVFoundation

struct MovieWriter {
    let size: CGSize            // e.g. 1280×720
    let fps: Int                // e.g. 30
}

enum MovieWriterError: Error {
    case noPixelBuffer
    case cannotStart
    case notReady
    case cannotAppend
    case failed
}

extension MovieWriter {

    func makeMovie(images: [NSImage], framesPerImage: Int, outputURL: URL) throws {
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
        var outputSettings = AVOutputSettingsAssistant(preset: .preset1280x720)!.videoSettings!
        outputSettings[AVVideoWidthKey] = size.width
        outputSettings[AVVideoHeightKey] = size.height
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        videoWriter.add(writerInput)
        let sourcePixelBufferAttributes: [String:Any] = [
          AVVideoCodecKey: Int(kCVPixelFormatType_32ARGB),
          AVVideoWidthKey: size.width,
          AVVideoHeightKey: size.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
          assetWriterInput: writerInput,
          sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        writerInput.expectsMediaDataInRealTime = true
        guard videoWriter.startWriting() else { throw MovieWriterError.cannotStart }
        videoWriter.startSession(atSourceTime: CMTime.zero)
        var frameCount: Int = 0
        for image in images {
            guard adaptor.assetWriterInput.isReadyForMoreMediaData else { throw MovieWriterError.notReady }
            guard let buffer = image.pixelBuffer else { throw MovieWriterError.noPixelBuffer }
            let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(fps))
            guard adaptor.append(buffer, withPresentationTime: frameTime) else { throw MovieWriterError.cannotAppend }
            frameCount += framesPerImage
        }
        writerInput.markAsFinished()
        videoWriter.endSession(atSourceTime: CMTimeMake(value: Int64(frameCount), timescale: Int32(fps)))
        let semaphore = DispatchSemaphore(value: 0)
        videoWriter.finishWriting { semaphore.signal() }
        semaphore.wait()
        if videoWriter.status != AVAssetWriter.Status.completed {
            throw MovieWriterError.failed
        }
    }
}
