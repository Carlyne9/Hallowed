import SwiftUI

enum HallowedDesign {
    enum Palette {
        static let background = SwiftUI.Color(hex: "FAF8F5")
        static let backgroundWarm = SwiftUI.Color(hex: "FFF4E6")
        static let backgroundBlush = SwiftUI.Color(hex: "F7D8BF")
        static let backgroundDepth = SwiftUI.Color(hex: "EAD8C5")
        static let sidebar = SwiftUI.Color(hex: "F5F1EB")
        static let surface = SwiftUI.Color(hex: "F2ECE4")
        static let surfaceRaised = SwiftUI.Color(hex: "FFFDF9")
        static let surfaceGlass = SwiftUI.Color.white.opacity(0.64)
        static let surfaceSubtle = SwiftUI.Color(hex: "EFE7DC")
        static let border = SwiftUI.Color(hex: "E8DDD3")
        static let borderStrong = SwiftUI.Color(hex: "D8CEC4")

        static let textPrimary = SwiftUI.Color(hex: "2D2420")
        static let textSecondary = SwiftUI.Color(hex: "5A4A3A")
        static let textMuted = SwiftUI.Color(hex: "8B7B6E")
        static let textFaint = SwiftUI.Color(hex: "B0A098")
        static let textOnAccent = SwiftUI.Color.white

        static let accent = SwiftUI.Color(hex: "8B6F4E")
        static let accentHover = SwiftUI.Color(hex: "7A5F3E")
        static let accentSoft = SwiftUI.Color(hex: "EFE7DC")
        static let accentGlow = SwiftUI.Color(hex: "C49A6C")
        static let amberAura = SwiftUI.Color(hex: "F1B66B")
        static let roseAura = SwiftUI.Color(hex: "D79A7A")
        static let oliveAura = SwiftUI.Color(hex: "A7A06A")

        static let success = SwiftUI.Color(hex: "6E8B62")
        static let warning = SwiftUI.Color(hex: "C9852B")
        static let destructive = SwiftUI.Color(hex: "B94A36")
        static let urgent = SwiftUI.Color(hex: "E07B5A")

        enum PrayerSession {
            static let background = SwiftUI.Color(hex: "1C1612")
            static let surface = SwiftUI.Color(hex: "261E18")
            static let surfaceDeep = SwiftUI.Color(hex: "1F1814")
            static let textPrimary = SwiftUI.Color(hex: "F5EDE0")
            static let textMuted = SwiftUI.Color(hex: "8B7B6E")
            static let divider = SwiftUI.Color(hex: "3D302A")
        }
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let full: CGFloat = 999
    }

    enum Layout {
        static let sidebarMinWidth: CGFloat = 230
        static let sidebarIdealWidth: CGFloat = 250
        static let sidebarMaxWidth: CGFloat = 290
        static let popoverWidth: CGFloat = 520
        static let minimumHitArea: CGFloat = 44
    }

    enum Typography {
        static let appTitle = SwiftUI.Font.system(size: 15, weight: .semibold, design: .serif)
        static let screenTitle = SwiftUI.Font.system(size: 28, weight: .semibold, design: .serif)
        static let sectionTitle = SwiftUI.Font.system(size: 22, weight: .bold, design: .rounded)
        static let heading = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = SwiftUI.Font.system(size: 15, weight: .regular)
        static let bodyStrong = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let label = SwiftUI.Font.system(size: 13, weight: .medium)
        static let caption = SwiftUI.Font.system(size: 12, weight: .regular)
        static let micro = SwiftUI.Font.system(size: 10, weight: .regular)
        static let prayerBody = SwiftUI.Font.system(size: 17, weight: .light)
        static let scripture = SwiftUI.Font.system(size: 14, weight: .regular).italic()
    }

    enum Shadow {
        static let soft = SwiftUI.Color(hex: "2D2420").opacity(0.06)
        static let elevated = SwiftUI.Color(hex: "2D2420").opacity(0.12)
        static let spatial = SwiftUI.Color(hex: "7A5F3E").opacity(0.16)
    }

