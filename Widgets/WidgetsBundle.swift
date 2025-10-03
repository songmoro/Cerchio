//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by 송재훈 on 10/3/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        Widgets()
        if #available(iOS 16.2, *) {
            ReadingTimerLiveActivity()
        }
    }
}
