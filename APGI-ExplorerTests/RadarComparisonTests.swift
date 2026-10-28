import SwiftUI
import XCTest
@testable import APGI_Explorer

@MainActor
final class RadarComparisonTests: XCTestCase {
  func testZeroAndFullScoresShareTheGridCenterAndRadius() {
    let geometry = RadarComparisonGeometry(size: CGSize(width: 860, height: 344))
    for axis in 0..<4 {
      XCTAssertEqual(geometry.point(axis: axis, score: 0), geometry.center)
      let endpoint = geometry.point(axis: axis, score: 100)
      XCTAssertEqual(hypot(endpoint.x - geometry.center.x, endpoint.y - geometry.center.y), geometry.radius, accuracy: 0.001)
    }
  }

  func testMarksAndLabelsFitInsideNarrowAndWideCanvases() {
    for width in [CGFloat(480), 660, 860, 1160] {
      let geometry = RadarComparisonGeometry(size: CGSize(width: width, height: 344))
      let canvas = CGRect(origin: .zero, size: geometry.size)
      for axis in 0..<4 {
        XCTAssertTrue(canvas.contains(geometry.labelFrame(axis: axis)))
        for score in [-20.0, 0, 50, 100, 200] {
          XCTAssertTrue(canvas.contains(geometry.point(axis: axis, score: score)))
        }
      }
    }
  }

  func testRenderComparisonAtTwoWidths() throws {
    let first = QuizProfile(id: UUID(), name: "Dima", dateCreated: Date(), dateModified: Date(),
                            results: ["epsilon": 15, "precision": 10, "threshold": 12, "somatic": 14])
    let second = QuizProfile(id: UUID(), name: "Mike", dateCreated: Date(), dateModified: Date(),
                             results: ["epsilon": 40, "precision": 55, "threshold": 50, "somatic": 60])
    for width in [CGFloat(560), 900] {
      let renderer = ImageRenderer(content:
        RadarComparisonChart(profile1: first, profile2: second)
          .frame(width: width, height: 420)
          .background(Color.white)
          .environment(\.colorScheme, .light))
      let image = try XCTUnwrap(renderer.nsImage)
      let tiff = try XCTUnwrap(image.tiffRepresentation)
      let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
      let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("apgi-radar-preview-\(Int(width)).png")
      try png.write(to: url)
      NSLog("Radar layout preview: %@", url.path)
      XCTAssertEqual(image.size.width, width, accuracy: 1)
      XCTAssertEqual(image.size.height, 420, accuracy: 1)
    }
  }
}