    enum Experimental {
        static let canvas = SwiftUI.Color(hex: "11130F")
        static let panel = SwiftUI.Color(hex: "181A16")
        static let panelRaised = SwiftUI.Color(hex: "242721")
        static let glass = SwiftUI.Color.white.opacity(0.08)
        static let glassStrong = SwiftUI.Color.white.opacity(0.14)
        static let line = SwiftUI.Color.white.opacity(0.12)
        static let lineStrong = SwiftUI.Color.white.opacity(0.22)
        static let text = SwiftUI.Color(hex: "F4F0E7")
        static let muted = SwiftUI.Color(hex: "AAA69C")
        static let faint = SwiftUI.Color(hex: "6E716A")
        static let blue = SwiftUI.Color(hex: "7FA6FF")
        static let amber = SwiftUI.Color(hex: "D4973B")
        static let green = SwiftUI.Color(hex: "7EE18B")
        static let rose = SwiftUI.Color(hex: "D86E8B")
    }
}

struct HallowedSpatialBackground: View {
    var body: some View {
        HallowedDesign.Palette.background
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct HallowedSpatialCard<Content: View>: View {
    var cornerRadius: CGFloat = HallowedDesign.Radius.xl
    var padding: CGFloat = HallowedDesign.Spacing.xl
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(HallowedDesign.Palette.surfaceRaised)
                    .shadow(color: HallowedDesign.Shadow.soft, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(HallowedDesign.Palette.border, lineWidth: 1)
            )
    }
}

struct HallowedExperimentalBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    HallowedDesign.Experimental.canvas,
                    Color(hex: "151712"),
                    Color(hex: "0D0F12")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(HallowedDesign.Experimental.blue.opacity(0.18))
                .frame(width: 520, height: 520)
                .blur(radius: 120)
                .offset(x: 270, y: -180)

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.12))
                .frame(width: 430, height: 430)
                .blur(radius: 110)
                .offset(x: -240, y: 250)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct HallowedExperimentalCard<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 24
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(HallowedDesign.Experimental.glass)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 18)
    }
}
// MARK: - Theme Illustration

struct HallowedThemeIllustration: View {
    let themeName: String
    let icon: String

    var body: some View {
        ZStack {
            baseAura
            metaphor
        }
        .accessibilityHidden(true)
    }

    private var normalizedName: String {
        themeName.lowercased()
    }

