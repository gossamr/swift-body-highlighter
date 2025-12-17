# BodyHighlighter

A Swift Package for rendering interactive body maps in SwiftUI, ported from the React Native body highlighter.

## Features

- Man and woman body models
- Front and back views
- Full, Upper, and Lower body sections
- Zoom and scaling support
- Customizable colors, strokes, and styling
- Intensity-based coloring
- Side-specific highlighting (left/right)
- Group-based targeting (e.g. highlight all "arms")
- Interactive tap handlers
- Hidden and disabled body parts

## Installation

Add this package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/gossamr/swift-body-highlighter.git", from: "0.0.1")
]
```

## Usage

### Basic Example

```swift
import SwiftUI
import BodyHighlighter

struct ContentView: View {
    var body: some View {
        BodyView(
            side: .front,
            gender: .man,
            scale: 1.2
        )
    }
}
```

### Sections and Zooming

You can display specific sections of the body (upper, lower, or full) and apply scaling.

```swift
BodyView(
    gender: .woman,
    section: .upper, // .upper, .lower, or .full
    scale: 1.5,      // Zoom in
    border: .gray    // Optional border color
)
```

### Custom Data and Styling

Highlight specific muscles or entire groups using `BodyPartData`.

```swift
import SwiftUI
import BodyHighlighter

struct ContentView: View {
    let bodyData: [BodyPartData] = [
        // Highlight logic by intensity (uses colors array)
        BodyPartData(
            group: .quads, // Target the entire quads muscle group
            intensity: 1 // Uses first color in 'colors'
        ),
        // Direct color assignment
        BodyPartData(
            slug: .rectus_abdominus, // Target specific muscle
            color: .red
        ),
        // Detailed styling with stroke
        BodyPartData(
            slug: .biceps,
            style: BodyPartStyle(
                fill: .blue,
                stroke: .white,
                strokeWidth: 2
            ),
            side: .left // Only left bicep
        ),
        // Highlight entire muscle groups
        BodyPartData(
            group: .arms,
            color: .green
        )
    ]

    var body: some View {
        BodyView(
            data: bodyData,
            side: .front,
            gender: .man,
            colors: [.yellow, .orange, .red], // Intensity gradient
            onBodyPartPress: { slug, side in
                print("Tapped: \(slug.rawValue), side: \(side?.rawValue ?? "none")")
            }
        )
    }
}
```

### Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | `[BodyPartData]` | `[]` | Array of data to highlight parts. |
| `side` | `BodySide` | `.front` | Front or back view. |
| `gender` | `Gender` | `.woman` | Man or woman model. |
| `section` | `BodySection` | `.full` | Show `.upper`, `.lower`, or `.full` body. |
| `scale` | `CGFloat` | `1.0` | Scale factor for zooming. |
| `border` | `Color?` | `#dfdfdf` | Color of the body outline. Pass `nil` to hide. |
| `colors` | `[Color]` | `[...]` | Array of colors for intensity mapping `(1...n)`. |
| `disabledParts` | `Set<BodyPartSlug>` | `[.hair, ...]` | Parts that are visible but not interactive. |
| `disabledFill` | `Color` | `#ebebe4` | Fill color for disabled parts. |
| `hiddenParts` | `Set<BodyPartSlug>` | `[]` | Parts that are completely hidden. |
| `defaultFill` | `Color` | `#3f3f3f` | Default color for unhighlighted parts. |
| `defaultStroke` | `Color` | `.clear` | Default stroke color. |
| `defaultStrokeWidth` | `CGFloat` | `0` | Default stroke width. |

### Available Body Parts

The package supports granular muscle targeting. See `BodyPartSlug` and `BodyPartGroup` for a complete list, including:

- **Torso**: `rectus_abdominus`, `obliques`, `trapezius`, `upper_back` (group), `lower_back` (group), ...
- **Arms**: `biceps`, `triceps` (group), `deltoids` (group), `forearms` (group), ...
- **Legs**: `quads` (group), `hamstrings` (group), `calves` (group), `adductors` (group), `gluteus_maximus`, ...
- **Other**: `head`, `neck`, `knees`, `hands`, `feet`, ...

You can also target broader groups using `BodyPartData(group: ...)` with groups such as `.arms`, `.chest`, `.upper_back`, `.quads`, etc.

## Architecture

The package is structured as follows:

- **Data/BodyData.swift**: Contains all SVG path data for body parts
- **Models/Models.swift**: Core data models (`BodyPartData`, `BodyPartStyle`, enums)
- **Views/BodyView.swift**: Main SwiftUI view with Canvas rendering logic

## Acknowledgements

Inspired by [react-native-body-highlighter](https://github.com/HichamELBSI/react-native-body-highlighter). All SVG paths used herein are copyright its author.

## License

MIT
