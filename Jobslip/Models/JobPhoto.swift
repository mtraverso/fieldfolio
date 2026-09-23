import Foundation
import SwiftData

@Model
final class JobPhoto {
    var id: UUID
    var kindRaw: String
    var imageData: Data
    var createdAt: Date
    var job: Job?

    var kind: PhotoKind {
        get { PhotoKind(rawValue: kindRaw) ?? .before }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: PhotoKind, imageData: Data, job: Job? = nil) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.imageData = imageData
        self.createdAt = Date()
        self.job = job
    }
}
