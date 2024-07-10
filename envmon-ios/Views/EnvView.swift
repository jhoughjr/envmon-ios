//
//  EnvView.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 6/28/24.
//

import SwiftUI
import SwiftData
import Charts

struct EnvDTO: Codable {

    var tempC: Float
    var hum: Float
    var co2: Int

    func toModel() -> EnvReading {
        let d = Date()

        return EnvReading(timestamp: d,
                          co2: Int16(self.co2),
                          hum: self.hum,
                          tmp: self.tempC)
    }

    func toJSON() -> Data {
    """
    {
    \"tempC\" : \(self.tempC),
    \"hum\" : \(self.hum),
    \"co2\" : \(self.co2)
    }
    """.data(using: .utf8)!

    }
}

class StreamKeeper {
    var socketStream:SocketStream? = nil
}

struct EnvView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query(sort: [SortDescriptor(\EnvReading.timestamp)])
    var readings: [EnvReading]
        
    let server: Server
    
    @State var connected = false
    @State var graphOn = false
    
    // get this out of view state
    let streamKeeper = StreamKeeper()

    var tableView: some View {
        VStack {
            List {
                ForEach(readings.reversed(), id: \.id) { reading in
                    HStack {
                        Text(verbatim: "\(reading.timestamp.ISO8601Format())")
                        VStack {
                            Text(verbatim: "\(reading.degreesC) °C")
                            Text(verbatim: "\(reading.percentRH) %RH")
                            Text(verbatim: "\(reading.co2ppm) CO2 ppm")
                        }
                    }
                }
            }
        }
    }
    
    var graphsView: some View {
        
        VStack(alignment:.trailing) {
            tempHeadingView
            HStack {
                tempGraphView
                lastTempReadingView
            }
            humHeadingView
            HStack {
                humidtyGraphView
                lastHumidtyReadingView
            }
            co2HeadingView
            
            HStack {
                co2GraphView
                lastCo2ReadingView
            }
        }
    }
    
    var tempHeadingView: some View {
        HStack {
            Image(systemName: "thermometer.medium")
            Text("Temperature")
        }
    }
    
    var tempGraphView: some View {
        Chart(readings,
              id: \EnvReading.id) { reading in
            PointMark(x: .value("GMT", reading.timestamp),
                     y: .value("°C", reading.degreesC))
            .foregroundStyle(.green)
        }
    }
    
    var lastTempReadingView: some View {
        
        VStack {
            if let last = readings.last {
                Text("\(last.degreesC.rounded().formatted()) °C")
                    .font(.largeTitle)
                Text("\(last.timestamp.formatted())")
                    .fontWeight(.ultraLight)
            }
        }
    }
    
    var humHeadingView: some View {
        HStack {
            Image(systemName: "drop.fill")
            Text("Humidity")
        }
    }
    
    var humidtyGraphView: some View {
        Chart(readings,
              id: \EnvReading.id) { reading in
            PointMark(x: .value("GMT", reading.timestamp),
                      y: .value("% RH", reading.percentRH))
            .foregroundStyle(.blue)
        }
    }
    
    var lastHumidtyReadingView: some View {
        VStack {
            if let last = readings.last {
                
                Text("\(last.percentRH.rounded().formatted()) % RH")
                    .font(.largeTitle)
                Text("\(last.timestamp.formatted())")
                    .fontWeight(.ultraLight)
            }
        }
    }
    
    var co2HeadingView: some View {
        HStack {
            Image(systemName: "carbon.dioxide.cloud.fill")
            Text("CO2")
        }
    }
    
    var co2GraphView: some View {
        Chart(readings,
              id: \EnvReading.id) { reading in
            
            PointMark(x: .value("GMT", reading.timestamp),
                     y: .value("CO2 ppm", reading.co2ppm))
            .foregroundStyle(.gray)
            
        }
    }
    
    var lastCo2ReadingView: some View {
        VStack {
            if let last = readings.last {
                Text("\(last.co2ppm) ppm")
                    .font(.largeTitle)
                Text("\(last.timestamp.formatted())")
                    .fontWeight(.ultraLight)
            }
        }
    }
    
    var headingView: some View {
        VStack {
            HStack {
                Image(systemName: "server.rack")
                Text("ws://\(server.address)")
            }
            
            HStack {
                connectionToggleButtonView
                graphOrTableButtonView
            }
        }
    }
    
    var connectionToggleButtonView: some View {
        HStack {
            Image(systemName: "app.connected.to.app.below.fill")
            Button {
                if !connected {
                    Task {
                        startEnvSocket()
                    }
                }else {
                    Task {
                        stopEnvSocket()
                    }
                }
            } label: {
                Text(connected ? "Disconnect" : "Connect")
            }
        }
    }
    
    var graphOrTableButtonView: some View {
        HStack {
            graphOn ? Image(systemName: "tablecells") : Image(systemName: "chart.line.uptrend.xyaxis")
            Button(graphOn ? "Table" : "Graphs") {
                graphOn.toggle()
            }
        }
    }
    
    var body: some View {
        
        VStack {
            headingView
            if !graphOn {
                tableView
            }else {
                ScrollView {
                    graphsView
                }
            }
                
        }
    }
    
    
    private func startEnvSocket() {
    
        Task {
            let url = URL(string: "ws://" + server.address)!
            print("starting stream from \(url)")

            let socketConnection = URLSession.shared.webSocketTask(with: url)
            let stream = SocketStream(task: socketConnection)
            let decoder = JSONDecoder()
            print("setup")
            streamKeeper.socketStream = stream
            connected = true
            
            do {
                for try await message in stream {
                    
                    // handle incoming messages
                    switch message {
                    case .string(let message):
                        // decode
                        let reading = try? decoder.decode(EnvDTO.self,
                                                                from: message.data(using: .utf8)!)
                        // recode
                        if let object = reading?.toModel() {
                            modelContext.insert(object)
                            try modelContext.save()
                        }
                        
                    case .data(let data):
                        // decode
                        let reading  = try? decoder.decode(EnvDTO.self,
                                                                 from: data)
                        // recode
                        if let object = reading?.toModel() {
                            modelContext.insert(object)
                            try modelContext.save()
                        }
                        
                    default: break;
                    }
                    
                }
                
            } catch {
                // handle error
                print(error)
            }
            
            streamKeeper.socketStream = nil
            connected = false

            print("stream ended.")
        }
    }
    
    private func stopEnvSocket() {
        Task {
            print("stopping stream")
            try await self.streamKeeper.socketStream?.cancel()
            streamKeeper.socketStream = nil
            connected = false
        }
    }
    
}
