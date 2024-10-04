import Foundation
import os

protocol Logging {
    var logger: Logger { get }
}

extension Logging {

    var logger: Logger {
        let subsystem = #fileID.components(separatedBy: "/").first ?? "APIService"
        let category = String(describing: Self.self)

        return Logger(
            subsystem: subsystem,
            category: category
        )
    }
}
