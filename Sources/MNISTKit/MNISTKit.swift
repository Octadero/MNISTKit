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
import Dispatch

public struct MNISTKit {
}

/// Represents MNIST file kind, image or label
public enum MNISTFileKind: Equatable, Hashable {
    public enum Stride: String {
        case train = "train"
        case test = "t10k"
    }
    
    case label(stride: Stride)
    case image(stride: Stride)
    
    /// Equatable for comparing
    public static func ==(lhs: MNISTFileKind, rhs: MNISTFileKind) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    /// Simple, but fast work.
    public var hashValue: Int {
        switch self {
        case .label(stride: .train):
            return 0
        case .label(stride: .test):
            return 1
        case .image(stride: .train):
            return 2
        case .image(stride: .test):
            return 3
        }
    }
    
    public var fileName: String {
        switch self {
        case .label(let stride):
            return stride.rawValue + "-labels-idx1-ubyte"
        case .image(let stride):
            return stride.rawValue + "-images-idx3-ubyte"
        }
    }
    
    public static var fileNames: [String : MNISTFileKind] {
        return [
            MNISTFileKind.image(stride: .test).fileName : MNISTFileKind.image(stride: .test),
            MNISTFileKind.image(stride: .train).fileName : MNISTFileKind.image(stride: .train),
            MNISTFileKind.label(stride: .test).fileName : MNISTFileKind.label(stride: .test),
            MNISTFileKind.label(stride: .train).fileName : MNISTFileKind.label(stride: .train),
        ]
    }
}
/// Represents error in dataset.
public enum MNISTDatasetError: Error {
    case loadDataset(message: String)
}

/// Represents list of MNIST files in dataset.
public class MNISTDataset {
    public private(set) var files = [MNISTFile]()
    
    /// Return files of specified type.
    public func files(`for` kind: MNISTFileKind) -> [MNISTFile] {
        return files.filter { $0.kind == kind }
    }
    
    let loadCallback: (_ error: Error?) -> Void
    public init(callback: @escaping (_ error: Error?) -> Void) {
        loadCallback = callback
        DispatchQueue.global().async {
            do {
                try self.prepare()
            } catch {
                self.loadCallback(error)
            }
        }
    }
    
    internal func prepare() throws {
        let callback = { (urls: [URL]?, error: Error?) in
            if let error = error {
                self.loadCallback(error)
                return
            }
            
            guard let urls = urls else {
                self.loadCallback(MNISTDatasetError.loadDataset(message: "There isn't files."))
                return
            }
            
            do {
                let datasetFiles = try DataSetProvider.unarchive(zippedDataset: urls)
                
                for file in datasetFiles {
                    let fileName = file.lastPathComponent
                    if let kind = MNISTFileKind.fileNames[fileName] {
                        let mnistFile = try MNISTFile.load(fileURL: file, kind: kind)
                        self.files.append(mnistFile)
                    }
                }
                self.loadCallback(nil)
            } catch {
                self.loadCallback(error)
            }
        }
        try DataSetProvider.loadDataset(callback: callback)
    }
}
