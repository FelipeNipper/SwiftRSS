import XCTest
@testable import SwiftRSS

final class SwiftRSSTests: XCTestCase {
    func testParse() async throws {
        let parser = RSSParser()
        let url = URL(string: "https://developer.apple.com/news/rss/news.rss")!
        
        do {
            let items = try await parser.parse(url: url)
            XCTAssertGreaterThan(items.count, 0, "Parsed items should not be empty")
        } catch {
            XCTFail("Parsing failed with error: \(error)")
        }
    }
}
