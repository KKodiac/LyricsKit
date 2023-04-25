//
//  File.swift
//  
//
//  Created by Sean Hong on 2023/04/14.
//

import Foundation

enum Global {
    case base
    case indexPostfix
    case detailPostfix
    
    var path: String {
        switch self {
        case .base:
            return "https://www.melon.com/"
        case .indexPostfix:
            return "search/total/index.htm?q="
        case .detailPostfix:
            return "song/detail.htm?songId="
        }
    }
    
    var header: String {
        switch self {
        default:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9"
        }

    }
}
