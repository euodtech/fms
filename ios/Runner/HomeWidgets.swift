import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), open: 0, ongoing: 0, complete: 0, activeVehicles: 0, recentJobs: [], mapImagePath: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = UserDefaults(suiteName: "group.com.querta.fms")
        let recentJobsJson = data?.string(forKey: "job_recent_list") ?? "[]"
        let recentJobs = decodeRecentJobs(json: recentJobsJson)
        let mapImagePath = data?.string(forKey: "map_image_path")
        
        let entry = SimpleEntry(
            date: Date(),
            open: data?.integer(forKey: "job_open_count") ?? 0,
            ongoing: data?.integer(forKey: "job_ongoing_count") ?? 0,
            complete: data?.integer(forKey: "job_complete_count") ?? 0,
            activeVehicles: data?.integer(forKey: "map_active_count") ?? 0,
            recentJobs: recentJobs,
            mapImagePath: mapImagePath
        )
        completion(entry)
    }
// ... (getTimeline and decodeRecentJobs remain same)

struct SimpleEntry: TimelineEntry {
    let date: Date
    let open: Int
    let ongoing: Int
    let complete: Int
    let activeVehicles: Int
    let recentJobs: [JobItem]
    let mapImagePath: String?
}

struct MapWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let path = entry.mapImagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
                Image(systemName: "map.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading) {
                Text("Active: \(entry.activeVehicles)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
            .padding(8)
        }
    }
}

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
    
    func decodeRecentJobs(json: String) -> [JobItem] {
        guard let data = json.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([JobItem].self, from: data)
        } catch {
            return []
        }
    }
}

struct JobItem: Codable, Identifiable {
    var id: String { title + time }
    let title: String
    let status: String
    let time: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let open: Int
    let ongoing: Int
    let complete: Int
    let activeVehicles: Int
    let recentJobs: [JobItem]
    let mapImagePath: String?
}

struct JobWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Job Overview")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                VStack {
                    Text("Open")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(entry.open)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("Ongoing")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(entry.ongoing)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(entry.complete)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !entry.recentJobs.isEmpty {
                Text("Recent Jobs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 8)
                
                ForEach(entry.recentJobs.prefix(3)) { job in
                    HStack {
                        Text(job.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(job.status)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 1)
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "fms://job"))
    }
}

struct MapWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let path = entry.mapImagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
                Image(systemName: "map.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading) {
                Text("Active: \(entry.activeVehicles)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
            .padding(8)
        }
        .widgetURL(URL(string: "fms://map"))
    }
}

struct JobWidget: Widget {
    let kind: String = "JobWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JobWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Job Overview")
        .description("View summary of your jobs.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MapWidget: Widget {
    let kind: String = "MapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fleet Map")
        .description("View active fleet status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct FMSWidgets: WidgetBundle {
    var body: some Widget {
        JobWidget()
        MapWidget()
    }
}
