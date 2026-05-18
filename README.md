# Markdown Preview

Native macOS Quick Look preview extension for Markdown files.

It renders `.md` files as styled HTML in Finder's Quick Look panel instead of showing raw plain text.

## Features

- Finder Quick Look preview for Markdown files.
- Polished light and dark mode styling.
- Local rendering only: no network calls and no external runtime services.
- Supports headings, emphasis, links, inline code, fenced code blocks, block quotes, lists, thematic breaks, and tables.
- Handles common Markdown UTIs, including TeXShop's `com.unknown.md`, without changing your editor association.

## Requirements

- macOS 14 or later.
- Xcode or Xcode command line tools with `xcodebuild`.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
```

## Install

```sh
git clone https://github.com/PierreVannier/markdown-preview-quicklook.git
cd markdown-preview-quicklook
./scripts/install.sh
```

The installer builds the app, installs it to:

```text
~/Applications/Markdown Preview.app
```

It also registers the Quick Look extension, resets Quick Look caches, and sets Markdown Preview as the Finder/Quick Look viewer for Markdown content types. Editor handlers are left intact.

## Use

In Finder:

- Select a `.md` file and press Space.
- Or enable the preview pane with `View > Show Preview`.

## Uninstall

```sh
./scripts/uninstall.sh
```

## Troubleshooting

If Finder still shows a plain-text preview after installing:

```sh
qlmanage -r
qlmanage -r cache
killall Finder
```

Then select the Markdown file again and press Space.

If TeXShop takes over Markdown previews, run the installer again. TeXShop registers `.md` as `com.unknown.md`; the installer explicitly sets Markdown Preview as the Viewer handler for that type while leaving TeXShop as the Editor.

## Development

Generate the Xcode project:

```sh
xcodegen generate
```

Build:

```sh
xcodebuild \
  -project MarkdownPreview.xcodeproj \
  -scheme "Markdown Preview" \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  SDK_STAT_CACHE_ENABLE=NO \
  build
```

Install locally:

```sh
./scripts/install.sh
```

## License

MIT
