# macOS backend rework

#### Pull Requests

- ~~[31769: Fix several MacOS memory management bugs](https://github.com/matplotlib/matplotlib/pull/31769)~~
- [31855: Convert macOS backend to ARC](https://github.com/matplotlib/matplotlib/pull/31855)
- [31977: Use CoreText to find macOS fonts
](https://github.com/matplotlib/matplotlib/pull/31977)

#### Issues fixed in "arc" branch:

- [21788: Apparent memory issue?](https://github.com/matplotlib/matplotlib/issues/21788)
- [29076: Calling start() multiple times on a macos timer doesn't stop the previous timer
](https://github.com/matplotlib/matplotlib/issues/29076)
- [31797: Re-enable Automatic Reference Counting (ARC) for macOS backend.
](https://github.com/matplotlib/matplotlib/issues/31797)
- [31798: macOS backend should always pair +alloc/-init calls
](https://github.com/matplotlib/matplotlib/issues/31798)

#### Issues fixed in "coretext-find-fonts" branch:

- [28249: font finding in OSX produces 200+ lines of warnings](https://github.com/matplotlib/matplotlib/issues/28249).
- [31965: Possibly use CoreText to find fonts for faster performance](https://github.com/matplotlib/matplotlib/issues/31965)

#### Issued fixed in "macosx-staging" branch:

- *None currently*

#### Issued fixed in "macosx-rework" branch:

- [27592: Add dark mode for subplot configuration tool](https://github.com/matplotlib/matplotlib/issues/27592).
- [30419: Event handling with input in callback function](https://github.com/matplotlib/matplotlib/issues/30419)
- [31770: macOS backend lacks standard keyboard shortcuts](https://github.com/matplotlib/matplotlib/issues/31770)
- [31813: macOS backend uses un-prefixed class names](https://github.com/matplotlib/matplotlib/issues/31813)
- [31875: macOS backend likely double-draws renderer output](https://github.com/matplotlib/matplotlib/issues/31875)
- [31899: macOS backend reports wrong button for button_release_event
](https://github.com/matplotlib/matplotlib/issues/31899) (Note: Credit to @mishanilkazreen for his approach in [PR 31937](https://github.com/matplotlib/matplotlib/pull/31937), which is better than my original attempt.)
- [31933: macOS backend UI doesn't update on 'o' and 'p' shortcuts
](https://github.com/matplotlib/matplotlib/issues/31933)
- [31991: macOS backend flickers/flashes due to use of timers](https://github.com/matplotlib/matplotlib/issues/31991)

#### Issues to investigate:

- *None currently*


### Todo

- Start on development notes and architectural overview
- ~~Test full-keyboard accessibility with main figure window~~
- ~~Make `macosx-staging` branch. Start migrating fixes in a way that preserves git history.~~
- Research additional `clang-tidy` and static analyzer settings.

