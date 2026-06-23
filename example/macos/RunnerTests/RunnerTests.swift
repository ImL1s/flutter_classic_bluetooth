import Cocoa
import FlutterMacOS
import XCTest

@testable import flutter_classic_bluetooth

// Unit tests for the macOS portion of the plugin. These exercise methods that
// are actually implemented and hardware-independent.
//
// See https://developer.apple.com/documentation/xctest for more information.
class RunnerTests: XCTestCase {

  func testPlatformCapabilitiesAreReported() {
    let plugin = FlutterClassicBluetoothPlugin()
    let call = FlutterMethodCall(methodName: "getPlatformCapabilities", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let caps = result as? [String: Any]
      XCTAssertNotNil(caps)
      XCTAssertNotNil(caps?["platformNote"])
      // macOS does not require MFi certification.
      XCTAssertEqual(caps?["requiresMfiCertification"] as? Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
