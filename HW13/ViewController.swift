import UIKit
import AVFoundation
import AVKit

class AssetStore {
    let video1: AVAsset
    let video2: AVAsset
    let video3: AVAsset
    let music1: AVAsset
    let music2: AVAsset
    
    init(video1: AVAsset, video2: AVAsset, video3: AVAsset, music1: AVAsset, music2: AVAsset) {
        self.video1 = video1
        self.video2 = video2
        self.video3 = video3
        self.music1 = music1
        self.music2 = music2
    }
    
    static func asset(_ resource: String, type: String) -> AVAsset{
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else { fatalError("Check Target & Location") }
        let url = URL(fileURLWithPath: path)
        return AVAsset(url: url)
    }
    
    static func test() -> AssetStore{
        return AssetStore(video1: asset("video1", type: "MOV"),
                          video2: asset("video2", type: "MOV"),
                          video3: asset("video3", type: "MOV"),
                          music1: asset("Alan_Walker_-_Fade_(cut)", type: "mp3"),
                          music2: asset("Versión_De_Lujo_-_My_Heart_(cut)", type: "mp3"))
    }
    
    func compose() -> (AVAsset, AVVideoComposition){
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        guard let video1Track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("videoTrack1") }
        guard let video2Track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("videoTrack2") }
        guard let video3Track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("videoTrack3") }
        guard let audio1Track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("audioTrack1") }
        guard let audio2Track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("audioTrack2") }
        
        let transitionDuration = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        try? video1Track.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration), of: video1.tracks(withMediaType: .video)[0], at: CMTime.zero)
        
        try? video2Track.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video2.duration), of: video2.tracks(withMediaType: .video)[0], at: video1.duration - transitionDuration)
        
        try? video3Track.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video3.duration), of: video3.tracks(withMediaType: .video)[0], at: video1.duration + video2.duration)
        
        try? audio1Track.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration), of: music1.tracks(withMediaType: .audio)[0], at: CMTime.zero)
        
        try? audio2Track.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video2.duration + video3.duration), of: music2.tracks(withMediaType: .audio)[0], at: video1.duration)
        
      
        let passThroughInstruction1 = AVMutableVideoCompositionInstruction()
        passThroughInstruction1.timeRange = CMTimeRange(start: CMTime.zero, duration: video1.duration - transitionDuration)
        let passThroughLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: video1Track)
        passThroughLayerInstruction1.setTransform(video1Track.preferredTransform, at: CMTime.zero)
        passThroughInstruction1.layerInstructions = [passThroughLayerInstruction1]
        
      
        let passThroughInstruction2 = AVMutableVideoCompositionInstruction()
        passThroughInstruction2.timeRange = CMTimeRange(start: video1.duration, duration: video2.duration)
        let passThroughLayerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: video2Track)
        passThroughLayerInstruction2.setTransform(video2Track.preferredTransform, at: CMTime.zero)
        passThroughInstruction2.layerInstructions = [passThroughLayerInstruction2]
        
     
        let passThroughInstruction3 = AVMutableVideoCompositionInstruction()
        passThroughInstruction3.timeRange = CMTimeRange(start: video1.duration + video2.duration, duration: video3.duration)
       
        videoComposition.renderSize = CGSize(width: 640, height: 361)
   
        

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: video1.duration - transitionDuration, duration: transitionDuration)
        
  
        let video1Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video1Track)
    
        let video1pos1 = CGAffineTransform(translationX: 0, y: 0)
        let video1pos2 = CGAffineTransform(translationX: videoComposition.renderSize.width, y: 0)

        video1Instruction.setTransformRamp(fromStart: video1pos1, toEnd: video1pos2, timeRange: instruction.timeRange)
 
        let video2Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video2Track)
   
        let video2pos1 = CGAffineTransform(translationX: -videoComposition.renderSize.width, y: 0)
        let video2pos2 = CGAffineTransform(translationX: 0, y: 0)

        video2Instruction.setTransformRamp(fromStart: video2pos1, toEnd: video2pos2, timeRange: instruction.timeRange)
        

        let video3Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video3Track)
        
        let instruction2 = AVMutableVideoCompositionInstruction()
        instruction2.timeRange = CMTimeRange(start: video1.duration + video2.duration, duration: transitionDuration)
        
        let video2Size = video2.tracks(withMediaType: .video)[0].naturalSize
        let video3Size = video3.tracks(withMediaType: .video)[0].naturalSize
        
        let W = video2Size.width / video3Size.width
        let H = video2Size.height / video3Size.height
        
        let video3scale1 = CGAffineTransform(scaleX: 0.001, y: 0.001)
        let video3scale2 = CGAffineTransform(scaleX: W, y: H)
        
        video3Instruction.setTransformRamp(
            fromStart: video3scale1,
            toEnd: video3scale2,
            timeRange: instruction2.timeRange)
        
        passThroughInstruction3.layerInstructions.append(video3Instruction)
       
        instruction.layerInstructions = [video1Instruction, video2Instruction, video3Instruction]
        videoComposition.instructions = [passThroughInstruction1, instruction, passThroughInstruction2, passThroughInstruction3]
        
        return (composition, videoComposition)
    }
    
    func export(asset: AVAsset, composition: AVVideoComposition, completion: @escaping (Bool) -> Void){
        guard let documentDirectory = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first else { fatalError("documentDirectory") }
        
        let url = documentDirectory.appendingPathComponent("mergedVideo-\(arc4random()).mov")
        
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { fatalError("exporter") }
        
        exporter.outputURL = url
        exporter.outputFileType = .mov
        exporter.videoComposition = composition
        
        exporter.exportAsynchronously {
            // print(exporter.error)
            DispatchQueue.main.async {
                completion(exporter.status == .completed)
                print("Full Path: \(url.absoluteString.dropFirst(7))")
            }
        }
    }
}

class ViewController: UIViewController {
    
    let store = AssetStore.test()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let (asset, videoComposition) = store.compose()
        startPlaying(asset: asset, videoComposition: videoComposition)
    }
    
    @IBAction func save(_ sender: Any) {
        store.export(asset: store.compose().0, composition: store.compose().1) { success in
            print("saved? \(success)")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    func startPlaying(asset: AVAsset, videoComposition: AVVideoComposition){
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = videoComposition
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds.insetBy(dx: 0, dy: 100)
        
        view.layer.addSublayer(playerLayer)
        player.play()
        

    }
}
