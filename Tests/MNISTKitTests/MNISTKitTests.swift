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

import XCTest
import MNISTKit

#if os(macOS)
    import CoreGraphics
    
    public class ImageProcessor {
        public static func imageFromARGB32Bitmap(data: Data, width:Int, height:Int) -> CGImage? {
            //vImageConvert_BGRA8888toRGB888
            let bitmapInfo : CGBitmapInfo = .byteOrder32Big
            
            let bitsPerComponent:Int = 8
            let bitsPerPixel:Int = 32
            
            let providerRef = CGDataProvider(data: data as CFData)
            let rgb = CGColorSpaceCreateDeviceRGB()
            
            
            let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: width * 4,
                space: rgb,
                bitmapInfo: bitmapInfo,
                provider: providerRef!,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
            return cgImage
        }
        public static func saveImage(data: Data, width: UInt16, height: UInt16)  {
            self.saveImage(data: data, width: Int(width), height: Int(height))
        }
        
        public static func saveImage(data: Data, width: Int, height: Int)  {
            let cgImage = self.imageFromARGB32Bitmap(data: data,
                                                     width: width,
                                                     height: height)
            
            let url = NSURL(fileURLWithPath: "/tmp/image-\(Date().timeIntervalSince1970)-width-\(width)xheight-\(height).png")
            
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
                return
            }
            CGImageDestinationAddImage(destination, cgImage!, nil)
            
            print(url,CGImageDestinationFinalize(destination))
            
        }
    }
#endif


class MNISTKitTests: XCTestCase {
    var dataset: MNISTDataset?
    
    func testDownloader() {
        let anExpectation = expectation(description: "TestInvalidatingWithExecution \(#function)")
        
        let callback = {(urls: [URL]?, error: Error?) in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            
            if let urls = urls {
                do {
                    let files = try DataSetProvider.unarchive(zippedDataset: urls)
                    print(files)
                    
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
            
            anExpectation.fulfill()
        }
        
        try? DataSetProvider.loadDataset(callback: callback)
        
        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error, "Download timeout.")
        }
    }
    
    func testLoader() {
        let anExpectation = expectation(description: "TestInvalidatingWithExecution \(#function)")
        
        let callback = {(error: Error?) in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            // Create image to test.
            #if os(macOS)
            if let imageFile = self.dataset?.files.first as? MNISTImagesFile {
                print(imageFile.kind)
                let image = imageFile.images[0]
                    var fakeRGBA = [UInt8]()
                    image.forEach({ (pixel) in
                        fakeRGBA.append(255 - UInt8(pixel * 255))
                        fakeRGBA.append(255 - UInt8(pixel * 255))
                        fakeRGBA.append(255 - UInt8(pixel * 255))
                        fakeRGBA.append(1)
                    })
                    
                    let data = Data(bytes: fakeRGBA)
                    ImageProcessor.saveImage(data: data, width: 28, height: 28)
                    
            }
            #endif

            anExpectation.fulfill()
        }
        
        self.dataset = MNISTDataset(callback: callback)
        
        waitForExpectations(timeout: 60) { error in
            XCTAssertNil(error, "Download timeout.")
        }
    }
    
    static var allTests = [("testDownloader", testDownloader), ("testLoader", testLoader)]
}
