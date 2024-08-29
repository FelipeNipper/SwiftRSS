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
    private var currentAuthor: String = ""
    private var currentCategory: String = ""
    private var currentComments: String = ""
    private var currentEnclosure: String = ""
    private var currentGuid: String = ""
    private var currentPubDate: String = ""
    private var currentSource: String = ""
    private var currentImages: [RSSFeedImage] = []
    private var continuation: CheckedContinuation<[RSSFeedItem], Error>?

    public func parse(url: URL) async throws -> [RSSFeedItem] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                    return
                }

                // Convert data to string for preprocessing
                guard var xmlString = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }

                // Preprocess XML to escape invalid characters
                xmlString = xmlString.replacingOccurrences(of: "&(?!amp;|lt;|gt;|quot;|apos;)", with: "&amp;", options: .regularExpression)

                // Convert back to data
                guard let processedData = xmlString.data(using: .utf8) else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }

                let parser = XMLParser(data: processedData)
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
            currentAuthor = ""
            currentCategory = ""
            currentComments = ""
            currentEnclosure = ""
            currentGuid = ""
            currentPubDate = ""
            currentSource = ""
            currentImages = []
        }

        if currentElement == "enclosure", let url = attributeDict["url"], let type = attributeDict["type"], type.hasPrefix("image") {
            currentEnclosure = url
        }

        if currentElement == "media:thumbnail" {
            let url = attributeDict["url"] ?? ""
            let width = Int(attributeDict["width"] ?? "")
            let height = Int(attributeDict["height"] ?? "")
            //let credit = attributeDict["credit"]

            let image = RSSFeedImage(url: url, width: width, height: height, credit: nil)
            currentImages.append(image)
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
        case "author":
            currentAuthor += string
        case "category":
            currentCategory += string
        case "comments":
            currentComments += string
        case "guid":
            currentGuid += string
        case "pubDate":
            currentPubDate += string
        case "source":
            currentSource += string
        case "image":
            let image = RSSFeedImage(url: string, width: nil, height: nil, credit: nil)
            currentImages.append(image)
        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            let date = formatter.date(from: currentPubDate)

            let item = RSSFeedItem(
                id: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines),
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                author: currentAuthor.trimmingCharacters(in: .whitespacesAndNewlines),
                category: currentCategory.trimmingCharacters(in: .whitespacesAndNewlines),
                comments: currentComments.trimmingCharacters(in: .whitespacesAndNewlines),
                enclosure: currentEnclosure.trimmingCharacters(in: .whitespacesAndNewlines),
                guid: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: date,
                source: currentSource.trimmingCharacters(in: .whitespacesAndNewlines),
                images: currentImages
            )
            items.append(item)
        }
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        continuation?.resume(returning: items)
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error at line \(parser.lineNumber), column \(parser.columnNumber): \(parseError.localizedDescription)")
        continuation?.resume(throwing: parseError)
    }
}
