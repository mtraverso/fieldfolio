import Foundation
import SwiftData
import UIKit

enum DataExporter {
    enum ExportError: LocalizedError {
        case noData
        case zipFailed

        var errorDescription: String? {
            switch self {
            case .noData: return String(localized: "Nothing to export yet.")
            case .zipFailed: return String(localized: "Could not create the backup zip.")
            }
        }
    }

    static func exportBackup(
        clients: [Client],
        jobs: [Job],
        profile: BusinessProfile?
    ) throws -> URL {
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("FieldFolio-Export-\(stamp)", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let photosDir = folder.appendingPathComponent("photos", isDirectory: true)
        try FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

        try writeClientsCSV(clients, to: folder.appendingPathComponent("clients.csv"))
        try writeJobsCSV(jobs, to: folder.appendingPathComponent("jobs.csv"))

        if let profile {
            let profileText = """
            businessName,\(csvEscape(profile.businessName))
            phone,\(csvEscape(profile.phone))
            email,\(csvEscape(profile.email))
            currencyCode,\(csvEscape(profile.currencyCode))
            paymentInstructions,\(csvEscape(profile.paymentInstructions))
            """
            try profileText.write(to: folder.appendingPathComponent("business.csv"), atomically: true, encoding: .utf8)
        }

        for job in jobs {
            for (index, photo) in job.beforePhotos.enumerated() {
                let name = "\(job.id.uuidString)-before-\(index + 1).jpg"
                try photo.imageData.write(to: photosDir.appendingPathComponent(name))
            }
            for (index, photo) in job.afterPhotos.enumerated() {
                let name = "\(job.id.uuidString)-after-\(index + 1).jpg"
                try photo.imageData.write(to: photosDir.appendingPathComponent(name))
            }
        }

        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FieldFolio-Backup-\(stamp).zip")
        try? FileManager.default.removeItem(at: zipURL)
        try ZipArchive.create(fromDirectory: folder, to: zipURL)
        try? FileManager.default.removeItem(at: folder)
        return zipURL
    }

    private static func writeClientsCSV(_ clients: [Client], to url: URL) throws {
        var rows = ["id,name,phone,address,defaultRate,notes"]
        for client in clients {
            rows.append([
                client.id.uuidString,
                csvEscape(client.name),
                csvEscape(client.phone),
                csvEscape(client.address),
                "\(client.defaultRate)",
                csvEscape(client.notes)
            ].joined(separator: ","))
        }
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func writeJobsCSV(_ jobs: [Job], to url: URL) throws {
        var rows = ["id,clientName,status,scheduledAt,serviceName,subtotal,taxPercent,discountAmount,total,invoiceNumber,estimateNumber,notes,lineItems"]
        let formatter = ISO8601DateFormatter()
        for job in jobs {
            let lineDesc = job.effectiveLineItems
                .map { "\($0.title) x\($0.quantity) @\($0.unitPrice)" }
                .joined(separator: " | ")
            rows.append([
                job.id.uuidString,
                csvEscape(job.client?.name ?? ""),
                csvEscape(job.status.rawValue),
                csvEscape(formatter.string(from: job.scheduledAt)),
                csvEscape(job.serviceName),
                "\(job.subtotal)",
                "\(job.taxPercent)",
                "\(job.discountAmount)",
                "\(job.total)",
                job.invoiceNumber.map(String.init) ?? "",
                job.estimateNumber.map(String.init) ?? "",
                csvEscape(job.notes),
                csvEscape(lineDesc)
            ].joined(separator: ","))
        }
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

/// Minimal stored-ZIP writer (stored method only — no compression) for backup bundles.
enum ZipArchive {
    static func create(fromDirectory directory: URL, to zipURL: URL) throws {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            throw DataExporter.ExportError.zipFailed
        }

        var entries: [(name: String, data: Data)] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let relative = fileURL.path.replacingOccurrences(of: directory.path + "/", with: "")
            entries.append((name: relative, data: try Data(contentsOf: fileURL)))
        }

        var output = Data()
        var central = Data()
        var offset: UInt32 = 0

        for entry in entries {
            let nameData = Data(entry.name.utf8)
            let localHeaderOffset = offset

            var local = Data()
            local.append(contentsOf: UInt32(0x04034b50).littleEndianBytes)
            local.append(contentsOf: UInt16(20).littleEndianBytes) // version needed
            local.append(contentsOf: UInt16(0).littleEndianBytes) // flags
            local.append(contentsOf: UInt16(0).littleEndianBytes) // stored
            local.append(contentsOf: UInt16(0).littleEndianBytes) // time
            local.append(contentsOf: UInt16(0).littleEndianBytes) // date
            let crc = crc32(entry.data)
            local.append(contentsOf: crc.littleEndianBytes)
            local.append(contentsOf: UInt32(entry.data.count).littleEndianBytes)
            local.append(contentsOf: UInt32(entry.data.count).littleEndianBytes)
            local.append(contentsOf: UInt16(nameData.count).littleEndianBytes)
            local.append(contentsOf: UInt16(0).littleEndianBytes) // extra
            local.append(nameData)
            local.append(entry.data)
            output.append(local)
            offset += UInt32(local.count)

            var cen = Data()
            cen.append(contentsOf: UInt32(0x02014b50).littleEndianBytes)
            cen.append(contentsOf: UInt16(20).littleEndianBytes)
            cen.append(contentsOf: UInt16(20).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: crc.littleEndianBytes)
            cen.append(contentsOf: UInt32(entry.data.count).littleEndianBytes)
            cen.append(contentsOf: UInt32(entry.data.count).littleEndianBytes)
            cen.append(contentsOf: UInt16(nameData.count).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt16(0).littleEndianBytes)
            cen.append(contentsOf: UInt32(0).littleEndianBytes)
            cen.append(contentsOf: localHeaderOffset.littleEndianBytes)
            cen.append(nameData)
            central.append(cen)
        }

        let centralOffset = UInt32(output.count)
        output.append(central)
        let centralSize = UInt32(central.count)

        var end = Data()
        end.append(contentsOf: UInt32(0x06054b50).littleEndianBytes)
        end.append(contentsOf: UInt16(0).littleEndianBytes)
        end.append(contentsOf: UInt16(0).littleEndianBytes)
        end.append(contentsOf: UInt16(entries.count).littleEndianBytes)
        end.append(contentsOf: UInt16(entries.count).littleEndianBytes)
        end.append(contentsOf: centralSize.littleEndianBytes)
        end.append(contentsOf: centralOffset.littleEndianBytes)
        end.append(contentsOf: UInt16(0).littleEndianBytes)
        output.append(end)

        try output.write(to: zipURL)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xff)
            crc = (crc >> 8) ^ crcTable[idx]
        }
        return crc ^ 0xffffffff
    }

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xedb88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()
}

private extension FixedWidthInteger {
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian, Array.init)
    }
}
