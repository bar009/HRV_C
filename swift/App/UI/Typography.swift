import SwiftUI

// SF Pro type ramp (Figma Foundations — Typography). Built on the system text
// styles so Dynamic Type scales automatically through XXXL.
extension Font {
    static let hrvDisplay     = Font.system(.largeTitle).weight(.semibold)  // Display ~34
    static let hrvTitle       = Font.system(.title2).weight(.semibold)
    static let hrvTitle3      = Font.system(.title3).weight(.semibold)      // Title 3 ~20
    static let hrvHeadline    = Font.system(.headline)
    static let hrvBody        = Font.system(.body)
    static let hrvCallout     = Font.system(.callout)                       // Callout ~16
    static let hrvSubheadline = Font.system(.subheadline)                   // Subheadline ~15
    static let hrvFootnote    = Font.system(.footnote)
    static let hrvCaption     = Font.system(.caption)
}
