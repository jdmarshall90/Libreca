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
import FirebaseAnalytics

protocol ResponseStatusReporting {
    associatedtype ResponseType
    
    var reportedEventPrefix: String { get }
    
    func reportStatus(of response: DataResponse<ResponseType>)
}

extension ResponseStatusReporting {
    func reportStatus(of response: DataResponse<ResponseType>) {
        switch response.result {
        case .success:
            let elapsed = response.timeline.totalDuration
            let toNearest = 0.01
            let roundedElapsed = round(elapsed / toNearest) * toNearest
            Analytics.logEvent("\(reportedEventPrefix)_success", parameters: ["time_interval": roundedElapsed])
        case .failure(let error):
            let parameters: [String: Any]
            switch error as? AFError {
            case .invalidURL?:
                parameters = ["reason": "invalidURL"]
            case .parameterEncodingFailed(let reason)?:
                switch reason {
                case .missingURL:
                    parameters = ["reason": "missingURL"]
                case .jsonEncodingFailed:
                    parameters = ["reason": "jsonEncodingFailed"]
                case .propertyListEncodingFailed:
                    parameters = ["reason": "propertyListEncodingFailed"]
                }
            case .multipartEncodingFailed?:
                // this could have many reasons, per the associated type,
                // but multipart encoding isn't used for this service
                parameters = ["reason": "multipartEncodingFailed"]
            case .responseValidationFailed(let reason)?:
                switch reason {
                case .dataFileNil:
                    parameters = ["reason": "dataFileNil"]
                case .dataFileReadFailed:
                    parameters = ["reason": "dataFileReadFailed"]
                case .missingContentType:
                    parameters = ["reason": "missingContentType"]
                case .unacceptableContentType(_, let responseContentType):
                    parameters = ["reason": "unacceptableContentType:\(responseContentType)"]
                case .unacceptableStatusCode(let code):
                    parameters = ["reason": "unacceptableStatusCode:\(code)"]
                }
            case .responseSerializationFailed(let reason)?:
                switch reason {
                case .inputDataNil:
                    parameters = ["reason": "inputDataNil"]
                case .inputDataNilOrZeroLength:
                    parameters = ["reason": "inputDataNilOrZeroLength"]
                case .inputFileNil:
                    parameters = ["reason": "inputFileNil"]
                case .inputFileReadFailed:
                    parameters = ["reason": "inputFileReadFailed"]
                case .stringSerializationFailed(let encoding):
                    parameters = ["reason": "stringSerializationFailed:\(encoding.description)"]
                case .jsonSerializationFailed:
                    parameters = ["reason": "jsonSerializationFailed"]
                case .propertyListSerializationFailed:
                    parameters = ["reason": "propertyListSerializationFailed"]
                }
            case .none:
                parameters = ["reason": "\(type(of: error))"]
            }
            Analytics.logEvent("\(reportedEventPrefix)_fail", parameters: parameters)
        }
    }
}
