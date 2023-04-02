//
//  File.swift
//  
//
//  Created by Will Chiong on 4/1/23.
//

import Foundation

public struct Hand {
    private let cards: [PlayingCard]
 
    public var numberOfCards: Int {
        return cards.count
    }
 
    init(cards: [PlayingCard]) {
        self.cards = cards
    }
}

