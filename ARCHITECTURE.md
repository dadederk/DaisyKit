# DaisyKit Architecture

This document describes the current DaisyKit package architecture with a diagram-first view.

## Parse Pipeline

```text
+-------------------------------------+
| parsePublication(at:options:)       |
+-------------------------------------+
                  |
                  v
+-------------------------------------+
| DaisyParserPipeline.parse            |
+-------------------------------------+
                  |
                  v
+-------------------------------------+
| DaisyWorkspaceResolver.resolve...    |
+-------------------------------------+
                  |
                  v
+-------------------------------------+
| locateOPF                            |
+-------------------------------------+
                  |
                  v
+-------------------------------------+
| DaisyOPFParser.parse                 |
+-------------------------------------+
      |                    |                     |
      v                    v                     v
+-------------+   +-------------------+   +----------------+
| parseNCX... |   | parseDTBook...    |   | parseSmilRefs  |
+-------------+   +-------------------+   +----------------+
                         |                     |
                         +----------+----------+
                                    v
                    +----------------------------------+
                    | DaisyNormalizer.validateSmil...  |
                    +----------------------------------+
                                    |
                                    v
                    +----------------------------------+
                    | DaisyNormalizer.buildPublication |
                    +----------------------------------+
                                    |
                                    v
                    +------------------------------+
                    | DaisyPublication (normalized)|
                    +------------------------------+

From OPF parse:
  +----------------------------+
  | DaisyPublicationRaw        |
  +----------------------------+

Diagnostics path:
  DaisyDiagnosticCollector records diagnostics across OPF/NCX/DTBook/SMIL/Normalizer
  and contributes them to the final report.

Final:
  DaisyParseReport = { raw, publication, diagnostics }
```

## Package Components

```text
+-----------------------------+      +----------------------------------------+
| API                         | ---> | Parsing                                |
| - DaisyKit.swift            |      | - DaisyParserPipeline                  |
| - DaisyParseTypes.swift     |      | - WorkspaceResolver                    |
+-----------------------------+      | - OPFParser / NCXParser / DTBookParser |
                                     | - SMILParser                           |
                                     | - Normalizer                           |
                                     | - PathResolution / XMLHelpers          |
                                     +-------------------+--------------------+
                                                         |
                                                         v
                              +--------------------------+----------------------+
                              | Models                                         |
                              | - DaisyRawModels                               |
                              | - DaisyNormalizedModels                        |
                              | - DaisyDiagnostics                             |
                              +--------------------------+----------------------+
                                                         |
                                                         v
                                           +---------------------------+
                                           | Support                   |
                                           | - DaisyLogger (OSLog)     |
                                           +---------------------------+
```

## Public Output Model Relationships

```text
+--------------------------------------------------------------+
| DaisyParseReport                                             |
| - raw: DaisyPublicationRaw                                   |
| - publication: DaisyPublication                              |
| - diagnostics: [DaisyDiagnostic]                             |
+-----------------------+--------------------+-----------------+
                        |                    |
                        v                    v
     +--------------------------------+   +---------------------------+
     | DaisyPublicationRaw            |   | DaisyPublication          |
     | - metadata: DaisyMetadata      |   | - title: String           |
     | - manifest: [DaisyManifestItem]|   | - sections: [DaisySection]|
     | - spine: [DaisySpineItem]      |   +-------------+-------------+
     | - navPoints: [DaisyNavPoint]   |                 |
     | - smilRefs: [DaisySmilRef]     |                 v
     +----------------+---------------+      +-------------------------------+
                      |                      | DaisySection                  |
                      |                      | - sourcePath                  |
                      |                      | - title                       |
                      |                      | - paragraphs: [DaisyParagraph]|
                      |                      | - headings: [DaisyHeading]    |
                      |                      | - anchors: [DaisyAnchor]      |
                      |                      +----------+-----------+---------+
                      |                                 |           |
                      v                                 v           v
  DaisyMetadata, DaisyManifestItem,           DaisyParagraph   DaisyHeading
  DaisySpineItem, DaisyNavPoint,              DaisyAnchor      (anchor links
  DaisySmilRef                                                 section/id hrefs)
```

## Diagnostics and Parse Mode Behavior

```text
Parser emits DaisyDiagnostic
          |
          v
DaisyDiagnosticCollector.record
          |
          v
   +-------------------------------+
   | mode == strict AND error ?    |
   +---------------+---------------+
                   | yes
                   v
        Throw DaisyParseError now
                   |
                  stop

                   no
                   v
        Append diagnostic and continue parsing
```

## Input and Workspace Resolution

```text
Input URL
   |
   v
+---------------------------+
| Directory or .zip ?       |
+-------------+-------------+
              | directory
              v
   +-------------------------------+
   | Use directory as workspace    |
   +---------------+---------------+
                   |
                   v
        Pipeline reads from workspace root

              | zip
              v
   +-------------------------------+
   | Extract to temporary workspace|
   +---------------+---------------+
                   |
                   v
   +-------------------------------+
   | Enforce zip limits            |
   | - max entries                 |
   | - max entry size              |
   | - max total uncompressed size |
   +---------------+---------------+
                   |
                   v
   +-------------------------------+
   | Block unsafe paths/traversal  |
   +---------------+---------------+
                   |
                   v
        Pipeline reads from workspace root
```
