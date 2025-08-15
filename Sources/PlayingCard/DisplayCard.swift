//
//  DisplayCard.swift
//  
//
//  Created by Will Chiong on 4/2/23.
//

#if canImport(SwiftUI) && !CI_BUILD
import SwiftUI

@available(macOS 10.15, *)
public struct DisplayCard: View {
    public init(card: PlayingCard){
        self.card = card
    }
    
    let card: PlayingCard
    
    let bgColor: Color = Color.white
    
    var suitColor:[Suit:Color] = [Suit.clubs:Color.black, Suit.spades: Color.black, Suit.diamonds: Color.red, Suit.hearts: Color.red]
    
    public var body: some View {
        VStack(alignment: .center) {
            Text(card.rank.description)
                .font(.subheadline)
                .frame(width: 29.0)
                .foregroundColor(suitColor[card.suit])
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6.0)
            Text(card.suit.description)
                .font(.headline)
                .frame(width: 29.0)
                .multilineTextAlignment(.center)
        }
        .background(bgColor)
        .frame(width: 29.0, height: 41.0)
        .cornerRadius(.infinity)
        .padding(.horizontal, 0.0)
        .border(Color.black)
    }
}

@available(macOS 10.15, *)
struct DisplayCard_Preview: PreviewProvider {
    static var previews: some View {
        DisplayCard(card: PlayingCard(rank: Rank.four, suit: Suit.hearts))
    }
}
#endif
