// GM Standard Drum Map — MIDI channel 10 note names
enum GMDrumMap {
    static let shortNames: [Int: String] = [
        35: "Kick 2",   36: "Kick",
        37: "Stick",    38: "Snare",    39: "Clap",     40: "Snare 2",
        41: "Tom FL",   42: "HH Cls",   43: "Tom FH",   44: "HH Ped",
        45: "Tom L",    46: "HH Opn",   47: "Tom LM",   48: "Tom HM",
        49: "Crash",    50: "Tom H",    51: "Ride",     52: "China",
        53: "Ride Bll", 54: "Tamb",     55: "Splash",   56: "Cowbell",
        57: "Crash 2",  58: "Vibra",    59: "Ride 2",
        60: "Bongo H",  61: "Bongo L",  62: "Conga MH", 63: "Conga OH",
        64: "Conga L",  65: "Timb H",   66: "Timb L",
        69: "Cabasa",   70: "Maracas",  75: "Claves",
        76: "WBlk H",   77: "WBlk L",   80: "Tri M",    81: "Tri O"
    ]

    static func name(for note: Int) -> String? { shortNames[note] }
}
