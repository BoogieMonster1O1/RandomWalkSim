//
//  RandomWalkSimApp.swift
//  RandomWalkSim
//
//  Created by Shrish Deshpande on 12/06/23.
//

import SwiftUI
import SwiftData

@main
struct RandomWalkSimApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
