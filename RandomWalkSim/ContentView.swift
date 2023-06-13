//
//  ContentView.swift
//  RandomWalkSim
//
//  Created by Shrish Deshpande on 12/06/23.
//

import SwiftUI
import Charts
import Foundation

let corners: [Corner] = (0..<8).map { Corner($0) }

struct ContentView: View {
    @State var simulations: Int = 1000
    @State var data: [Int:Int]? = nil
    @State var slope: Double = 0
    @State var computing: Bool = false
    @State var average: Double = 0
    
    var body: some View {
        VStack {
            Text("Cube Walk Simulator")
                .font(.largeTitle)
            
            Form {
                TextField("Simulations", value: $simulations, formatter: NumberFormatter())
                Button("Run simulation") {
                    self.computing = true
                    Task(priority: .high) {
                        await runSimulation()
                    }
                }
            }
            .padding(/*@START_MENU_TOKEN@*/.all, 5.0/*@END_MENU_TOKEN@*/)
            
            if computing {
                ProgressView("Simulating")
            } else if let data = data {
                Text("Average: \(average)")
                Text("Log Slope: \(slope)")
                Divider()
                Text("Actual graph")
                    .font(.title)
                Chart {
                    ForEach(data.sorted(by: >), id: \.key) { key, value in
                        BarMark(
                            x: .value("Steps", key),
                            y: .value("Frequency", value)
                        )
                    }
                }
                .padding(/*@START_MENU_TOKEN@*/.all, 5.0/*@END_MENU_TOKEN@*/)
            }
            
            Spacer()
        }
        .padding(/*@START_MENU_TOKEN@*/.all, 10.0/*@END_MENU_TOKEN@*/)
        .onAppear {
            corners[0].connections = [corners[1], corners[3], corners[4]]
            corners[1].connections = [corners[0], corners[2], corners[5]]
            corners[2].connections = [corners[1], corners[3], corners[6]]
            corners[3].connections = [corners[0], corners[2], corners[7]]
            corners[4].connections = [corners[0], corners[5], corners[7]]
            corners[5].connections = [corners[1], corners[4], corners[6]]
            corners[6].connections = [corners[2], corners[5], corners[7]]
            corners[7].connections = [corners[3], corners[4], corners[6]]
        }
    }
    
    @MainActor func setData(data: [Int:Int], average: Double, slope: Double) {
        withAnimation {
            self.computing = false
            self.data = data
            self.average = average
            self.slope = slope
        }
    }
    
    func runSimulation() async {
        var total: Int = 0
        var data: [Int:Int] = [:]
        var average: Double = 0
        
        for _ in (0..<self.simulations) {
            let steps = walk()
            data[steps, default: 0] += 1
            total += steps
        }
        
        if total != 0 {
            average = Double(total) / Double(simulations)
        }
        
        let slope = calculateSlope(data: data.mapValues { log(Double($0)) })
        
        await setData(data: data, average: average, slope: slope)
    }
    
    func walk() -> Int {
        let start = corners.randomElement()!
        var current = start
        var steps = 0
        
        while true {
            steps += 1
            let nextIndex = Int.random(in: 0..<current.connections.count)
            current = current.connections[nextIndex]
            if current == start {
                return steps
            }
        }
    }
    
    func calculateSlope(data: [Int: Double]) -> Double {
        guard data.count >= 2 else {
            fatalError()
        }
        
        let xValues = Array(data.keys)
        let yValues = Array(data.values)
        
        let sumX = Double(xValues.reduce(0, +))
        let sumY = Double(yValues.reduce(0, +))
        let sumXY = zip(xValues, yValues).map { Double($0) * Double($1) }.reduce(0, +)
        let sumXX = xValues.map { Double($0) * Double($0) }.reduce(0, +)
        
        let n = Double(data.count)
        let numerator = n * sumXY - sumX * sumY
        let denominator = n * sumXX - sumX * sumX
        
        guard denominator != 0 else {
            fatalError()
        }
        
        let slope = numerator / denominator
        return slope
    }
}

class Corner: Equatable {
    var id: Int
    var connections: [Corner] = []
    
    init(_ id: Int) {
        self.id = id
    }
    
    public static func == (lhs: Corner, rhs: Corner) -> Bool {
        return lhs.id == rhs.id
    }
}
