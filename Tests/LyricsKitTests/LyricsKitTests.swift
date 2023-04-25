import XCTest
import SwiftUI
@testable import LyricsKit

final class LyricsKitTests: XCTestCase {
    var melon = MelonLyrics()
    let idURL = "https://www.melon.com/song/detail.htm?songId=261692"
    let listURL = "https://www.melon.com/search/total/index.htm?q=Don%60t+Look+Back+In+Anger&section="
    
    func testFetch() throws {
        melon.fetch(title: "Don't look back in anger")
        print(melon.lyrics)
    }
}
