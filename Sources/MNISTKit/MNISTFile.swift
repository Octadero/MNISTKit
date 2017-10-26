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

/// Memory helper tool.
extension Data {
    internal func asArray<T>() -> Array<T> {
        let array = self.withUnsafeBytes({ (pointer: UnsafePointer<T>) -> Array<T> in
            return Array(UnsafeBufferPointer<T>(start: pointer, count: self.count / MemoryLayout<T>.size))
        })
        return array
    }
}

/// Represent file
public class MNISTFile: CustomStringConvertible {
    public internal(set) var kind: Kind
    public internal(set) var fileURL: URL
    internal var fileHandle: FileHandle

    /// Fabric
    static func load(fileURL: URL, kind: Kind) throws -> MNISTFile {
        switch kind {
        case .image(_):
            let imageFile = try MNISTImagesFile(fileURL: fileURL, kind: kind)
            return imageFile

        case .label(_):
            let labelsFile = try MNISTLabelsFile(fileURL: fileURL, kind: kind)
            return labelsFile
        }
    }
    
    public  init(fileURL: URL, kind: Kind) throws {
        self.kind = kind
        self.fileURL = fileURL
        print("load: ", fileURL)
        fileHandle = try FileHandle(forReadingFrom: fileURL)
    }
    
    public var description: String {
        return "File: " + fileURL.absoluteString
    }
}

public class MNISTImagesFile: MNISTFile {
    
    /// Image file
    public private(set) var numberOfColumns: UInt32 = 0
    public private(set) var numberOfRows: UInt32 = 0
    public private(set) var numberOfImages: UInt32 = 0
    public private(set) var images = [[Float]]()
    
    /// Label file
    public override init(fileURL: URL, kind: Kind) throws {
        try super.init(fileURL: fileURL, kind: kind)
        readImageFileHeader()
        readImages()
    }
    
    internal func readImageFileHeader() {
        fileHandle.seek(toFileOffset: 0)
        let magicNumberData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        
        /// bigEndian:
        ///     All the integers in the files are stored in the MSB first (high endian) format used by most non-Intel processors.
        ///     Users of Intel processors and other low-endian machines must flip the bytes of the header.
        
        let magicNumber = UInt32(bigEndian: magicNumberData.withUnsafeBytes { $0.pointee })
        
        let numberOfImagesData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        numberOfImages = UInt32(bigEndian: numberOfImagesData.withUnsafeBytes { $0.pointee })
        
        let numberOfRowsData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        numberOfRows = UInt32(bigEndian: numberOfRowsData.withUnsafeBytes { $0.pointee })
        
        let numberOfColumnsData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        numberOfColumns = UInt32(bigEndian: numberOfColumnsData.withUnsafeBytes { $0.pointee })
        
        print("magicNumber: ", magicNumber)
        print("numberOfImages: ", numberOfImages)
        print("numberOfRows: ", numberOfRows)
        print("numberOfColumns: ", numberOfColumns)
    }
    
    internal func readImages() {
        let imageSize = MemoryLayout<UInt8>.size * Int(numberOfRows * numberOfColumns)
        
        for _ in 0..<numberOfImages {
            let imageData = fileHandle.readData(ofLength: imageSize)
            let bytes : [UInt8] = imageData.asArray()
            let floatImage = bytes.map { Float($0) / Float(255.0) }
            images.append(floatImage)
        }
    }
}

public class MNISTLabelsFile: MNISTFile {
    public private(set) var numberOfLabels: UInt32 = 0
    public private(set) var labels = [UInt8]()
    
    /// Label file
    public override init(fileURL: URL, kind: Kind) throws {
        try super.init(fileURL: fileURL, kind: kind)
        readLabelsFileHeader()
        readLabels()
    }
    
    internal func readLabelsFileHeader() {
        fileHandle.seek(toFileOffset: 0)
        let magicNumberData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        
        /// bigEndian:
        ///     All the integers in the files are stored in the MSB first (high endian) format used by most non-Intel processors.
        ///     Users of Intel processors and other low-endian machines must flip the bytes of the header.
        let magicNumber = UInt32(bigEndian: magicNumberData.withUnsafeBytes { $0.pointee })
        
        let numberOfLabelsData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        numberOfLabels = UInt32(bigEndian: numberOfLabelsData.withUnsafeBytes { $0.pointee })
        
        print("magicNumber: ", magicNumber)
        print("numberOfLabels: ", numberOfLabels)
    }
    
    internal func readLabels() {
        let labelsData = fileHandle.readDataToEndOfFile()
        labels = labelsData.asArray()
    }
}
