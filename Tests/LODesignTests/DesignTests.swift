import Testing
import LODesign

@Suite("LODesign")
struct DesignTests {
    @Test("All color tokens have valid hex format")
    func colorHexFormat() {
        for token in LOColorToken.allCases {
            #expect(token.hex.hasPrefix("#"), "\(token) hex should start with #")
            #expect(token.hex.count == 7, "\(token) hex should be 7 chars (#RRGGBB)")
        }
    }

    @Test("Color tokens have CSS variable names")
    func colorCSSVars() {
        for token in LOColorToken.allCases {
            #expect(token.cssVar.hasPrefix("--"), "\(token) CSS var should start with --")
        }
    }

    @Test("CSS root output contains all tokens")
    func cssRoot() {
        let css = LOColorToken.cssRoot()
        #expect(css.contains(":root"))
        for token in LOColorToken.allCases {
            #expect(css.contains(token.cssVar), "CSS root missing \(token.cssVar)")
            #expect(css.contains(token.hex), "CSS root missing \(token.hex)")
        }
    }

    @Test("Accent is purple400")
    func accent() {
        #expect(LOColorToken.accent == .purple400)
    }

    @Test("Spacing tokens have positive values")
    func spacing() {
        for token in LOSpacingToken.allCases {
            #expect(token.rawValue > 0, "Spacing \(token) should be positive")
        }
    }

    @Test("Font tokens have family names")
    func fontFamilies() {
        let display = LOFontToken.display(size: 32, weight: .bold)
        let body = LOFontToken.body(size: 16, weight: .regular)
        let mono = LOFontToken.mono(size: 14)

        #expect(display.familyName.contains("SF Pro"))
        #expect(body.familyName.contains("SF Pro"))
        #expect(mono.familyName.contains("SF Mono"))
    }
}
