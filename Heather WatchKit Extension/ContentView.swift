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
            if workoutManager.isRunning != nil {
                Button {
                    workoutManager.isRunning! ? workoutManager.pauseWorkout() : workoutManager.resumeWorkout()
                }
                label: {
                    workoutManager.isRunning! ? Text("Pause") : Text("Fortsetzen")
                }
            } else {
                Button {
                    workoutManager.startWorkout()
                }
                label: {
                    Text("Start")
                }
            }
            Button {
                workoutManager.endWorkout()
            }
            label: {
                Text("Stop")
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