    private var baseAura: some View {
        ZStack {
            Circle()
                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                .frame(width: 106, height: 106)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HallowedDesign.Experimental.amber.opacity(0.24),
                            HallowedDesign.Experimental.amber.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 58
                    )
                )
                .frame(width: 116, height: 116)
        }
    }

    @ViewBuilder
    private var metaphor: some View {
        switch normalizedName {
        case let name where name.contains("thanksgiving"):
            offeringBowl
        case let name where name.contains("holy spirit"):
            windAndFlame
        case let name where name.contains("intercession"):
            bridgeOfLights
        case let name where name.contains("confession"):
            washedHeart
        case let name where name.contains("worship"):
            risingPraise
        case let name where name.contains("identity"):
            fingerprintStar
        case let name where name.contains("guidance"):
            lanternPath
        case let name where name.contains("warfare"):
            shieldAndSparks
        case let name where name.contains("healing"):
            mendedVessel
        case let name where name.contains("nations"):
            connectedGlobe
        case let name where name.contains("family"):
            gatheredHome
        case let name where name.contains("ministry"):
            openDoorFlame
        case let name where name.contains("blessing"):
            fruitBranch
        case let name where name.contains("lament"):
            rainAndEmber
        case let name where name.contains("love"):
            protectedFlame
        case let name where name.contains("hope"):
            sunriseHorizon
        case let name where name.contains("peace"):
            stillWaterLeaf
        case let name where name.contains("fear"):
            calmedStorm
        case let name where name.contains("temptation"):
            guardedPath
        case let name where name.contains("trust"):
            deepAnchor
        case let name where name.contains("anger"):
            cooledEmber
        case let name where name.contains("pride"):
            loweredCrown
        default:
            fallbackIllustration
        }
    }

    private var offeringBowl: some View {
        ZStack {
            cuppedHands
                .offset(y: 22)

            Circle()
                .fill(amberGradient)
                .frame(width: 34, height: 34)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.45), radius: 18, x: 0, y: 8)
                .offset(y: -6)

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(HallowedDesign.Experimental.amber.opacity(0.72 - Double(index) * 0.1))
                    .frame(width: 3, height: 26 + CGFloat(index * 4))
                    .offset(x: CGFloat(index * 12 - 18), y: -30)
                    .rotationEffect(.degrees(Double(index * 8 - 12)))
            }

            sparkle(x: 32, y: -30, size: 14)
            sparkle(x: -34, y: -18, size: 10)
        }
    }

    private var windAndFlame: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Path { path in
                    let y = CGFloat(index * 18 + 24)
                    path.move(to: CGPoint(x: 18, y: y))
                    path.addCurve(to: CGPoint(x: 72, y: y - 8), control1: CGPoint(x: 36, y: y - 14), control2: CGPoint(x: 54, y: y + 8))
                    path.addCurve(to: CGPoint(x: 92, y: y - 14), control1: CGPoint(x: 84, y: y - 18), control2: CGPoint(x: 96, y: y - 6))
                }
                .stroke(HallowedDesign.Experimental.text.opacity(0.36 - Double(index) * 0.06), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 118, height: 118)
            }

            Image(systemName: "flame.fill")
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.amber)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.24), radius: 14, x: 0, y: 8)
                .offset(x: 18, y: 12)
        }
    }

    private var bridgeOfLights: some View {
        ZStack {
            miniPerson(x: -27, y: 4)
            miniPerson(x: 27, y: 4)

            Path { path in
                path.move(to: CGPoint(x: 45, y: 72))
                path.addCurve(to: CGPoint(x: 73, y: 72), control1: CGPoint(x: 53, y: 65), control2: CGPoint(x: 65, y: 65))
            }
            .stroke(HallowedDesign.Experimental.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 118, height: 118)

            sparkle(x: 0, y: -34, size: 14)
        }
    }

    private var washedHeart: some View {
        ZStack {
            Image(systemName: "cross.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.amber)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.35), radius: 14, x: 0, y: 4)
                .offset(y: -30)

            reachingHands
                .offset(y: 20)
        }
    }

    private var risingPraise: some View {
        ZStack {
            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.26))
                .frame(width: 62, height: 62)
                .blur(radius: 12)
                .offset(x: 22, y: -24)

            Circle()
                .fill(HallowedDesign.Experimental.text.opacity(0.7))
                .frame(width: 16, height: 16)
                .offset(x: -18, y: -6)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.58))
                .frame(width: 24, height: 38)
                .rotationEffect(.degrees(24))
                .offset(x: -8, y: 22)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.48))
                .frame(width: 46, height: 8)
                .offset(x: 12, y: 42)

            Path { path in
                path.move(to: CGPoint(x: 53, y: 54))
                path.addCurve(to: CGPoint(x: 72, y: 42), control1: CGPoint(x: 58, y: 43), control2: CGPoint(x: 66, y: 39))
                path.move(to: CGPoint(x: 57, y: 60))
                path.addCurve(to: CGPoint(x: 76, y: 51), control1: CGPoint(x: 62, y: 51), control2: CGPoint(x: 69, y: 49))
            }
            .stroke(HallowedDesign.Experimental.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 118, height: 118)

            Capsule()
                .fill(HallowedDesign.Experimental.amber.opacity(0.82))
                .frame(width: 4, height: 34)
                .offset(x: 33, y: -18)

            sparkle(x: 28, y: -35, size: 15)
        }
    }

    private var fingerprintStar: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 22)
                    .stroke(HallowedDesign.Experimental.text.opacity(0.22 + Double(index) * 0.08), lineWidth: 2)
                    .frame(width: 34 + CGFloat(index * 12), height: 46 + CGFloat(index * 12))
                    .rotationEffect(.degrees(Double(index * 8 - 12)))
            }

            Text("?")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(HallowedDesign.Experimental.amber)
        }
    }

    private var lanternPath: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 16, y: 100))
                path.addCurve(to: CGPoint(x: 62, y: 70), control1: CGPoint(x: 24, y: 82), control2: CGPoint(x: 48, y: 88))
                path.addCurve(to: CGPoint(x: 98, y: 98), control1: CGPoint(x: 76, y: 50), control2: CGPoint(x: 90, y: 74))
            }
            .stroke(HallowedDesign.Experimental.lineStrong, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 118, height: 118)

            Image(systemName: "lantern.fill")
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.78))
                .offset(y: -10)

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.72))
                .frame(width: 18, height: 18)
                .blur(radius: 5)
                .offset(y: 5)
        }
    }

    private var shieldAndSparks: some View {
        ZStack {
            Image(systemName: "shield")
                .font(.system(size: 76, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.68))

            Image(systemName: "book.closed.fill")
                .font(.system(size: 29, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.canvas.opacity(0.9))
                .offset(y: 3)

            Image(systemName: "cross.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(HallowedDesign.Experimental.amber)
                .offset(y: 3)
        }
    }

    private var mendedVessel: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 34, y: 44))
                path.addCurve(to: CGPoint(x: 84, y: 44), control1: CGPoint(x: 46, y: 28), control2: CGPoint(x: 72, y: 28))
                path.addLine(to: CGPoint(x: 76, y: 86))
                path.addCurve(to: CGPoint(x: 42, y: 86), control1: CGPoint(x: 66, y: 94), control2: CGPoint(x: 52, y: 94))
                path.closeSubpath()
            }
            .fill(HallowedDesign.Experimental.text.opacity(0.22))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 34, y: 44))
                    path.addCurve(to: CGPoint(x: 84, y: 44), control1: CGPoint(x: 46, y: 28), control2: CGPoint(x: 72, y: 28))
                    path.addLine(to: CGPoint(x: 76, y: 86))
                    path.addCurve(to: CGPoint(x: 42, y: 86), control1: CGPoint(x: 66, y: 94), control2: CGPoint(x: 52, y: 94))
                    path.closeSubpath()
                }
                .stroke(HallowedDesign.Experimental.text.opacity(0.56), lineWidth: 3)
            )
            .frame(width: 118, height: 118)

            Path { path in
                path.move(to: CGPoint(x: 58, y: 36))
                path.addLine(to: CGPoint(x: 50, y: 54))
                path.addLine(to: CGPoint(x: 60, y: 66))
                path.addLine(to: CGPoint(x: 52, y: 88))
            }
            .stroke(HallowedDesign.Experimental.amber, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 118, height: 118)

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.28))
                .frame(width: 42, height: 42)
                .blur(radius: 9)
                .offset(x: 4, y: 5)
        }
    }

    private var connectedGlobe: some View {
        ZStack {
            Image(systemName: "globe")
                .font(.system(size: 54, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.5))

            ForEach([CGPoint(x: -28, y: -14), CGPoint(x: 14, y: -28), CGPoint(x: 30, y: 16), CGPoint(x: -12, y: 28)], id: \.debugDescription) { point in
                Circle()
                    .fill(HallowedDesign.Experimental.amber)
                    .frame(width: 9, height: 9)
                    .offset(x: point.x, y: point.y)
            }

            Capsule()
                .fill(HallowedDesign.Experimental.lineStrong)
                .frame(width: 66, height: 2)
                .rotationEffect(.degrees(24))
        }
    }

    private var gatheredHome: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.7))

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index == 0 ? HallowedDesign.Experimental.amber : HallowedDesign.Experimental.text.opacity(0.58))
                    .frame(width: 10, height: 10)
                    .offset(y: -43)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
        }
    }

    private var openDoorFlame: some View {
        ZStack {
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 44, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    HallowedDesign.Experimental.text.opacity(0.58),
                    HallowedDesign.Experimental.amber.opacity(0.72)
                )
                .offset(y: 22)

            Image(systemName: "flame.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.amber)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.35), radius: 14, x: 0, y: 7)
                .offset(y: -16)
        }
    }

    private var fruitBranch: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 24, y: 84))
                path.addCurve(to: CGPoint(x: 86, y: 36), control1: CGPoint(x: 44, y: 70), control2: CGPoint(x: 52, y: 38))
            }
            .stroke(HallowedDesign.Experimental.text.opacity(0.54), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 118, height: 118)

            ForEach([CGPoint(x: -21, y: -3), CGPoint(x: -2, y: -25), CGPoint(x: 21, y: -10), CGPoint(x: 31, y: 15)], id: \.debugDescription) { point in
                Circle()
                    .fill(amberGradient)
                    .frame(width: 20, height: 20)
                    .shadow(color: HallowedDesign.Experimental.amber.opacity(0.24), radius: 10, x: 0, y: 4)
                    .offset(x: point.x, y: point.y)
            }

            Circle()
                .stroke(HallowedDesign.Experimental.amber.opacity(0.7), lineWidth: 2)
                .frame(width: 72, height: 72)
                .offset(x: 12, y: -8)
        }
    }

    private var rainAndEmber: some View {
        ZStack {
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 52, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.5))
                .offset(y: -12)

            Circle()
                .fill(HallowedDesign.Experimental.amber)
                .frame(width: 20, height: 20)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.35), radius: 14, x: 0, y: 6)
                .offset(y: 38)
        }
    }

    private var protectedFlame: some View {
        ZStack {
            ForEach([-13, 13], id: \.self) { x in
                Image(systemName: "heart.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(x < 0 ? HallowedDesign.Experimental.amber.opacity(0.78) : HallowedDesign.Experimental.text.opacity(0.5))
                    .offset(x: CGFloat(x), y: 0)
            }

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.22))
                .frame(width: 54, height: 54)
                .blur(radius: 10)
        }
    }

    private var sunriseHorizon: some View {
        ZStack {
            Rectangle()
                .fill(HallowedDesign.Experimental.canvas.opacity(0.86))
                .frame(width: 90, height: 34)
                .offset(y: 38)

            Capsule()
                .fill(HallowedDesign.Experimental.lineStrong)
                .frame(width: 92, height: 5)
                .offset(y: 30)

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.95))
                .frame(width: 48, height: 48)
                .offset(y: 24)
                .mask(
                    Rectangle()
                        .frame(width: 92, height: 32)
                        .offset(y: 14)
                )

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(HallowedDesign.Experimental.amber.opacity(0.8))
                    .frame(width: 3, height: 14)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(index * 22 - 44)))
            }
        }
    }

    private var stillWaterLeaf: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .stroke(HallowedDesign.Experimental.line.opacity(0.9 - Double(index) * 0.18), lineWidth: 2)
                    .frame(width: 82 + CGFloat(index * 12), height: 26 + CGFloat(index * 4))
                    .offset(y: 20)
            }

            Image(systemName: "leaf.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.green.opacity(0.78))
                .rotationEffect(.degrees(-18))
                .offset(y: -10)
        }
    }

    private var calmedStorm: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Path { path in
                    let inset = CGFloat(index * 8)
                    path.addArc(
                        center: CGPoint(x: 59, y: 59),
                        radius: 43 - inset,
                        startAngle: .degrees(Double(index * 22 - 155)),
                        endAngle: .degrees(Double(index * 28 + 80)),
                        clockwise: false
                    )
                }
                .stroke(HallowedDesign.Experimental.text.opacity(0.36 - Double(index) * 0.05), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 118, height: 118)
            }

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.72))
                .frame(width: 26, height: 26)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.28), radius: 16, x: 0, y: 0)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.34))
                .frame(width: 34, height: 4)
                .offset(x: -42, y: -4)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.28))
                .frame(width: 26, height: 4)
                .offset(x: 43, y: 12)
        }
    }

    private var guardedPath: some View {
        ZStack {
            Circle()
                .fill(amberGradient)
                .frame(width: 46, height: 46)
                .offset(y: 18)

            Image(systemName: "leaf.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.green.opacity(0.72))
                .rotationEffect(.degrees(-24))
                .offset(x: 16, y: -14)

            Path { path in
                path.move(to: CGPoint(x: 32, y: 42))
                path.addCurve(to: CGPoint(x: 85, y: 40), control1: CGPoint(x: 42, y: 16), control2: CGPoint(x: 88, y: 16))
                path.addCurve(to: CGPoint(x: 50, y: 58), control1: CGPoint(x: 82, y: 60), control2: CGPoint(x: 42, y: 42))
                path.addCurve(to: CGPoint(x: 90, y: 80), control1: CGPoint(x: 62, y: 82), control2: CGPoint(x: 92, y: 62))
            }
            .stroke(HallowedDesign.Experimental.text.opacity(0.76), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(width: 118, height: 118)

            Circle()
                .fill(HallowedDesign.Experimental.rose.opacity(0.74))
                .frame(width: 10, height: 10)
                .offset(x: 24, y: -25)

            Circle()
                .fill(HallowedDesign.Experimental.text.opacity(0.8))
                .frame(width: 5, height: 5)
                .offset(x: 16, y: -20)
        }
    }

    private var deepAnchor: some View {
        ZStack {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 44, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.66))
                .rotationEffect(.degrees(-26))
                .offset(x: -18, y: 20)

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.86))
                .frame(width: 22, height: 22)
                .shadow(color: HallowedDesign.Experimental.amber.opacity(0.42), radius: 16, x: 0, y: 0)
                .offset(x: 20, y: -18)

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(HallowedDesign.Experimental.amber.opacity(0.7 - Double(index) * 0.1))
                    .frame(width: 3, height: 24 - CGFloat(index * 2))
                    .offset(x: CGFloat(index * 9 - 13), y: -36)
                    .rotationEffect(.degrees(Double(index * 8 - 14)))
            }

            Path { path in
                path.move(to: CGPoint(x: 34, y: 84))
                path.addCurve(to: CGPoint(x: 84, y: 54), control1: CGPoint(x: 52, y: 86), control2: CGPoint(x: 70, y: 70))
            }
            .stroke(HallowedDesign.Experimental.lineStrong, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 118, height: 118)
        }
    }

    private var cooledEmber: some View {
        ZStack {
            personSilhouette
                .offset(y: 16)

            ForEach([-22, 22], id: \.self) { x in
                Path { path in
                    path.move(to: CGPoint(x: 59, y: 40))
                    path.addCurve(to: CGPoint(x: 59, y: 15), control1: CGPoint(x: 45, y: 34), control2: CGPoint(x: 73, y: 24))
                }
                .stroke(HallowedDesign.Experimental.rose.opacity(0.76), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 118, height: 118)
                .offset(x: CGFloat(x))
            }
        }
    }

    private var loweredCrown: some View {
        ZStack {
            Image(systemName: "crown.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.62))
                .rotationEffect(.degrees(155))
                .offset(x: -4, y: 10)

            Capsule()
                .fill(HallowedDesign.Experimental.lineStrong)
                .frame(width: 66, height: 4)
                .offset(y: 40)

            Image(systemName: "arrow.down")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(HallowedDesign.Experimental.amber)
                .offset(x: 30, y: -26)
        }
    }

    private var cuppedHands: some View {
        Image(systemName: "hands.sparkles.fill")
            .font(.system(size: 42, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(
                HallowedDesign.Experimental.text.opacity(0.64),
                HallowedDesign.Experimental.amber.opacity(0.82)
            )
    }

    private var reachingHands: some View {
        ZStack {
            ForEach([-1, 1], id: \.self) { side in
                ZStack {
                    Capsule()
                        .fill(HallowedDesign.Experimental.text.opacity(0.42))
                        .frame(width: 8, height: 36)
                        .offset(y: 22)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 27, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(HallowedDesign.Experimental.text.opacity(0.72))
                        .offset(y: -2)
                }
                .scaleEffect(x: CGFloat(side), y: 1)
                .rotationEffect(.degrees(Double(side) * -16))
                .offset(x: CGFloat(side * 19), y: 4)
            }

            ForEach([-18, 0, 18], id: \.self) { x in
                Capsule()
                    .fill(HallowedDesign.Experimental.amber.opacity(0.36))
                    .frame(width: 3, height: 18)
                    .offset(x: CGFloat(x), y: -30)
            }
        }
        .frame(width: 118, height: 82)
    }

    private var releasingHands: some View {
        ZStack {
            ForEach([-1, 1], id: \.self) { side in
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(HallowedDesign.Experimental.text.opacity(0.62))
                    .scaleEffect(x: CGFloat(side), y: 1)
                    .rotationEffect(.degrees(Double(side) * 22))
                    .offset(x: CGFloat(side * 22), y: -4)
            }

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.24))
                .frame(width: 32, height: 32)
                .blur(radius: 7)
                .offset(y: 20)
        }
        .frame(width: 118, height: 66)
    }

    private var personSilhouette: some View {
        ZStack {
            Circle()
                .fill(HallowedDesign.Experimental.text.opacity(0.68))
                .frame(width: 20, height: 20)
                .offset(y: -28)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HallowedDesign.Experimental.text.opacity(0.56))
                .frame(width: 30, height: 44)
                .offset(y: 6)
        }
    }

    private func miniPerson(x: CGFloat, y: CGFloat) -> some View {
        personSilhouette
            .scaleEffect(0.62)
            .offset(x: x, y: y)
    }

    private var kneelingPerson: some View {
        ZStack {
            Circle()
                .fill(HallowedDesign.Experimental.text.opacity(0.68))
                .frame(width: 18, height: 18)
                .offset(x: -12, y: -28)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.58))
                .frame(width: 26, height: 42)
                .rotationEffect(.degrees(26))
                .offset(x: -4, y: 2)

            Capsule()
                .fill(HallowedDesign.Experimental.text.opacity(0.48))
                .frame(width: 42, height: 8)
                .offset(x: 12, y: 32)

            Path { path in
                path.move(to: CGPoint(x: 52, y: 48))
                path.addCurve(to: CGPoint(x: 70, y: 48), control1: CGPoint(x: 58, y: 38), control2: CGPoint(x: 65, y: 38))
            }
            .stroke(HallowedDesign.Experimental.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 118, height: 118)
        }
    }

    private var bowl: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 8, y: 16))
                path.addCurve(to: CGPoint(x: 62, y: 16), control1: CGPoint(x: 22, y: 32), control2: CGPoint(x: 48, y: 32))
                path.addCurve(to: CGPoint(x: 52, y: 40), control1: CGPoint(x: 60, y: 28), control2: CGPoint(x: 58, y: 36))
                path.addLine(to: CGPoint(x: 18, y: 40))
                path.addCurve(to: CGPoint(x: 8, y: 16), control1: CGPoint(x: 12, y: 36), control2: CGPoint(x: 10, y: 28))
            }
            .fill(HallowedDesign.Experimental.text.opacity(0.18))

            Path { path in
                path.move(to: CGPoint(x: 8, y: 16))
                path.addCurve(to: CGPoint(x: 62, y: 16), control1: CGPoint(x: 22, y: 32), control2: CGPoint(x: 48, y: 32))
            }
            .stroke(HallowedDesign.Experimental.text.opacity(0.52), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Capsule()
                .fill(HallowedDesign.Experimental.amber.opacity(0.34))
                .frame(width: 42, height: 10)
                .blur(radius: 5)
                .offset(y: -1)
        }
    }

    private var amberGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F3B04C"),
                HallowedDesign.Experimental.amber,
                Color(hex: "8F5C22")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sparkle(x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(HallowedDesign.Experimental.amber.opacity(0.9))
            .offset(x: x, y: y)
    }

    private var fallbackIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(HallowedDesign.Experimental.glass)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                )
                .rotationEffect(.degrees(-8))

            Circle()
                .fill(HallowedDesign.Experimental.amber.opacity(0.12))
                .frame(width: 88, height: 88)

            Image(systemName: icon)
                .font(.system(size: 38, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(HallowedDesign.Experimental.text.opacity(0.72))
        }
    }
}


