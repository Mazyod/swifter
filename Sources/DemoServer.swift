//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation


public func demoServer(_ publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = shareFilesFromDirectory(publicDir)

    server["/"] = { _ in return .ok(.json(["status": "ok"])) }

    server["/magic"] = { .ok(.html("You asked for " + $0.path)) }

    server["/raw"] = { r in
        return HttpResponse.raw(200, "OK", ["XXX-Custom-Header": "value"], { try $0.write([UInt8]("test".utf8)) })
    }
    
    server["/redirect/permanently"] = { r in
        return .movedPermanently("http://www.google.com")
    }
    
    server["/redirect/temporarily"] = { r in
        return .movedTemporarily("http://www.google.com")
    }

    server["/long"] = { r in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        return .ok(.html(longResponse))
    }
    
    server["/wildcard/*/test/*/:param"] = { r in
        return .ok(.html(r.path))
    }
    
    server["/stream"] = { r in
        return HttpResponse.raw(200, "OK", nil, { w in
            for i in 0...100 {
                try w.write([UInt8]("[chunk \(i)]".utf8))
            }
        })
    }
    
    server["/websocket-echo"] = websocket(text: { (session, text) in
        session.writeText(text)
    }, binary: { (session, binary) in
        session.writeBinary(binary)
    }, pong: { (session, pong) in
        // Got a pong frame
    }, connected: { (session) in
        // New client connected
    }, disconnected: { (session) in
        // Client disconnected
    })
    
    server.notFoundHandler = { r in
        return .movedPermanently("https://github.com/404")
    }
    
    server.middleware.append { r in
        print("Middleware: \(r.address ?? "unknown address") -> \(r.method) -> \(r.path)")
        return nil
    }
    
    return server
}
    
