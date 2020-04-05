//
//  File.swift
//  
//
//  Created by Gregory Higley on 3/31/20.
//

import Foundation

public protocol HTTPConfiguration {
  var permittedStatusCodes: Set<Int> { get }
  var defaultQueue: DispatchQueue { get }
  var defaultHeaders: [String: String] { get }
  subscript<T>(type: T.Type) -> HTTPDecode<T>? { get }
}

open class DefaultHTTPConfiguration: HTTPConfiguration {
  public init() {}
  open var permittedStatusCodes: Set<Int> {
    return Set(200..<206)
  }
  open var defaultQueue: DispatchQueue {
    return .global()
  }
  open var defaultHeaders: [String : String] {
    return [:]
  }
  open subscript<T>(type: T.Type) -> HTTPDecode<T>? {
    if type == String.self {
      return { data in
        guard let string = String(data: data, encoding: .utf8) as? T else {
          throw HTTPError.decoding(nil)
        }
        return string
      }
    }
    return nil
  }
}