// MARK: - Design System Preview

private struct HallowedThemeIllustrationPreviewGrid: View {
    private let themes = [
        "Thanksgiving",
        "The Holy Spirit",
        "Intercession",
        "Confession & Repentance",
        "Worship & Adoration",
        "Identity & Purpose",
        "Guidance & Wisdom",
        "Spiritual Warfare",
        "Healing & Restoration",
        "The Nations & Mission",
        "Family & Relationships",
        "Ministry & Calling",
        "Blessing & Fruitfulness",
        "Lament",
        "Love",
        "Hope",
        "Peace",
        "Fear & Anxiety",
        "Temptation",
        "Trust",
        "Anger",
        "Pride"
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        ZStack {
            HallowedExperimentalBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme Illustration System")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .foregroundColor(HallowedDesign.Experimental.text)

                        Text("Reusable vector/SVG-style metaphors pulled into the design system.")
                            .font(HallowedDesign.Typography.caption)
                            .foregroundColor(HallowedDesign.Experimental.muted)
                    }

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(themes, id: \.self) { theme in
                            VStack(spacing: 12) {
                                HallowedThemeIllustration(themeName: theme, icon: "sparkle")
                                    .frame(width: 118, height: 118)

                                Text(theme)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(HallowedDesign.Experimental.text)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(minHeight: 34)
                            }
                            .frame(maxWidth: .infinity, minHeight: 178)
                            .padding(16)
                            .background(HallowedDesign.Experimental.glass)
                            .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.xl, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HallowedDesign.Radius.xl, style: .continuous)
                                    .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(32)
            }
        }
    }
}

#Preview("Theme Illustration System") {
    HallowedThemeIllustrationPreviewGrid()
        .frame(width: 980, height: 720)
}
