//
//  RequestError.swift
//  Similar
//
//  Created by Guillermo Cique Fernández on 23/05/2020.
//

import Foundation

public enum RequestError: Error {
    case noData
    case localError(Error)
    case serverError(code: Int, Data?)
    case decodingError(Error)
}
