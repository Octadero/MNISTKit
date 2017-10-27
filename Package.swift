// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

import PackageDescription

let package = Package(
    name: "MNISTKit",
    products: [
        .library(name: "MNISTKit", targets: ["MNISTKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/Octadero/Unarchiver.git", from: "0.0.5")
    ],
    targets: [
        .target(name: "MNISTKit", dependencies: ["Unarchiver"]),
        .testTarget(name: "MNISTKitTests", dependencies: ["MNISTKit"])
    ]
)
