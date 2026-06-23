import Flutter
import UIKit
import XCTest

@testable import flutter_classic_bluetooth

// Unit tests for the iOS portion of the plugin. These exercise methods that are
// actually implemented and hardware-independent.
//
// See https://developer.apple.com/documentation/xctest for more information.
class RunnerTests: XCTestCase {

  func testIsSupportedReturnsTrue() {
    let plugin = FlutterClassicBluetoothPlugin()
    let call = FlutterMethodCall(methodName: "isSupported", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as? Bool, true)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPlatformCapabilitiesRequireMfi() {
    let plugin = FlutterClassicBluetoothPlugin()
    let call = FlutterMethodCall(methodName: "getPlatformCapabilities", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let caps = result as? [String: Any]
      XCTAssertNotNil(caps)
      // iOS only supports MFi accessories — discovery and server are unavailable.
      XCTAssertEqual(caps?["requiresMfiCertification"] as? Bool, true)
      XCTAssertEqual(caps?["canDiscoverDevices"] as? Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
