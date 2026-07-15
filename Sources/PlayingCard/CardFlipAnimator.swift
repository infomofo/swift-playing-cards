// MARK: - Card Flip Animation Logic

/// Pure-logic model for the two-phase 3D card flip used in VideoPokerHandView.
///
/// The flip progresses from 0° (front visible) through 90° (edge-on midpoint)
/// to 180° (back visible), then resets to 0°. Each face uses a separate
/// `rotation3DEffect` so only the correct face is rendered at any point.
///
/// Example (redeal of two cards, ripple order 0 and 1):
/// ```swift
/// CardFlipAnimator.isFrontVisible(at: 45)   // true  — still showing front
/// CardFlipAnimator.isFrontVisible(at: 91)   // false — past midpoint, front hidden
/// CardFlipAnimator.isBackVisible(at: 91)    // true  — back now visible
/// CardFlipAnimator.rippleDelay(for: 1)      // 0.1   — second card starts 100 ms later
/// ```
public enum CardFlipAnimator {
    /// Whether the front face should be visible at the given rotation (degrees).
    public static func isFrontVisible(at degrees: Double) -> Bool {
        degrees <= 90
    }

    /// Whether the back face should be visible at the given rotation (degrees).
    public static func isBackVisible(at degrees: Double) -> Bool {
        degrees > 90
    }

    /// The rotation applied to the back face so it appears correctly across the
    /// full 0°–180° sweep. At 180° this returns 0°, which is the back face's
    /// resting (fully visible) orientation.
    public static func backFaceRotation(at degrees: Double) -> Double {
        degrees - 180
    }

    /// The delay in seconds before the card at `order` in a ripple sequence
    /// begins flipping. Order 0 starts immediately; each subsequent card is
    /// staggered by 100 ms.
    public static func rippleDelay(for order: Int) -> Double {
        Double(order) * 0.1
    }

    /// Scale for the front face at the given rotation: shrinks from 1.0 to 0.9
    /// as the card rotates from 0° to 90°, giving a subtle perspective feel.
    public static func frontFaceScale(at degrees: Double) -> Double {
        guard degrees <= 90 else { return 0.9 }
        return 1.0 - (degrees / 90) * 0.1
    }

    /// Scale for the back face at the given rotation: grows from 0.9 to 1.0
    /// as the card rotates from 90° to 180°.
    public static func backFaceScale(at degrees: Double) -> Double {
        guard degrees > 90 else { return 1.0 }
        return 0.9 + ((degrees - 90) / 90) * 0.1
    }
}
