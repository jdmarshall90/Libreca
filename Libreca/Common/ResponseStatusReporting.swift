//
//  ResponseStatusReporting.swift
//  Libreca
//
//  Created by Justin Marshall on 4/11/19.
//  
//  Libreca is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Libreca is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Libreca.  If not, see <https://www.gnu.org/licenses/>.
//
//  Copyright © 2019 Justin Marshall
//  This file is part of project: Libreca
//

import Alamofire

protocol ResponseStatusReporting {
    associatedtype ResponseType
    
    var reportedEventPrefix: String { get }
    
    func reportStatus(of response: DataResponse<ResponseType>)
}

extension ResponseStatusReporting {
    func reportStatus(of response: DataResponse<ResponseType>) {
        switch response.result {
        case .success:
            reportSuccess(of: response)
        case .failure(let error):
            reportFailure(of: error)
        }
    }
    
    private func reportSuccess(of response: DataResponse<ResponseType>) {
        let elapsed = response.timeline.totalDuration
        let toNearest = 0.01
        let roundedElapsed = round(elapsed / toNearest) * toNearest
        print(roundedElapsed)
    }
    
    private func reportFailure(of error: Error) {
        let parameters: [String: Any]
        switch error as? AFError {
        case .invalidURL?:
            parameters = ["reason": "invalidURL"]
        case .parameterEncodingFailed(let reason)?:
            parameters = generateParameters(for: reason)
        case .multipartEncodingFailed?:
            // this could have many reasons, per the associated type,
            // but multipart encoding isn't used for this service
            parameters = ["reason": "multipartEncodingFailed"]
        case .responseValidationFailed(let reason)?:
            parameters = generateParameters(for: reason)
        case .responseSerializationFailed(let reason)?:
            parameters = generateParameters(for: reason)
        case .none:
            let error = error as NSError
            parameters = ["reason": "\(error.code)"]
        }
        print(parameters)
    }
    
    private func generateParameters(for reason: AFError.ParameterEncodingFailureReason) -> [String: Any] {
        switch reason {
        case .missingURL:
            return ["reason": "missingURL"]
        case .jsonEncodingFailed:
            return ["reason": "jsonEncodingFailed"]
        case .propertyListEncodingFailed:
            return ["reason": "propertyListEncodingFailed"]
        }
    }
    
    private func generateParameters(for reason: AFError.ResponseValidationFailureReason) -> [String: Any] {
        switch reason {
        case .dataFileNil:
            return ["reason": "dataFileNil"]
        case .dataFileReadFailed:
            return ["reason": "dataFileReadFailed"]
        case .missingContentType:
            return ["reason": "missingContentType"]
        case .unacceptableContentType(_, let responseContentType):
            return ["reason": "unacceptableContentType:\(responseContentType)"]
        case .unacceptableStatusCode(let code):
            return ["reason": "unacceptableStatusCode:\(code)"]
        }
    }
    
    private func generateParameters(for reason: AFError.ResponseSerializationFailureReason) -> [String: Any] {
        switch reason {
        case .inputDataNil:
            return ["reason": "inputDataNil"]
        case .inputDataNilOrZeroLength:
            return ["reason": "inputDataNilOrZeroLength"]
        case .inputFileNil:
            return ["reason": "inputFileNil"]
        case .inputFileReadFailed:
            return ["reason": "inputFileReadFailed"]
        case .stringSerializationFailed(let encoding):
            return ["reason": "stringSerializationFailed:\(encoding.description)"]
        case .jsonSerializationFailed:
            return ["reason": "jsonSerializationFailed"]
        case .propertyListSerializationFailed:
            return ["reason": "propertyListSerializationFailed"]
        }
    }
}
