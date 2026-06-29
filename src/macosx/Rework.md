# macOS backend rework

#### Pull Requests

- ~~[31769: Fix several MacOS memory management bugs](https://github.com/matplotlib/matplotlib/pull/31769)~~
- [31855: Convert macOS backend to ARC](https://github.com/matplotlib/matplotlib/pull/31855)

#### Issues fixed in "arc" branch:

- [21788: Apparent memory issue?](https://github.com/matplotlib/matplotlib/issues/21788)
- [29076: Calling start() multiple times on a macos timer doesn't stop the previous timer
](https://github.com/matplotlib/matplotlib/issues/29076)
- [31797: Re-enable Automatic Reference Counting (ARC) for macOS backend.
](https://github.com/matplotlib/matplotlib/issues/31797)
- [31798: macOS backend should always pair +alloc/-init calls
](https://github.com/matplotlib/matplotlib/issues/31798)

#### Issued fixed in "macosx-staging" branch:

- *None currently*

#### Issued fixed in "macosx-rework" branch:

- [31770: macOS backend lacks standard keyboard shortcuts](https://github.com/matplotlib/matplotlib/issues/31770)
- [31813: macOS backend uses un-prefixed class names](https://github.com/matplotlib/matplotlib/issues/31813)
- [31875: macOS backend likely double-draws renderer output](https://github.com/matplotlib/matplotlib/issues/31875) This includes reworking `draw_idle()`/`draw()` to use layer-hosted views. The end result is no double-draws, no unnecessary color space conversions, and no flicker when updating a figure.
- [31899: macOS backend reports wrong button for button_release_event
](https://github.com/matplotlib/matplotlib/issues/31899) (Note: Credit to @mishanilkazreen for his approach in [PR 31937](https://github.com/matplotlib/matplotlib/pull/31937), which is better than my original attempt.)
- [31933: macOS backend UI doesn't update on 'o' and 'p' shortcuts
](https://github.com/matplotlib/matplotlib/issues/31933)

#### Issues to investigate:

- [27592: Add dark mode for subplot configuration tool](https://github.com/matplotlib/matplotlib/issues/27592). Will involve making a native version of the subplot tool, which I'm already working on for keyboard accessibility.
- [28249: font finding in OSX produces 200+ lines of warnings](https://github.com/matplotlib/matplotlib/issues/28249). Unlikely to be fixable but I need to install Catalina for testing anyway.
- [30419: Event handling with input in callback function](https://github.com/matplotlib/matplotlib/issues/30419)


### Todo

- Start on development notes and architectural overview
- Test full-keyboard accessibility with main figure window
- Make `macosx-staging` branch. Start migrating fixes in a way that preserves git history.
- Research additional `clang-tidy` and static analyzer settings.

