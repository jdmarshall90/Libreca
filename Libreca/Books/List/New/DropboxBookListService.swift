//
//  DropboxBookListService.swift
//  Libreca
//
//  Created by Justin Marshall on 5/7/19.
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

import Foundation
import SwiftyDropbox
import ZipArchive

struct DropboxBookListService: BookListServicing {
    typealias BookServiceResponseData = [AuthorDirectory]
    
    func fetchBooks(completion: @escaping (Result<[AuthorDirectory], Error>) -> Void) {
        // TODO: Clean this mess up...
        
        guard let client = DropboxClientsManager.authorizedClient else {
            // TODO: Handle this error
            return
        }
        
        // TODO: Grab from disk if available, only hit network if user pulls to refresh
        client.files.downloadZip(path: "/Calibre Library").response(completionHandler: { responseFiles, error in
            guard error == nil else {
                // TODO: Handle errors
                return
            }
            let zipFileName = responseFiles?.0.metadata.name ?? ""
            
            // swiftlint:disable:next force_unwrap
            let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            let zipURL = documentsPathURL.appendingPathComponent(zipFileName).appendingPathExtension("zip")
            do {
                try responseFiles?.1.write(to: zipURL)
                let unzippedURL = zipURL.deletingPathExtension()
                SSZipArchive.unzipFile(atPath: zipURL.path, toDestination: unzippedURL.path, progressHandler: { someString, fileInfo, anInt, anotherInt in
                    // TODO: Show progress indicator in UI
                    print() // string: "Calibre Library/"; file_info: not needed, filesystem info; anInt: 0,1,2,3, increments @ every call; anotherInt: 2580
                }, completionHandler: { someString, aBool, error in
                    print()
                    guard error == nil else {
                        // TODO: Handle errors
                        return
                    }
                    do {
                        try FileManager.default.removeItem(at: zipURL)
                        
                            // instead of this next line, try: FileManager.default.subpaths(atPath: unzippedURL.path)
                            // in the debugger, that was giving the exact count of OPF files that you were expecting (625)
                            // ▿ Optional<Array<String>>
                            // ▿ some : 3654 elements
                        let authorsURL = try FileManager.default.contentsOfDirectory(at: unzippedURL, includingPropertiesForKeys: nil, options: []).last!
                        let authorURLs = try FileManager.default.contentsOfDirectory(at: authorsURL, includingPropertiesForKeys: nil, options: [])
                        let authorDirectories: [AuthorDirectory] = try authorURLs.compactMap { titleURL in
                            guard titleURL.hasDirectoryPath else {
                                return nil
                            }
                            // TODO: Handle more than just jpegs
                            // expected file types are: image, opf, and ebook file
                            let titleFilesURLs = try FileManager.default.contentsOfDirectory(at: titleURL, includingPropertiesForKeys: nil, options: [])
                            let titleDirectories: [AuthorDirectory.TitleDirectory]
//
//                            switch titleFilesURLs.count {
//                            case 0:
//                                titleDirectories = [] // nothing to see here ... wouldn't expect this to actually happen?
//                            case 1:
//                                titleDirectories = []
//                            case 2:
//                                titleDirectories = []
//                            case 3:
//                                titleDirectories = []
//                            default:
//                                titleDirectories = [] // wouldn't expect this to actually happen either?
//                            }
                            if titleFilesURLs.isEmpty {
                                print()
                            }
                            // this line is just temp, for testing...
                            titleDirectories = titleFilesURLs.map { _ in AuthorDirectory.TitleDirectory(cover: nil, opfMetadataFileData: Data(), ebookFile: nil) }
                            return AuthorDirectory(titleDirectories: titleDirectories)
                        }
                        print("\(authorDirectories.count) author directories. \(authorDirectories.flatMap { $0.titleDirectories }.count) titles.")
                        print()
                    } catch {
                        // TODO: Handle this error
                        print()
                    }
                })
            } catch {
                // TODO: Handle this error
                print()
            }
        }).progress({ progress in
            // TODO: Show progress indicator in UI
            print(progress)
        })
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            let authorDirectories = [
//                AuthorDirectory(
//                    titleDirectories: [
//                        AuthorDirectory.TitleDirectory(cover: nil, opfMetadataFileData: Data())
//                    ]
//                )
//            ]
//            completion(.success(authorDirectories))
//        }
    }
}
