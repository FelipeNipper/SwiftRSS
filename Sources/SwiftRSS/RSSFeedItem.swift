//
//  File.swift
//  
//
//  Created by Felipe Grosze Nipper de Oliveira on 12/07/24.
//

import Foundation

public struct RSSFeedItem: Identifiable {
    public let id: String
    public let title: String?
    public let link: String?
    public let description: String?
    public let author: String?
    public let category: String?
    public let comments: String?
    public let enclosure: String?
    public let guid: String?
    public let pubDate: Date?
    public let source: String?
    public let images: [RSSFeedImage]
    
}

public struct RSSFeedImage {
    public let url: String
    public let width: Int?
    public let height: Int?
    public let credit: String?
}
