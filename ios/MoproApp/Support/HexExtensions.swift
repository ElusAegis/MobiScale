import Foundation

public extension Data {
    init?(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else { return nil }
        self.init(capacity: hexString.count/2)
        var idx = hexString.startIndex
        while idx < hexString.endIndex {
            let next = hexString.index(idx, offsetBy: 2)
            guard let byte = UInt8(hexString[idx..<next], radix: 16) else { return nil }
            append(byte)
            idx = next
        }
    }
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
