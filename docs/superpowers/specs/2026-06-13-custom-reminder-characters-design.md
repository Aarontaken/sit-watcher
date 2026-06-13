# Custom Reminder Characters Design

## Context

SitWatcher currently ships built-in reminder characters through the app asset catalog. `RestReminderFigureStyle` names each built-in style, supplies asset names and frame timing, and `RestReminderCharacterFigure` loops those frames in the floating reminder (`126x126`) and full-screen reminder (`206x206`). Settings persist only the selected built-in enum value.

The new feature adds user-managed custom reminder characters. Users can add multiple custom characters, delete them, edit them after import, and choose one alongside the built-in characters.

## Goals

- Support multiple custom reminder characters.
- Accept still images, animated images, and videos through one import flow.
- Render all custom characters through the same image-frame playback path.
- For videos, default to the first 3 seconds while allowing the user to adjust the start time.
- Handle mismatched aspect ratios without stretching by using a square stage, fill crop, and user-adjustable focus and zoom.
- Keep reminder display lightweight and reliable by doing all media decoding and frame generation during import or edit.

## Non-Goals

- No intelligent background removal in the first version.
- No audio playback for video imports.
- No arbitrary video trimming with separate start and end points.
- No playback of original GIF, APNG, WebP, or video files inside the reminder view.
- No per-surface character selection; floating and full-screen reminders use the same selected character.

## Recommended Approach

Use an internal frame package for every custom character.

- Still image: generate one `512x512` frame.
- Animated image: sample the animation into at most 45 `512x512` frames.
- Video: sample up to 3 seconds from the chosen start time into at most 45 `512x512` frames.

This keeps the reminder view simple. It only needs to display a frame sequence with a known frame interval, whether the original source was a PNG, GIF, APNG, WebP, or video.

## Data Model

Add a new selection model:

```swift
enum ReminderCharacterSelection: Equatable, Codable {
    case builtIn(RestReminderFigureStyle)
    case custom(UUID)
}
```

`Settings` persists this selection instead of only `restReminderFigureStyle`. Existing installs migrate their current `restReminderFigureStyle` into `.builtIn(style)`.

Add a custom character model:

```swift
struct CustomReminderCharacter: Identifiable, Codable {
    let id: UUID
    var name: String
    var sourceKind: SourceKind
    var createdAt: Date
    var updatedAt: Date
    var frameCount: Int
    var frameInterval: TimeInterval
    var crop: CharacterCrop
    var videoStartTime: TimeInterval?
}

enum SourceKind: String, Codable {
    case stillImage
    case animatedImage
    case video
}

enum CropShape: String, Codable {
    case circle
    case roundedRectangle
    case square
}

struct CharacterCrop: Codable, Equatable {
    var scale: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var shape: CropShape
}
```

The crop operates on a square output stage. It preserves the source aspect ratio, fills the square by default for opaque media, and lets the user adjust zoom and focal point. Multi-frame packages use a uniform frame interval derived from the sampled duration and frame count.

## Storage

Store custom character packages in Application Support, for example:

```text
Application Support/SitWatcher/CustomCharacters/<uuid>/
  manifest.json
  preview.png
  frames/
    frame-000.png
    frame-001.png
    ...
```

`manifest.json` stores the metadata and crop settings. `preview.png` is the display thumbnail and Reduce Motion fallback. Frame files are the rendered `512x512` output frames.

Import and edit operations write into a temporary package directory first. Only after frame generation succeeds does the app move the completed directory into the custom character store. This prevents half-written packages.

## Import And Edit Flow

The settings UI adds an "Add character" action. After the user chooses a file, the app opens one shared import editor for still images, animated images, and videos.

The editor shows:

- A square preview stage.
- The selected crop shape, defaulting to a circle for opaque media and square for transparent media.
- Drag-to-position focal point.
- Zoom control for subject size.
- Name field.
- For videos only, a start-time slider. The preview loops the 3-second clip beginning at that start time.

On save:

- Static images generate one frame.
- Animated images generate up to 45 frames.
- Videos generate up to 45 frames from the selected 3-second segment.
- Frames are rendered at `512x512`.
- The completed package is added to the character library.

Existing custom characters can be renamed, deleted, and reopened in the same editor to adjust crop, zoom, and video start time. Saving an edit regenerates the frame package.

## Background And Aspect Ratio Handling

The internal stage is always square because the existing reminder character slots are square. The visual treatment depends on source transparency:

- Transparent source: preserve transparency, default to the square stage, and display without forcing a card background.
- Opaque source: default to a circular crop card.

The first version supports these crop shapes:

- Circle, default for opaque media.
- Rounded rectangle.
- Square stage.

The app never stretches media. It preserves the source aspect ratio, uses fill crop by default, and lets the user drag and zoom to keep the subject well framed.

## Settings UI

The "Reminder Character" settings section becomes a small library:

- Built-in characters remain first.
- Custom characters appear after built-ins with thumbnail, name, and selected state.
- An add button appears at the end.
- Custom character cards expose rename, edit, and delete actions.
- Deleting the currently selected custom character falls back to the default built-in character.

The built-in character UI can continue using `RestReminderFigureStyle` previews. Custom character previews use `preview.png`.

## Reminder Rendering

Introduce a unified reminder character view that accepts `ReminderCharacterSelection` and size.

- Built-in selection: reuse the existing asset catalog animation behavior.
- Custom selection: load frame files from the package and loop using the manifest frame interval.
- Reduce Motion: show `preview.png` or the first frame without looping.
- Missing or invalid custom package: fall back to the default built-in character.

The floating and full-screen reminders differ only by the size they pass into this unified view.

## Limits

- Maximum clip duration: 3 seconds.
- Maximum frame count: 45.
- Output frame size: `512x512`.
- Video imports are silent; only image frames are used.
- If source media is shorter than 3 seconds, use the available duration.
- If source media is too small, still allow import but warn that it may look blurry.

## Error Handling

- Unsupported file type: show a clear message asking for PNG, JPEG, GIF, APNG, WebP, MOV, MP4, or M4V.
- Decode failure: keep current settings unchanged and show import failure.
- Frame generation failure: remove the temporary package and keep the library unchanged.
- Missing selected custom package: fall back to the default built-in character.
- Delete action: confirm before removing a custom character.

## Testing

Automated tests cover:

- `ReminderCharacterSelection` persistence and migration from `restReminderFigureStyle`.
- Manifest encode/decode.
- Character store listing, add, edit, delete, and delete-current fallback.
- Frame sampling plan calculation for still images, animated images, short videos, and videos longer than 3 seconds.
- Crop math for fit-to-square, fill-to-square, zoom, and offset clamping.

Manual verification covers:

- Importing a static JPEG or PNG.
- Importing a transparent PNG.
- Importing an animated image.
- Importing a video and changing the start time.
- Editing crop and zoom after import.
- Reduce Motion showing a still preview.
- Deleting the selected custom character.
- Simulating a missing custom package and confirming fallback.
- Building the app with `xcodebuild -scheme SitWatcher`.

## Implementation Notes

- Prefer `ImageIO` for image and animated image decoding.
- Prefer `AVFoundation` for video duration, thumbnails, and frame extraction.
- Keep media processing behind a small service boundary so UI code can preview progress and tests can validate frame plans without decoding real media.
