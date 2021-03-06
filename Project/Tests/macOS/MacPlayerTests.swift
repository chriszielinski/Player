//
//  PlayerTests_macOS.swift
//  PlayerTests_macOS
//
//  Created by Chris Zielinski on 6/22/18.
//  Copyright © 2018 Patrick Piemonte. All rights reserved.
//

import XCTest
import Player
import AVKit
@testable import Player_macOS

class TestViewController: NSViewController {

    let player = Player()
    @objc dynamic var didLoop: Bool = false

	convenience init() {
		self.init(nibName: nil, bundle: nil)
	}

	override func loadView() {
		view = NSView()
		view.autoresizingMask = [.height, .width]
		view.setFrameSize(NSSize(width: 400 * (16.0 / 9), height: 400))
	}

	override func viewDidLoad() {
		player.url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "mp4")!
		player.view.autoresizingMask = [.height, .width]
		player.view.frame = view.bounds

        player.playbackDelegate = self
	}
}

extension TestViewController: PlayerPlaybackDelegate {
    func playerPlaybackWillLoop(player: Player) {
        didLoop = true
    }
}

class MacPlayerTests: XCTestCase {

	var testViewController: TestViewController!
	var player: Player {
		return testViewController.player
	}

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		testViewController = TestViewController()
		NSApp.windows.first!.contentViewController = testViewController
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
        testViewController = nil
	}

	func testAutoplayEnabled() {
		player.autoplay = true
		player.add(to: testViewController)

		expectation(for: NSPredicate(format: "isPlaying == true"), evaluatedWith: player, handler: nil)
		waitForExpectations(timeout: 5, handler: nil)
	}

    func testAutoplayDisabled() {
        player.autoplay = false
        player.add(to: testViewController)

        let result = XCTWaiter.wait(for: [
            expectation(for: NSPredicate(format: "isPlaying == true"), evaluatedWith: player, handler: nil)],
                                    timeout: 5)
        XCTAssert(result == .timedOut)
    }

    func testPlaybackLoops() {
        player.playbackLoops = true
        player.add(to: testViewController)

        let result = XCTWaiter.wait(for: [
            expectation(for: NSPredicate(format: "didLoop == true"), evaluatedWith: testViewController, handler: nil)],
                                    timeout: 12)

        XCTAssert(result == .completed, "`playerPlaybackWillLoop(player:)` was not called.")
        XCTAssert(player.currentTime < 0.5, "Player did not loop.")
    }

    func testPlaybackFreezesAtEnd() {
        player.playbackFreezesAtEnd = true
        player.add(to: testViewController)

        let didNotLoop = expectation(for: NSPredicate(format: "didLoop == true"), evaluatedWith: testViewController, handler: nil)
        let result = XCTWaiter.wait(for: [didNotLoop], timeout: 5)

        XCTAssert(result == .timedOut, "`playerPlaybackWillLoop(player:)` was called.")
        XCTAssert(player.currentTime == player.maximumDuration, "Player did not freeze at last frame.")
        XCTAssert(!player.isPlaying, "`isPlaying` is true.")
    }

}
