//
//  InteractiveCard.swift
//
//  An InteractiveCard can be clicked on, and can be flipped over.
//
//
//  Created by Will Chiong on 4/2/23.
//

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, *)
struct InteractiveCard: View, Hashable {
    public init(card: PlayingCard){
        self.card = card
    }

    public static func == (lhs: InteractiveCard, rhs: InteractiveCard) -> Bool {
        return lhs.card == rhs.card
    }

    var suitColor:[Suit:Color] = [Suit.clubs:Color.black, Suit.spades: Color.black, Suit.diamonds: Color.red, Suit.hearts: Color.red]


    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.card)
    }

    var card: PlayingCard
    @State
    var selected: Bool = false
    @State
    private var degrees = 0.0
    @State
    private var bgColor: Color = Color.white

    func toggleSelection() {
        selected = !selected
        if selected {
            bgColor = Color.white
        } else {
            bgColor = Color.gray
        }
    }

    mutating func replace(replacement: PlayingCard) {
        print("replacing \(self.card) with \(replacement)")
        withAnimation {
            self.degrees += 180
            self.card = replacement
        }
    }

    public var body: some View {
        Button(action: self.toggleSelection, label: {
            VStack(alignment: .center) {
                if #available(macOS 11.0, *) {
                    Text(card.rank.description)
                        .font(.title2)
                        .foregroundColor(suitColor[card.suit])
                        .multilineTextAlignment(.center)
                } else {
                    Text(card.rank.description)
                        .foregroundColor(suitColor[card.suit])
                        .multilineTextAlignment(.center)
                }
                if #available(macOS 11.0, *) {
                    Text(card.suit.description)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                } else {
                    Text(card.suit.description)
                        .multilineTextAlignment(.center)
                }
            }

        })
        .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
        .frame(width: 50.0, height: 70.0)
        .background(bgColor)
        .cornerRadius(.infinity)
        .border(Color.black)

    }
}

@available(macOS 10.15, *)
struct InteractiveCard_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveCard(card: PlayingCard(rank: Rank.four, suit: Suit.hearts))
    }
}
#endif
