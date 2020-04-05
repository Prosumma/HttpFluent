//
//  File.swift
//  
//
//  Created by Gregory Higley on 4/4/20.
//

#if canImport(Combine)
import Combine
#endif
import Foundation

public extension HTTP {
  private func post(encode: @escaping HTTPEncode) -> Builder {
    body(encode: encode).method(.post)
  }
  
  func post(data: Data) -> Builder {
    post { data }
  }
  
  #if canImport(Combine)
  @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  func post<Body: Encodable, Encoder: TopLevelEncoder>(body: Body, encoder: Encoder) -> Builder where Encoder.Output == Data {
    post { try encoder.encode(body) }
  }
  #endif
  
  func post<JSON: Encodable>(json: JSON, encoder: JSONEncoder = JSONEncoder()) -> Builder {
    content(type: .json).post { try encoder.encode(json) }
  }
  
  func post(form: FormData) -> Builder {
    content(type: form.contentType).post(data: form.encode())
  }
}