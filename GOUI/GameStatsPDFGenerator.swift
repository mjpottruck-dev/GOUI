import UIKit

/// Generates a clean PDF of game stats for sharing / MaxPreps upload.
enum GameStatsPDFGenerator {

    static func generatePDF(
        teamName: String,
        opponent: String,
        date: Date,
        goalsFor: Int,
        goalsAgainst: Int,
        players: [Player],
        stats: [UUID: PlayerStatLine],
        seconds: [UUID: Int],
        events: [MatchEvent]
    ) -> URL {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let usable = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GameStats_\(MaxPrepsExport.sanitizedFilename(opponent)).pdf")

        try? renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
            let title = "\(teamName) vs \(opponent)"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
            y += 28

            // Date + Score
            let subFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            let dateLine = "\(date.formatted(date: .abbreviated, time: .omitted))   |   Score: \(goalsFor) - \(goalsAgainst)"
            dateLine.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: subFont, .foregroundColor: UIColor.secondaryLabel])
            y += 24

            // Separator
            y += 8
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: margin + usable, y: y))
            UIColor.separator.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            y += 16

            // Goals section
            let sectionFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
            "GOALS".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: sectionFont, .foregroundColor: UIColor.secondaryLabel])
            y += 18

            let goalEvents = events.filter { $0.kind == .goal || $0.kind == .pkMade }
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let boldBody = UIFont.systemFont(ofSize: 12, weight: .semibold)

            if goalEvents.isEmpty {
                "No goals".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.tertiaryLabel])
                y += 18
            } else {
                for event in goalEvents.sorted(by: { $0.seconds < $1.seconds }) {
                    let time = String(format: "%02d:%02d", event.seconds / 60, event.seconds % 60)
                    time.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
                    event.title.draw(at: CGPoint(x: margin + 50, y: y), withAttributes: [.font: boldBody])
                    if let detail = event.detail, !detail.isEmpty {
                        detail.draw(at: CGPoint(x: margin + 200, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
                    }
                    y += 18
                }
            }
            y += 10

            // Player Stats Table
            "PLAYER STATS".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: sectionFont, .foregroundColor: UIColor.secondaryLabel])
            y += 18

            // Header row
            let headerFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
            let cols: [(String, CGFloat)] = [
                ("#", 30), ("Name", 120), ("Min", 40), ("G", 30), ("A", 30),
                ("Sh", 30), ("SOT", 35), ("Sv", 30), ("YC", 30), ("RC", 30)
            ]
            var x: CGFloat = margin
            for (label, w) in cols {
                label.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: headerFont, .foregroundColor: UIColor.secondaryLabel])
                x += w
            }
            y += 16

            // Player rows
            let sorted = players.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
            for player in sorted {
                let line = stats[player.id] ?? PlayerStatLine()
                let mins = (seconds[player.id] ?? 0) / 60
                guard mins > 0 || line.goals > 0 || line.assists > 0 else { continue }

                if y > pageHeight - margin - 20 {
                    ctx.beginPage()
                    y = margin
                }

                x = margin
                let vals: [String] = [
                    "\(player.number)", player.name, "\(mins)", "\(line.goals)", "\(line.assists)",
                    "\(line.shots)", "\(line.shotsOnTarget)", "\(line.saves)",
                    "\(line.yellowCards)", "\(line.redCards)"
                ]
                for (i, val) in vals.enumerated() {
                    let w = cols[i].1
                    val.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: bodyFont])
                    x += w
                }
                y += 16
            }
        }

        return url
    }
}
