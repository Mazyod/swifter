//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

// swiftlint:disable function_body_length
public func demoServer(_ publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = shareFilesFromDirectory(publicDir)

    server["/"] = { _ in return .ok(.json(["status": "ok"])) }

    server["/magic"] = { .ok(.html("You asked for " + $0.path)) }

    server["/raw"] = { _ in
        return HttpResponse.raw(200, "OK", ["XXX-Custom-Header": "value"], { try $0.write([UInt8]("test".utf8)) })
    }
    
    server["/redirect/permanently"] = { _ in
        return .movedPermanently("http://www.google.com")
    }
    
    server["/redirect/temporarily"] = { _ in
        return .movedTemporarily("http://www.google.com")
    }

    server["/long"] = { _ in
        var longResponse = ""
        for index in 0..<1000 { longResponse += "(\(index)),->" }
        return .ok(.html(longResponse))
    }
    
    server["/wildcard/*/test/*/:param"] = { request in
        return .ok(.html(request.path))
    }
    
    server["/stream"] = { _ in
        return HttpResponse.raw(200, "OK", nil, { writer in
            for index in 0...100 {
                try writer.write([UInt8]("[chunk \(index)]".utf8))
            }
        })
    }
    
    server["/websocket-echo"] = websocket(text: { (session, text) in
        session.writeText(text)
    }, binary: { (session, binary) in
        session.writeBinary(binary)
    }, pong: { (_, _) in
        // Got a pong frame
    }, connected: { _ in
        // New client connected
    }, disconnected: { _ in
        // Client disconnected
    })
    
    server.notFoundHandler = { _ in
        return .movedPermanently("https://github.com/404")
    }
    
    server.middleware.append { request in
        print("Middleware: \(request.address ?? "unknown address") -> \(request.method) -> \(request.path)")
        return nil
    }
    
    return server
}
    
