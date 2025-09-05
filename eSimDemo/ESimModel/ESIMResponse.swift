//
//  ESIMResponse.swift
//  EsimDemo
//
//  Created by Swarajmeet Singh on 05/09/25.
//



import Foundation

/// Represents the top-level response structure for eSIM data
struct ESIMResponse: Codable {
    let response: ProfileResult
    
    enum CodingKeys: String, CodingKey {
        case response = "data"
    }
}

struct ProfileResult: Codable {
    var eSim: ESIMProfile
    
    private enum CodingKeys: String, CodingKey {
        case eSim = "results"
    }
}

/// Represents the detailed eSIM information
struct ESIMProfile: Codable {
    /// Integrated Circuit Card Identifier
    var iccid: String

    /// International Mobile Subscriber Identity
    var imsi: Int

    /// Current state of the eSIM profile
    var state: String

    /// Timestamp of the last operation in Unix time
    var lastOperationDate: Int

    /// Activation code for the eSIM
    var activationCode: String

    /// Indicates if profile reuse is enabled
    var reuseEnabled: Bool

    /// Indicates if confirmation code is required
    var ccRequired: Bool

    /// Policy details for profile reuse
    var profileReusePolicy: ProfileReusePolicy

    /// Remaining count for profile reuse
    var reuseRemainingCount: Int

    /// Timestamp when the profile was released in Unix time
    var releaseDate: Int

    /// Embedded Identity Document
    var eid: String

    /// Message describing the current state
    var stateMessage: String

    /// UTC timestamp of the last operation
    var lastOperationDateUTC: String

    /// UTC timestamp of the release date
    var releaseDateUTC: String

    private enum CodingKeys: String, CodingKey {
        case iccid
        case imsi
        case state
        case lastOperationDate = "last_operation_date"
        case activationCode = "activation_code"
        case reuseEnabled = "reuse_enabled"
        case ccRequired = "cc_required"
        case profileReusePolicy = "profile_reuse_policy"
        case reuseRemainingCount = "reuse_remaining_count"
        case releaseDate = "release_date"
        case eid
        case stateMessage = "state_message"
        case lastOperationDateUTC = "last_operation_date_utc"
        case releaseDateUTC = "release_date_utc"
    }
}

/// Represents the policy for eSIM profile reuse
struct ProfileReusePolicy: Codable {
    /// Type of reuse policy
    var reuseType: String

    /// Maximum number of reuses allowed
    var maxCount: String

    private enum CodingKeys: String, CodingKey {
        case reuseType = "reuse_type"
        case maxCount = "max_count"
    }
}
