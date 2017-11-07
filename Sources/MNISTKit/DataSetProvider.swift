/* Copyright 2017 The Octadero Authors. All Rights Reserved.
 Created by Volodymyr Pavliukevych on 2017.
 
 Licensed under the Apache License 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://github.com/Octadero/MNISTKit/blob/master/LICENSE
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Unarchiver

/// Provider (downloader and unarchiver)
public class DataSetProvider {
    
    public static let trainImagesURL = "http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz"
    public static let trainLabelsURL = "http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"
    public static let testImagesURL = "http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz"
    public static let testLabelsURL = "http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz"
    public static let datasetFolder = "/tmp/mnist/"
    
    public init() {}

    internal static func createDatasetFolder() throws {
        if !FileManager.default.fileExists(atPath: datasetFolder) {
            let datasetFolderURL = URL(fileURLWithPath: datasetFolder)
            try FileManager.default.createDirectory(at: datasetFolderURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// Simple dataset downloader.
    internal static func downloadDataset(at paths: [String], callback: @escaping (_ urlPath: String?, _ filePath: URL?, _ error: Error?) -> Void) throws {
        for path in paths {
            guard let url = URL(string: path) else {
                callback(path, nil, URLError(.badURL))
                continue
            }
            let fileName = url.lastPathComponent
            let filePath = URL(fileURLWithPath: datasetFolder + fileName)
            if FileManager.default.fileExists(atPath: datasetFolder + fileName) {
                callback(path, filePath, nil)
                continue
            }
            
            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            let task = urlSession.downloadTask(with: url, completionHandler: { (localFileURL, response, error) in
                if let error = error {
                    callback(path, nil, error)
                    return
                }
                
                guard let localFileURL = localFileURL else {
                    callback(path, nil, URLError(.badURL))
                    return
                }
                do {
                    try FileManager.default.copyItem(at: localFileURL, to: filePath)
                    callback(path, filePath, nil)
                } catch {
                    callback(path, nil, error)
                }
            })
            task.resume()
        }
    }

    /// MNIST DataSet provider
    ///  - Returns: list of URLs or error
    public static func loadDataset(callback: @escaping (_ dataset: [URL]?, _ error: Error?) -> Void) throws {
        try createDatasetFolder()
        var items = [trainImagesURL, trainLabelsURL, testImagesURL, testLabelsURL]
        var resultPaths = [URL]()
        try downloadDataset(at: items, callback: { (file, dstURL, error) in
            if let error = error {
                callback(nil, error)
                return
            }
            guard let file = file, let dstURL = dstURL else { callback(nil, URLError(.badURL)); return }
            if let index = items.index(of: file) {
                items.remove(at: index)
                resultPaths.append(dstURL)
            }
            
            if items.isEmpty {
                callback(resultPaths, nil)
            }
        })
    }
    
    /// Unarchive all datasets, skipIfExist is true by default.
    /// Set skipIfExist to false if you need.
    public static func unarchive(zippedDataset: [URL], skipIfExist: Bool = true) throws -> [URL] {
        var unzippedURLs = [URL]()
        for file in zippedDataset {
            let unzippedFileURL = file.deletingPathExtension()
            if skipIfExist && FileManager.default.fileExists(atPath: unzippedFileURL.path) {
                debugPrint("skip \(unzippedFileURL)")
                continue
            }
            debugPrint("File \(unzippedFileURL) not found. Unzipping ...")
            let fileData = try Data.init(contentsOf: file)
            let unzippedData = try fileData.gunzipped()
            try unzippedData.write(to: unzippedFileURL)
            unzippedURLs.append(unzippedFileURL)
        }
        return unzippedURLs
    }
}
