//
//  File.swift
//  
//
//  Created by Felipe Grosze Nipper de Oliveira on 12/07/24.
//

import Foundation

public class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSFeedItem] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDescription: String = ""
    private var currentPubDate: String = ""
    private var continuation: CheckedContinuation<[RSSFeedItem], Error>?

    public func parse(url: URL) async throws -> [RSSFeedItem] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                    return
                }

                let parser = XMLParser(data: data)
                parser.delegate = self
                parser.parse()
            }

            task.resume()
        }
    }

    // MARK: - XMLParserDelegate methods

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if currentElement == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "description":
            currentDescription += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            let date = formatter.date(from: currentPubDate)

            let item = RSSFeedItem(title: currentTitle, link: currentLink, description: currentDescription, pubDate: date)
            items.append(item)
        }
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        continuation?.resume(returning: items)
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        continuation?.resume(throwing: parseError)
    }
}
