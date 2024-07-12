# SwiftRSS

A Swift package for parsing RSS feeds.

## Usage

```swift
import SwiftRSS

let parser = RSSParser()
let url = URL(string: "https://developer.apple.com/news/rss/news.rss")! // Use a valid RSS feed URL

do {
  let items = try await parser.parse(url: url)
} catch {
  print(error)
}
```
