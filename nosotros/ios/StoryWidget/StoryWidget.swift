// Widget de iPhone: tu story a la izquierda y la de tu pareja a la derecha.
// Lee las fotos que la app guardó en el grupo compartido, así que funciona
// sin internet. Ver SETUP.md, sección "Widget en iPhone".
import SwiftUI
import WidgetKit

private let appGroup = "group.com.nosotrosapp.nosotros"

struct Side {
    let name: String
    let image: UIImage?
    let avatar: UIImage?
    let expires: Date?
}

struct StoryEntry: TimelineEntry {
    let date: Date
    let me: Side
    let partner: Side
}

private func loadImage(_ path: String?, maxSide: CGFloat) -> UIImage? {
    guard let path, let image = UIImage(contentsOfFile: path) else { return nil }
    // Los widgets tienen poca memoria: reducimos la foto.
    let scale = min(1, maxSide / max(image.size.width, image.size.height))
    if scale >= 1 { return image }
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    return UIGraphicsImageRenderer(size: size).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}

private func loadSide(_ key: String, _ data: UserDefaults?, now: Date) -> Side {
    let expires = (data?.string(forKey: "\(key)_expires")).flatMap(Double.init)
        .map { Date(timeIntervalSince1970: $0 / 1000) }
    let active = (expires ?? .distantPast) > now
    return Side(
        name: data?.string(forKey: "\(key)_name") ?? "",
        image: active ? loadImage(data?.string(forKey: "\(key)_image"), maxSide: 800) : nil,
        avatar: loadImage(data?.string(forKey: "\(key)_avatar"), maxSide: 120),
        expires: active ? expires : nil
    )
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StoryEntry {
        StoryEntry(date: Date(),
                   me: Side(name: "Yo", image: nil, avatar: nil, expires: nil),
                   partner: Side(name: "Mi amor", image: nil, avatar: nil, expires: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (StoryEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StoryEntry>) -> Void) {
        let now = Date()
        let current = entry(at: now)
        // Volvemos a dibujar justo cuando expire una story (o en 30 min).
        var next = now.addingTimeInterval(30 * 60)
        for e in [current.me.expires, current.partner.expires].compactMap({ $0 }) where e < next {
            next = e.addingTimeInterval(1)
        }
        completion(Timeline(entries: [current], policy: .after(next)))
    }

    private func entry(at date: Date) -> StoryEntry {
        let data = UserDefaults(suiteName: appGroup)
        return StoryEntry(date: date,
                          me: loadSide("me", data, now: date),
                          partner: loadSide("partner", data, now: date))
    }
}

struct HalfView: View {
    let side: Side
    let isMine: Bool

    var body: some View {
        ZStack(alignment: isMine ? .bottomLeading : .bottomTrailing) {
            Color(red: 0.14, green: 0.12, blue: 0.16)
            if let image = side.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(isMine ? "Sube tu story" : "Sin story")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.65))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .center, endPoint: .bottom)
            HStack(spacing: 6) {
                if isMine { avatar }
                Text(side.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
                if !isMine { avatar }
            }
            .padding(8)
        }
        .clipped()
    }

    @ViewBuilder private var avatar: some View {
        if let a = side.avatar {
            Image(uiImage: a).resizable().scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
        }
    }
}

struct StoryWidgetView: View {
    let entry: StoryEntry

    var body: some View {
        HStack(spacing: 2) {
            HalfView(side: entry.me, isMine: true)
            HalfView(side: entry.partner, isMine: false)
        }
        .background(Color(red: 0.055, green: 0.043, blue: 0.063))
        .containerBackground(for: .widget) { Color(red: 0.055, green: 0.043, blue: 0.063) }
    }
}

@main
struct StoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StoryWidget", provider: Provider()) { entry in
            StoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Nosotros")
        .description("Tu story y la de tu pareja.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
