import Foundation
import Combine

final class Pattern: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name:   String
    @Published var tracks: [Track]

    init(name: String, trackCount: Int = 4) {
        self.name   = name
        self.tracks = (0..<trackCount).map { i in
            Track(name: "Track \(i + 1)", stepCount: 16, midiChannel: i + 1)
        }
    }
}

extension Pattern: Codable {
    enum CodingKeys: String, CodingKey { case name, tracks }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name,   forKey: .name)
        try c.encode(tracks, forKey: .tracks)
    }

    convenience init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        let name   = try c.decode(String.self,  forKey: .name)
        let tracks = try c.decode([Track].self, forKey: .tracks)
        self.init(name: name, trackCount: tracks.count)
        self.tracks = tracks
    }
}
