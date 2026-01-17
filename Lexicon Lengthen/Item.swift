//
//  Item.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
