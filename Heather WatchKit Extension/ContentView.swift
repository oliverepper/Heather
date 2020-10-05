//
//  ContentView.swift
//  Heather WatchKit Extension
//
//  Created by Oliver Epper on 05.10.20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var workoutManager = WorkoutManager()

    var body: some View {
        VStack {
            Text("Elapsed: \(workoutManager.elapsedTime)")
            Text("HR: \(workoutManager.heartRate)")
            Button {
                workoutManager.startWorkout()
            }
            label: {
                Text("Starte Workout")
            }
            Button {
                workoutManager.endWorkout()
            }
            label: {
                Text("Beende Workout")
            }
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
