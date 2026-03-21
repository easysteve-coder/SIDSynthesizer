import CoreMIDI
import Foundation
import Combine

enum ClockMode: String, CaseIterable, Codable {
    case `internal` = "INT"
    case external   = "EXT"
}

// MARK: - C-compatible read proc (must be top-level)

private func midiReadProc(
    _ packetList: UnsafePointer<MIDIPacketList>,
    _ readProcRefCon: UnsafeMutableRawPointer?,
    _ srcConnRefCon: UnsafeMutableRawPointer?
) {
    guard let ref = readProcRefCon else { return }
    Unmanaged<MIDIManager>.fromOpaque(ref).takeUnretainedValue()
        .handlePackets(packetList)
}

// MARK: - MIDIManager

class MIDIManager: ObservableObject {
    private var client:  MIDIClientRef   = 0
    private var outPort: MIDIPortRef     = 0
    private var inPort:  MIDIPortRef     = 0
    private var virtSrc: MIDIEndpointRef = 0
    private var virtDst: MIDIEndpointRef = 0

    @Published var outputs:        [(ref: MIDIEndpointRef, name: String)] = []
    @Published var inputs:         [(ref: MIDIEndpointRef, name: String)] = []
    @Published var selectedOutput: MIDIEndpointRef = 0
    @Published var selectedInput:  MIDIEndpointRef = 0

    // Callbacks — called from the MIDI read thread (clock pulse) or main thread
    var onClockPulse: (() -> Void)?
    var onStart:      (() -> Void)?
    var onStop:       (() -> Void)?
    var onContinue:   (() -> Void)?
    var onCC:         ((Int, Int, Int) -> Void)?   // (channel 1-16, ccNumber, value)
    var onNoteOn:     ((Int, Int, Int) -> Void)?   // (channel 1-16, note, velocity)

    // MARK: - Setup

    func setup() {
        let ptr = Unmanaged.passUnretained(self).toOpaque()

        MIDIClientCreate("VintageSequencer" as CFString, { _, refCon in
            guard let r = refCon else { return }
            let m = Unmanaged<MIDIManager>.fromOpaque(r).takeUnretainedValue()
            DispatchQueue.main.async { m.refreshPorts() }
        }, ptr, &client)

        MIDIOutputPortCreate(client, "VintSeq-Out"  as CFString, &outPort)
        MIDIInputPortCreate (client, "VintSeq-In"   as CFString, midiReadProc, ptr, &inPort)
        MIDISourceCreate    (client, "Vintage Sequencer" as CFString, &virtSrc)
        MIDIDestinationCreate(client,"Vintage Sequencer" as CFString, midiReadProc, ptr, &virtDst)

        refreshPorts()
    }

    func refreshPorts() {
        let nDst = MIDIGetNumberOfDestinations()
        outputs = (0..<nDst).compactMap { i in
            let ep = MIDIGetDestination(i)
            return endpointName(ep).map { (ref: ep, name: $0) }
        }
        let nSrc = MIDIGetNumberOfSources()
        inputs = (0..<nSrc).compactMap { i in
            let ep = MIDIGetSource(i)
            return endpointName(ep).map { (ref: ep, name: $0) }
        }
    }

    func connectInput(_ ep: MIDIEndpointRef) {
        if selectedInput != 0 { MIDIPortDisconnectSource(inPort, selectedInput) }
        selectedInput = ep
        if ep != 0 { MIDIPortConnectSource(inPort, ep, nil) }
    }

    // MARK: - Send helpers

    func send(_ bytes: [UInt8]) {
        let bufSize = 256
        let buf = UnsafeMutableRawPointer.allocate(
            byteCount: bufSize,
            alignment: MemoryLayout<MIDIPacketList>.alignment)
        defer { buf.deallocate() }

        let pl = buf.bindMemory(to: MIDIPacketList.self, capacity: 1)
        var pkt = MIDIPacketListInit(pl)

        pkt = MIDIPacketListAdd(pl, bufSize, pkt, 0, bytes.count, bytes)

        if selectedOutput != 0 { MIDISend(outPort, selectedOutput, pl) }
        if virtSrc        != 0 { MIDIReceived(virtSrc, pl) }
    }

    func noteOn(channel: Int, note: Int, velocity: Int) {
        send([UInt8(0x90 | (channel - 1) & 0x0F),
              UInt8(note     & 0x7F),
              UInt8(velocity & 0x7F)])
    }

    func noteOff(channel: Int, note: Int) {
        send([UInt8(0x80 | (channel - 1) & 0x0F),
              UInt8(note & 0x7F), 0])
    }

    func cc(channel: Int, number: Int, value: Int) {
        send([UInt8(0xB0 | (channel - 1) & 0x0F),
              UInt8(number & 0x7F),
              UInt8(value  & 0x7F)])
    }

    func allNotesOff(channel: Int) { cc(channel: channel, number: 123, value: 0) }
    func clock()    { send([0xF8]) }
    func start()    { send([0xFA]) }
    func stop()     { send([0xFC]) }
    func `continue`() { send([0xFB]) }

    // MARK: - Receive

    func handlePackets(_ pl: UnsafePointer<MIDIPacketList>) {
        let count = Int(pl.pointee.numPackets)
        guard count > 0 else { return }

        // Echter Pointer in den Packet-List-Speicher (keine Stack-Kopie!)
        // MIDIPacketList: [UInt32 numPackets][MIDIPacket packet[1]...]
        var pktPtr = UnsafeMutableRawPointer(mutating: pl)
            .advanced(by: MemoryLayout<UInt32>.size)
            .assumingMemoryBound(to: MIDIPacket.self)

        for i in 0..<count {
            let length = Int(pktPtr.pointee.length)
            if length > 0 {
                let bytes = withUnsafeBytes(of: pktPtr.pointee.data) {
                    Array($0.prefix(length))
                }
                let status = bytes[0]
                switch status {
                case 0xF8: onClockPulse?()
                case 0xFA: DispatchQueue.main.async { self.onStart?() }
                case 0xFB: DispatchQueue.main.async { self.onContinue?() }
                case 0xFC: DispatchQueue.main.async { self.onStop?() }
                case 0x90...0x9F:
                    guard bytes.count >= 3 else { break }
                    let ch   = Int(status & 0x0F) + 1
                    let note = Int(bytes[1] & 0x7F)
                    let vel  = Int(bytes[2] & 0x7F)
                    if vel > 0 {
                        DispatchQueue.main.async { self.onNoteOn?(ch, note, vel) }
                    }
                case 0xB0...0xBF:
                    guard bytes.count >= 3 else { break }
                    let ch  = Int(status & 0x0F) + 1
                    let num = Int(bytes[1] & 0x7F)
                    let val = Int(bytes[2] & 0x7F)
                    DispatchQueue.main.async { self.onCC?(ch, num, val) }
                default: break
                }
            }
            // Wichtig: NICHT nach dem letzten Paket advance aufrufen!
            if i < count - 1 {
                pktPtr = MIDIPacketNext(pktPtr)
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        if virtSrc != 0 { MIDIEndpointDispose(virtSrc) }
        if virtDst != 0 { MIDIEndpointDispose(virtDst) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if inPort  != 0 { MIDIPortDispose(inPort) }
        if client  != 0 { MIDIClientDispose(client) }
    }

    // MARK: - Private

    private func endpointName(_ ep: MIDIEndpointRef) -> String? {
        var prop: Unmanaged<CFString>?
        MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &prop)
        return prop?.takeRetainedValue() as String?
    }
}
