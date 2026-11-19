# Social Media Data Package Analyzer

**Developed by KepicLabs**

A collection of forensic analysis tools designed to parse, organize, and visualize exported social media data packages into searchable, human-readable reports.

## Overview

Social media platforms allow users to download copies of their account data. These exports often contain large amounts of JSON, CSV, HTML, and media files that can be difficult to review manually.

**Social Media Data Package Analyzer** simplifies this process through platform-specific parsers that transform raw account exports into organized, readable reports.

The project is designed for:

- Digital Forensics and Incident Response (DFIR)
- Authorized investigations
- Account activity analysis
- Message and communication review
- Media and attachment analysis
- Personal data review

Each platform has its own analyzer, allowing tools to be developed and maintained independently while following a consistent reporting approach.

## Key Features

- **Automated Parsing:** Process supported social media data exports.
- **Single HTML Report:** Consolidate available information into a searchable report.
- **Message Analysis:** Review messages, timestamps, usernames, channels, and available conversation information.
- **Identity Resolution:** Translate platform-specific user and channel IDs into readable names when metadata permits.
- **Media Viewer:** Organize images, videos, audio, and attachments with previews when available.
- **Account Information:** Extract available account details and profile metadata.
- **Activity Analysis:** Review available account activity and interaction records.
- **Progress Tracking:** Display processing progress during analysis.
- **Evidence Preservation:** Read source data without modifying the original export.
- **Local Processing:** Process data without uploading evidence to external services.

Feature availability depends on the platform and analyzer version.

## Supported Platforms

| Platform | Status | Documentation |
|---|---|---|
| Discord | Initial release — testing ongoing | [Discord Analyzer](Discord/README.md) |
| Facebook | Planned | Coming soon |
| Instagram | Planned | Coming soon |
| Snapchat | Planned | Coming soon |
| TikTok | Planned | Coming soon |
| Reddit | Planned | Coming soon |
| Additional platforms | Future consideration | — |

## Repository Structure

```text
Social-Media-Data-Package-Analyzer/
│
├── Discord/
│   ├── Discord-Package-Viewer.ps1
│   └── README.md
│
├── Facebook/              # Planned
├── Instagram/             # Planned
├── Snapchat/              # Planned
├── TikTok/                # Planned
├── Reddit/                # Planned
│
├── Shared/                # Future shared components
│
├── README.md
├── CHANGELOG.md
└── LICENSE
```

Planned directories will be added as development begins. GitHub does not track empty directories.

## Requirements

Requirements vary by platform.

The current Discord analyzer is designed for:

- Windows 10/11
- Windows PowerShell 5.1 or later
- Extracted Discord data package
- Modern web browser

Additional requirements will be documented in each platform's README.

## Installation

Clone the repository:

```powershell
git clone https://github.com/KepicLabs/Social-Media-Data-Package-Analyzer.git
```

Alternatively, download the repository ZIP from GitHub.

The current Discord analyzer is designed to run without additional PowerShell modules.

## Getting Started

### Discord Data Package Viewer

1. Request your data package through Discord.
2. Download and extract the ZIP archive.
3. Open the `Discord` folder in the repository.
4. Run `Discord-Package-Viewer.ps1`.
5. Enter the extracted package folder path when prompted.
6. Wait for processing to complete.
7. Open the generated HTML report.

Example:

```powershell
& ".\Discord\Discord-Package-Viewer.ps1"
```

For detailed instructions, see the [Discord README](Discord/README.md).

Future platforms will have their own setup and usage instructions.

## Report Capabilities

The analyzers aim to organize the following data when available in the source export.

| Category | Description |
|---|---|
| Overview | Account and export information |
| Messages | Message content, timestamps, and conversations |
| Users | Available usernames, identifiers, and relationships |
| Media | Images, videos, audio, and attachments |
| Groups | Servers, groups, communities, and memberships |
| Activity | Available account activity and interactions |
| Connections | Associated accounts and platform relationships |
| Metadata | Original identifiers, timestamps, and source references |

Not every social media platform includes every category.

## Forensic Integrity

The project is designed to support evidence preservation and traceability.

### Evidence Handling

- Preserve original downloaded archives.
- Avoid modifying source evidence.
- Retain original identifiers and timestamps.
- Maintain references to source records when supported.
- Clearly distinguish resolved and unresolved identities.
- Document parsing errors and unsupported formats.
- Validate extracted findings against original evidence.

Evidence hashing, automated validation, and standardized forensic exports are planned enhancements.

### Data Limitations

Social media data exports may not contain:

- Deleted messages or media
- Complete conversations involving other participants
- Historical group or server memberships
- Expired attachment URLs
- Complete login or IP address histories
- All historical account activity

Missing records should not automatically be interpreted as evidence that an event did not occur.

## Privacy and Security

Social media exports frequently contain sensitive personal information.

Only analyze data you own or are authorized to access.

**Do not upload real account exports, private messages, credentials, access tokens, or investigation evidence to this repository.**

Generated HTML reports should be handled as potentially sensitive investigation artifacts.

## Development Roadmap

### Phase 1 — Discord Analyzer

- [x] Initial PowerShell parser
- [x] Interactive folder selection
- [x] HTML report generation
- [x] Processing progress indicator
- [ ] Improve user and channel identification
- [ ] Expand embedded media support
- [ ] Improve performance for large exports
- [ ] Add automated regression testing
- [ ] Validate against multiple Discord export formats

### Phase 2 — Additional Platforms

- [ ] Facebook Data Package Analyzer
- [ ] Instagram Data Package Analyzer
- [ ] Snapchat Data Package Analyzer
- [ ] TikTok Data Package Analyzer
- [ ] Reddit Data Package Analyzer

### Phase 3 — Shared Forensic Features

- [ ] Standardized HTML reporting
- [ ] Unified timestamp handling
- [ ] SHA-256 evidence hashing
- [ ] Cross-platform data normalization
- [ ] Communication timelines
- [ ] Relationship analysis
- [ ] Advanced searching and filtering
- [ ] CSV and JSON export options
- [ ] Automated parsing validation

## Contributing

Contributions, bug reports, and feature requests are welcome.

When reporting issues, please provide:

- Affected platform and analyzer version
- PowerShell or runtime version
- Error message
- Steps to reproduce
- Sanitized sample data when possible

Do not include private messages, account credentials, or sensitive personal information in public issues.

## Disclaimer

This project is intended for authorized forensic investigations, security research, and personal data review.

The accuracy and completeness of generated reports depend on the source data and supported parsing capabilities.

These tools do not guarantee recovery of deleted, missing, or inaccessible information.

This project is not affiliated with, endorsed by, or sponsored by Discord, Meta, Snapchat, TikTok, Reddit, or other social media platforms.

## License

To be determined.

## Maintainer

**KepicLabs**

GitHub: https://github.com/KepicLabs

---

**Social Media Data Package Analyzer — Making exported social media data easier to investigate, analyze, and understand.**
