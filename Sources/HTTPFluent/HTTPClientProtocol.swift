//
//  HTTPClientProtocol.swift
//  HTTPFluent
//
//  Created by Gregory Higley on 2020-05-08.
//  Copyright © 2020 Prosumma. All rights reserved.
//

import Combine
import Foundation

/**
 Adds the ability to publish a `URLRequest` built using
 `URLRequestBuilderProtocol`.
 */
public protocol HTTPClientProtocol: URLRequestBuilderProtocol {
  /**
   Returns a publisher that wraps a URL session data task for a given URL request.

   The publisher publishes Data when the task completes, or terminates if the task fails with an error.

   - returns: A publisher that wraps data for the URL request.
   */
  var publisher: AnyPublisher<Data, HTTPError> { get }
  func receive(on queue: DispatchQueue, callback: @escaping (Result<Data, HTTPError>) -> Void)
}

//swiftlint:disable function_default_parameter_at_end
public extension HTTPClientProtocol {
  /// Returns a publisher that wraps a URL session data task for a given URL request and decode the response with the specified decoder.
  ///
  /// The publisher publishes Reponse when the task completes, or terminates if the task fails with an error.
  /// - Parameters:
  ///   - type: The type to decode
  ///   - decoder: The json decoder to decode data to Response
  /// - Returns: A publisher that wraps a data task for the URL request.
  func publisher<Response, Decoder>(
    decoding type: Response.Type = Response.self,
    decoder: Decoder
  ) -> AnyPublisher<Response, HTTPError> where Response: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
    publisher.decode(type: type, decoder: decoder).mapErrorIfNeeded(HTTPError.decoding).eraseToAnyPublisher()
  }

  /// Returns a publisher that wraps a URL session data task for a given URL request and decode the response with JSONDecoder.
  ///
  /// - Parameter type: The type to decode
  /// - Returns: A publisher that wraps a data task for the URL request.
  func publisher<Response: Decodable>(
    decoding type: Response.Type = Response.self
  ) -> AnyPublisher<Response, HTTPError> {
    accept(.json).publisher(decoding: type, decoder: JSONDecoder())
  }

  func stringPublisher(encoding: String.Encoding = .utf8) -> AnyPublisher<String, HTTPError> {
    return publisher.tryMap { data in
      guard let string = String(data: data, encoding: encoding) else {
        throw HTTPError.decoding(nil)
      }
      return string
    }
    .mapToHttpError
    .eraseToAnyPublisher()
  }
  
  func receive(on queue: DispatchQueue = DispatchQueue.global(), callback: @escaping (Result<Data, HTTPError>) -> Void) {
    receive(on: queue, callback: callback)
  }
  
  func receive<Response, Decoder>(decoding type: Response.Type = Response.self, decoder: Decoder, on queue: DispatchQueue = DispatchQueue.global(), callback: @escaping (Result<Response, HTTPError>) -> Void) where Response: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
    let fluent = decoder is JSONDecoder ? accept(.json) : self
    fluent.receive(on: queue) { result in
      callback(result.flatMap { data in
        do {
          return try .success(decoder.decode(type, from: data))
        } catch {
          return .failure(.decoding(error))
        }
      })
    }
  }

  func receive<Response>(json type: Response.Type = Response.self, decoder: Decoder, on queue: DispatchQueue = DispatchQueue.global(), callback: @escaping (Result<Response, HTTPError>) -> Void) where Response: Decodable {
    receive(decoding: type, decoder: JSONDecoder(), on: queue, callback: callback)
  }
  
  func receiveString(encoding: String.Encoding = .utf8, on queue: DispatchQueue = DispatchQueue.global(), callback: @escaping (Result<String, HTTPError>) -> Void) {
    receive(on: queue) { result in
      callback(result.flatMap { data in
        if let string = String(data: data, encoding: encoding) {
          return .success(string)
        } else {
          return .failure(.decoding(nil))
        }
      })
    }
  }
}