import UIKit

/// Generates a clean PDF of the team roster (jersey, name, position, starter/sub status).
enum RosterPDFGenerator {

    static func generatePDF(team: Team, starterIDs: Set<UUID>) -> URL {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let usable = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Roster_\(MaxPrepsExport.sanitizedFilename(team.name)).pdf")

        try? renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
            team.name.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
            y += 28

            let subFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            "\(team.players.count) players".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: subFont, .foregroundColor: UIColor.secondaryLabel])
            y += 24

            // Separator
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: margin + usable, y: y))
            UIColor.separator.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            y += 16

            // Header
            let headerFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
            let cols: [(String, CGFloat)] = [("#", 40), ("Name", 180), ("Position", 100), ("Status", 80)]
            var x: CGFloat = margin
            for (label, w) in cols {
                label.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: headerFont, .foregroundColor: UIColor.secondaryLabel])
                x += w
            }
            y += 18

            // Player rows
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let boldBody = UIFont.systemFont(ofSize: 12, weight: .semibold)

            let sorted = team.players.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
            for player in sorted {
                if y > pageHeight - margin - 20 {
                    ctx.beginPage()
                    y = margin
                }

                x = margin
                let status = starterIDs.contains(player.id) ? "Starter" : "Sub"
                let position = player.positionName ?? player.position.rawValue
                let vals: [(String, UIFont)] = [
                    ("\(player.number)", boldBody),
                    (player.name, bodyFont),
                    (position, bodyFont),
                    (status, bodyFont)
                ]
                for (i, (val, font)) in vals.enumerated() {
                    let w = cols[i].1
                    val.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: font])
                    x += w
                }
                y += 18
            }
        }

        return url
    }
}
