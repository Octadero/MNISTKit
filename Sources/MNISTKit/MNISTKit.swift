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
public enum Kind {
    public enum Stride: String {
        case train = "train"
        case test = "t10k"
    }
    
    case label(stride: Stride)
    case image(stride: Stride)
    
    public var fileName: String {
        switch self {
        case .label(let stride):
            return stride.rawValue + "-labels-idx1-ubyte"
        case .image(let stride):
            return stride.rawValue + "-images-idx3-ubyte"
        }
    }
    
    public static var fileNames: [String : Kind] {
        return [
            Kind.image(stride: .test).fileName : Kind.image(stride: .test),
            Kind.image(stride: .train).fileName : Kind.image(stride: .train),
            Kind.label(stride: .test).fileName : Kind.label(stride: .test),
            Kind.label(stride: .train).fileName : Kind.label(stride: .train),
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
                    if let kind = Kind.fileNames[fileName] {
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
