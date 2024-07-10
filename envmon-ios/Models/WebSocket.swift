//
//  EnvReadingWebSocket.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 7/7/24.
//

import Foundation
import SwiftUI
import SwiftData

typealias WebSocketStream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>

class SocketStream: AsyncSequence {
    
    typealias AsyncIterator = WebSocketStream.Iterator
    typealias Element = URLSessionWebSocketTask.Message
    
    private var continuation: WebSocketStream.Continuation?
    private let task: URLSessionWebSocketTask
    
    private lazy var stream: WebSocketStream = {
        return WebSocketStream { continuation in
            self.continuation = continuation
            
            Task {
                var isAlive = true
                
                while isAlive && task.closeCode == .invalid {
                    do {
                        let value = try await task.receive()
                        continuation.yield(value)
                    } catch {
                        continuation.finish(throwing: error)
                        isAlive = false
                    }
                }
            }
        }
    }()
    
    init(task: URLSessionWebSocketTask) {
        self.task = task
        task.resume()
    }
    
    deinit {
        continuation?.finish()
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        return stream.makeAsyncIterator()
    }
    
    func cancel() async throws {
        print("stream task cancelling.")
        task.cancel(with: .goingAway, reason: nil)
        continuation?.finish()
    }
}

public extension URLSessionWebSocketTask {
    internal var stream: WebSocketStream {
        return WebSocketStream { continuation in
            Task {
                var isAlive = true
                
                while isAlive && closeCode == .invalid {
                    do {
                        let value = try await receive()
                        continuation.yield(value)
                    } catch {
                        continuation.finish(throwing: error)
                        isAlive = false
                    }
                }
            }
        }
    }
}


//
//class EnvReadingWebsocket: ObservableObject {
//    var modelContext: ModelContext? = nil
//

//   
//    var errors =  [String]()
//    var address: String = ""
//    
//    @Published var connected: Bool = false {
//        didSet {
//            print("\(connected)")
//        }
//    }
//    
//    private var webSocketTask: URLSessionWebSocketTask?
//    
//    init(context: ModelContext?) {
//        self.modelContext = context
//    }
//    
//    func open(_ addr: String) async throws {
//        print("opening \(addr)")
//        address = addr
//        guard let url = URL(string: "ws://" + address) else { return }
//        let request = URLRequest(url: url)
//        webSocketTask = URLSession.shared.webSocketTask(with: request)
////        setReceiveMessageHandlers()
//        
//        let message = try await webSocketTask?.receive()
//
//        print("\(message)")
//        connected = true
//    }
//    
//    func setReceiveHandler() async {
//        var isActive = true
//        
//        while isActive && webSocketTask?.closeCode == .invalid {
//            do {
//                let message = try await webSocketTask?.receive()
//                
//                switch message {
//                case let .string(string):
//                    print(string)
//                case let .data(data):
//                    print(data)
//                @unknown default:
//                    print("unkown message received")
//                }
//            } catch {
//                print(error)
//                isActive = false
//            }
//        }
//    }
//    
//    func close() {
//        print("closing \(address)")
//        webSocketTask?.cancel(with: .normalClosure,
//                              reason: "User closure".data(using: .utf8))
//       
//        errors.removeAll()
//        
//        print("buffers cleared")
//        connected = false
//    }
//    
//    private func setReceiveMessageHandlers() {
//        
//        webSocketTask?.receive { result in
//            switch result {
//            case .failure(let error):
//                print(error.localizedDescription)
//                DispatchQueue.main.async {
//                    self.connected = false
//                }
//            case .success(let message):
//                switch message {
//                case .string(let text):
//                    print("TEXT:\n\(text)")
//                    do {
//                        let decoded = try JSONDecoder().decode(EnvReadingWebsocket.EnvDTO.self, from: text.data(using: .utf8)!)
//                         let model = decoded.toModel()
//                            self.modelContext?.insert(model)
//                            try? self.modelContext?.save()
//                            print("saved")
//                        
//                    }
//                    catch {
//                        print("\(error)")
//
//                    }
//                    
//                case .data(let data):
//                    // Handle binary data
//                    print("BIN:\n\(String(data: data, encoding: .utf8))")
//                    let decoded = try? JSONDecoder().decode(EnvReadingWebsocket.EnvDTO.self, from: data)
//                    if let model = decoded?.toModel() {
//                        self.modelContext?.insert(model)
//                        try? self.modelContext?.save()
//                    }
//                @unknown default:
//                    break
//                }
//                print("resuming \(self.webSocketTask)")
//                self.webSocketTask?.resume()
//            }
//        }
//    }
//    
//    func sendMessage(_ message: String) {
//        guard let data = message.data(using: .utf8) else { return }
//        webSocketTask?.send(.string(message)) { error in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }
//    }
//    
//}
