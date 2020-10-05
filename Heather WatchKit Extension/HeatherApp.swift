//
//  HeatherApp.swift
//  Heather WatchKit Extension
//
//  Created by Oliver Epper on 05.10.20.
//

import SwiftUI

@main
struct HeatherApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
