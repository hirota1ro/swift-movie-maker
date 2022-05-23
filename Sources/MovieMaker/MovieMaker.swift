import Cocoa
import ArgumentParser

@main
struct MovieMaker: ParsableCommand {
    static let configuration = CommandConfiguration(
      subcommands: [],
      helpNames: [.long, .customShort("?")])

    @Argument(help: "source images. e.g. ~/Downloads/*.png")
    var files: [String] = []
    @Option(name: .shortAndLong, help: "output file path (e.g. ~/tmp/a.mp4)")
    var outputFile: String = "a.mp4"
    @Option(name: .shortAndLong, help: "video size (0 means the same as the image size")
    var width: Int = 0
    @Option(name: .shortAndLong, help: "video size (0 means the same as the image size")
    var height: Int = 0
    @Option(name: .shortAndLong, help: "frames per second")
    var fps: Int = 30
    @Option(name: [.customShort("F"), .long], help: "frames per image")
    var fpi: Int = 1
    @Flag var verbose = false

    mutating func run() throws {
        let images:[NSImage] = files.compactMap { NSImage(contentsOf: URL(fileURLWithPath: $0)) }
        let outputURL = URL(fileURLWithPath: outputFile)
        if FileManager.default.fileExists(atPath: outputURL.path) {
            if verbose {
                print("delete old file=\(outputURL.path)")
            }
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("#Failed: Could not remove file \(error.localizedDescription)")
            }
        }

        let defaultImageSize = images[0].size

        let w = width == 0 ? defaultImageSize.width : CGFloat(width)
        let h = height == 0 ? defaultImageSize.height : CGFloat(height)

        if verbose {
            print("files=\(files)")
            print("images.count=\(images.count)")
            print("size=\(w)x\(h)")
            print("outputURL=\(outputURL)")
            print("fps=\(fps)")
            print("fpi=\(fpi)")
        }
        let writer = MovieWriter(size: CGSize(width: w, height: h), fps: fps)
        try writer.makeMovie(images: images, framesPerImage: fpi, outputURL: outputURL)
        if verbose {
            print("Succeeded: created file=\(outputURL.path)")
        }
    }
}
