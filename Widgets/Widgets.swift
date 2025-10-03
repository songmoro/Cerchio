//
//  Widgets.swift
//  Widgets
//
//  Created by 송재훈 on 10/3/25.
//

import WidgetKit
import SwiftUI

// Empty placeholder widget - not used in this project
struct Widgets: Widget {
    let kind: String = "Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmptyProvider()) { entry in
            Text("Not used")
        }
        .supportedFamilies([])
    }
}

struct EmptyEntry: TimelineEntry {
    let date: Date
}

struct EmptyProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmptyEntry {
        EmptyEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EmptyEntry) -> Void) {
        completion(EmptyEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EmptyEntry>) -> Void) {
        completion(Timeline(entries: [EmptyEntry(date: Date())], policy: .never))
    }
}
