# Discord Data Package Viewer

**KepicLabs | Social Media Data Package Analyzer**

A PowerShell-based forensic utility designed to parse Discord account data exports and convert raw JSON records into a searchable, human-readable HTML report.

## Overview

Discord allows users to request a copy of their account data. These exports can contain hundreds or thousands of files, including messages, account information, server metadata, activity records, and attachment references.

**Discord Data Package Viewer** simplifies reviewing these exports by consolidating available information into a single HTML report.

The tool is intended for digital forensic investigations, incident response, authorized account analysis, and personal data review.

## Features

- **Single HTML Report:** Consolidates parsed data into one readable report.
- **Message Viewer:** Displays exported messages with timestamps and available sender and channel information.
- **Identity Resolution:** Attempts to replace Discord channel and user IDs with readable names using exported metadata.
- **Media Gallery:** Organizes images, videos, and file attachments with previews when accessible.
- **Account Information:** Displays available profile and account records.
- **Server Information:** Extracts available server metadata.
- **Activity Analysis:** Processes Discord activity records, including supported JSON and newline-delimited JSON formats.
- **Search:** Helps locate messages and other exported records.
- **Progress Bar:** Displays processing progress during execution.
- **Folder Prompt:** Requests the extracted Discord package location when launched.
- **Local Processing:** Processes data without uploading it to external services.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or later
- Extracted Discord Data Package
- Modern web browser

No additional PowerShell modules are intended to be required.

## Getting Started

### 1. Request Your Discord Data

In Discord, navigate to:

**User Settings → Data & Privacy → Request Data**

Download the ZIP archive once Discord makes it available.

Discord's official documentation:

https://support.discord.com/hc/articles/360004957991

### 2. Extract the Data Package

Extract the downloaded ZIP into a folder.

Example:

```text
C:\Users\YourName\Downloads\discordpackage
```

The extracted package may contain:

```text
discordpackage/
├── Account/
├── Activity/
├── Activities/
├── Ads/
├── Messages/
├── Servers/
├── Support Tickets/
└── README.txt
```

Some folders may be absent depending on the account and export settings.

### 3. Run the Viewer

Open PowerShell and execute:

```powershell
& ".\Discord-Package-Viewer.ps1"
```

When prompted, enter the full path to your extracted Discord package.

```text
Enter the path to your UNZIPPED Discord data package folder.

Discord folder path:
```

Example input:

```text
C:\Users\YourName\Downloads\discordpackage
```

### 4. Review the Report

Once processing completes, open the generated HTML report.

The intended output filename is:

```text
Discord_Complete_Viewer.html
```

The report is designed to allow users to browse exported information without opening individual JSON files.

## Report Sections

| Section | Description |
|---|---|
| Overview | General information and available records |
| Messages | Exported messages and conversation metadata |
| Images | Available image attachments and previews |
| Videos | Available video attachments |
| Files | Documents and other attachment references |
| Account | Account and profile information |
| Servers | Server information and membership metadata |
| Activity | Available activity and reporting records |
| Other Data | Additional exported JSON information |

## Message and Conversation Analysis

The viewer attempts to display:

- Message timestamps
- Message content
- Available sender information
- Channel names and identifiers
- DM and group DM metadata
- Attachment references
- URLs and links

### Resolving Discord Identifiers

Discord exports may use identifiers such as:

```text
c2304872037453
```

The viewer attempts to resolve these identifiers using information included in the data package.

When names are available, the report displays readable labels.

When names cannot be determined, the original identifiers are retained.

**Important:** Discord personal data exports generally contain messages sent by the account owner, not complete conversations from every participant. The tool cannot reconstruct missing replies or identify users when the necessary metadata is unavailable.

## Images, Videos, and Attachments

The media section is designed to organize available attachments by type.

### Supported Media Categories

- Images: PNG, JPG, JPEG, GIF, WEBP
- Videos: MP4, WEBM, and other recognizable video references
- Audio: MP3, WAV, OGG, and other recognizable audio references
- Documents: PDF, TXT, DOCX, ZIP, and other file references

Media previews depend on browser support and the availability of the underlying files or URLs.

Discord attachment URLs may expire or become inaccessible. The viewer cannot recover media that is no longer available.

## Processing and Progress

The PowerShell script displays progress during processing.

Depending on the export, processing may involve:

1. Discovering files.
2. Reading JSON and supported activity records.
3. Extracting messages and metadata.
4. Resolving available identifiers.
5. Organizing media references.
6. Generating the HTML report.

Large exports may require additional processing time and memory.

## Forensic Considerations

### Evidence Preservation

The viewer is intended to read source data without modifying the original export.

For investigations, preserve the original ZIP and consider recording its SHA-256 hash before extraction.

Maintain a copy of the original data package for validation.

### Data Limitations

Discord exports may not contain:

- Manually deleted messages
- Complete conversations from other participants
- Every historical server membership
- Expired or unavailable attachments
- Complete login and IP histories
- All historical account activity

Missing information should not be interpreted as evidence that an event did not occur.

### Timestamp Handling

Discord exports may contain timestamps in different formats.

Investigators should verify timestamp interpretation against the original records and document any timezone conversion used in their analysis.

## Troubleshooting

### Script Does Not Run

Verify the script path and launch it from PowerShell.

```powershell
& "C:\Tools\Discord-Package-Viewer.ps1"
```

If script execution is blocked, review your organization's PowerShell execution policy before making changes.

### Folder Not Found

Verify that the entered path points to the extracted Discord data package, not the ZIP file.

### Unknown User or Channel Names

The data package may not include enough information to resolve an identifier.

Unresolved identifiers should remain visible for reference.

### Images or Videos Do Not Display

The referenced media may be unavailable, expired, or unsupported by the browser.

### JSON Parsing Errors

Discord exports may contain different JSON structures, including newline-delimited activity records.

Record parsing errors and validate affected files against the original export.

## Known Limitations

- Identity resolution depends on available Discord metadata.
- Deleted or missing messages cannot be reconstructed.
- External attachments may be unavailable.
- Very large exports may produce large HTML files.
- Browser performance may vary with report size.
- Some export structures may require additional parser support.
- Testing against different Discord package formats is ongoing.

## Development Roadmap

- [x] Initial PowerShell parser
- [x] Interactive folder prompt
- [x] HTML report generation
- [x] Progress indicator
- [ ] Improve user and channel identification
- [ ] Expand media preview support
- [ ] Improve large-export performance
- [ ] Add advanced message filtering
- [ ] Add timeline analysis
- [ ] Add evidence hashing and validation
- [ ] Add automated regression tests
- [ ] Validate against multiple Discord export versions

## Privacy and Security

Discord data packages may contain private messages, account information, and sensitive personal data.

Only process data you own or are authorized to investigate.

Do not upload real Discord exports, private messages, account tokens, or investigation evidence to public GitHub repositories.

Generated HTML reports may contain sensitive information and should be handled accordingly.

## Disclaimer

This tool is provided for authorized forensic investigations, research, and personal data analysis.

Generated reports depend on the completeness and structure of the source data.

The tool does not guarantee recovery of deleted, missing, or inaccessible information.

This project is not affiliated with, endorsed by, or sponsored by Discord.

## Maintainer

**KepicLabs**

GitHub: https://github.com/KepicLabs

Part of the **Social Media Data Package Analyzer** project.
