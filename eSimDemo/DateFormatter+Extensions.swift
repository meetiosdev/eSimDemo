//
//  DateFormatter+Extensions.swift
//  EsimDemo
//
//  Created by Swarajmeet Singh on 05/09/25.
//

import Foundation

extension DateFormatter {
    static let humanReadable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

extension Date {
    var humanReadableString: String {
        return DateFormatter.humanReadable.string(from: self)
    }
}

extension String {
    func toHumanReadableDate() -> String? {
        // Try parsing as ISO 8601 format first
        if let date = DateFormatter.iso8601.date(from: self) {
            return date.humanReadableString
        }
        
        // Try parsing as Unix timestamp
        if let timestamp = Double(self), timestamp > 0 {
            let date = Date(timeIntervalSince1970: timestamp)
            return date.humanReadableString
        }
        
        return nil
    }
}

extension Int {
    var toHumanReadableDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        return date.humanReadableString
    }
}
