// WebSocketsServer.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Core
import HTTP

public extension Response {
	public func getHeader(header: String) -> String? {
		for (key, value) in headers where key.lowercaseString == header.lowercaseString {
			return value
		}
		return nil
	}

	public var isWebSocket: Bool {
		// TODO: Fail if extensions in the response that weren't in the request
		if let connection = getHeader("connection"), upgrade = getHeader("upgrade"), _ = getHeader("sec-websocket-accept")
			where statusCode == 101 && connection.lowercaseString == "upgrade" && upgrade.lowercaseString == "websocket" {
				return true
		} else {
			return false
		}
	}
}

public typealias ResponsePair = (Response, StreamType)
public class WebSocketClient {
	private var sockets: [WebSocket] = []
	private let websocketHandler: WebSocket -> Void
	public let wsKey = Base64.encode(Data(bytes: [0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5])).string!

	public init(websocketHandler: WebSocket -> Void) {
		self.websocketHandler =  websocketHandler
	}

	public func handleResponse(responsePair: ResponsePair) {
		let (response, stream) = responsePair
		guard response.isWebSocket else { return }
		guard let acceptKey = response.getHeader("sec-websocket-accept") where acceptKey == Base64.encode(Data(uBytes: SHA1.bytes(wsKey + WebSocket.KeyGuid))).string else { return }

		do {
			let socket = WebSocket(stream: stream, mode: .Client)
			self.sockets.append(socket)
			self.websocketHandler(socket)
		} catch {
			print("upgrade error: \(error)")
		}
	}
}
