 # MMRPGPowerCards
Marvel Multiverse RPG Power Card generator

# Card!
 Generator for TheGameCrafter

A PowerShell-based tool for generating custom playing cards from markdown data and SVG templates, with automatic conversion to TheGameCrafter-ready PNG files.

## Overview

This tool automates the creation of card sets by:
1. Parsing card data from markdown files
2. Injecting that data into SVG templates
3. Converting the results to high-quality PNGs with TheGameCrafter naming conventions

Perfect for tabletop game designers, RPG creators, or anyone needing to generate large sets of custom cards for print-on-demand services.

## Features

- **Markdown-driven**: Define your card data in simple markdown format
- **SVG templating**: Use Inkscape-created templates with text replacement zones
- **Batch processing**: Generate hundreds of cards at once
- **TheGameCrafter integration**: Automatic PNG naming for easy batch upload (`CardName[face,1].png`)
- **High-quality output**: 300 DPI default, 1125x1725 dimensions (TheGameCrafter Jumbo size)
- **Flexible formatting**: Supports bold text, line breaks, and custom styling

## Requirements

- **PowerShell 5.0+** (Windows)
- **Inkscape** (for SVG to PNG conversion)
  - Download from [inkscape.org](https://inkscape.org/)
  - Must be installed in default location: `C:\Program Files\Inkscape\`

## Files

- `Generate-Cards.ps1` - Main script for generating cards from markdown
- `Convert-SVGtoPNG.ps1` - Standalone SVG to PNG converter
- `PowersTemplate.svg` - Example SVG template (created with Inkscape)

## Quick Start

### 1. Prepare Your Data
Create a markdown file with your card data. Each card should follow this format:

```markdown
### Card Name
{Flavor text or description}
**Field 1:** Value
**Field 2:** Value
**Effect:** Description of the card effect...
```

**Tip**: If you're converting data from a website, the [MarkDownload](https://github.com/deathau/markdownload) browser extension (available for Chromium-based browsers) can help export web pages directly to markdown format, which you can then clean up for card generation.

### 2. Create Your Template
Use the included `PowersTemplate.svg` as a starting point, or create your own in Inkscape. The template uses text replacement zones that the script will populate.

### 3. Generate Cards

**Generate SVG files only:**
```powershell
.\Generate-Cards.ps1 -MarkdownFilePath "cards.md" -SvgTemplatePath "PowersTemplate.svg" -OutputDirectory "output"
```

**Generate both SVG and PNG files:**
```powershell
.\Generate-Cards.ps1 -MarkdownFilePath "cards.md" -SvgTemplatePath "PowersTemplate.svg" -OutputDirectory "output" -GeneratePNG
```

**Convert existing SVGs to PNGs:**
```powershell
.\Convert-SVGtoPNG.ps1 -SvgDirectory "output" -OutputDirectory "output\PNG"
```

## Parameters

### Generate-Cards.ps1
- `-MarkdownFilePath` - Path to your markdown file
- `-SvgTemplatePath` - Path to your SVG template
- `-OutputDirectory` - Where to save generated files
- `-GeneratePNG` - Also generate PNG files
- `-PngDPI` - PNG resolution (default: 300)
- `-CardFace` - Card face type: "face", "back", or "all" (default: "face")
- `-CardQuantity` - Quantity for TheGameCrafter (default: 1)

### Convert-SVGtoPNG.ps1
- `-SvgDirectory` - Directory containing SVG files
- `-OutputDirectory` - Where to save PNG files
- `-Width` - PNG width in pixels (default: 1125)
- `-Height` - PNG height in pixels (default: 1725)
- `-DPI` - PNG resolution (default: 300)
- `-CardFace` - Card face type for naming (default: "face")
- `-CardQuantity` - Quantity for naming (default: 1)

## Template Creation

1. Open Inkscape and create your card design (1125x1725 pixels)
2. Add text elements where you want dynamic content
3. Use placeholder text that the script can find and replace
4. Save as SVG and update the script's template mapping

The included `PowersTemplate.svg` shows how to structure:
- Title area
- Flavor text area  
- Structured data fields
- Effect descriptions

## Output

**SVG files** use clean naming: `Card Name.svg`

**PNG files** use TheGameCrafter format: `Card Name[face,1].png`

This allows you to:
- Keep clean SVG files for editing
- Upload PNGs directly to TheGameCrafter for printing
- Batch process hundreds of cards efficiently

## TheGameCrafter Integration

**Card Size**: This tool is configured for TheGameCrafter's **Jumbo** size cards (1125x1725 pixels at 300 DPI). 

For other card sizes, you'll need to update the dimensions:
- **Poker** size: 825x1125 pixels
- **Tarot** size: 1050x1800 pixels  
- **Bridge** size: 750x1125 pixels
- **Mini** size: 675x975 pixels

Update the `$Width` and `$Height` parameters in the scripts and resize your SVG template accordingly.

The PNG naming convention follows TheGameCrafter's requirements:
- `CardName[face,1].png` - Front of card, quantity 1
- `CardName[back,1].png` - Back of card, quantity 1  
- `CardName[all,2].png` - Both sides, quantity 2

Simply drag and drop the generated PNG files to TheGameCrafter's bulk upload tool.

## Troubleshooting

**"Inkscape not found"**: Install Inkscape or update the path in the script

**SVG rendering issues**: Check your template structure and text placement zones

**PowerShell bracket issues**: The scripts handle special characters in filenames automatically

## License

MIT License - Feel free to modify and distribute

## Contributing

Pull requests welcome! This tool was created for tabletop game development but can be adapted for any card-based project.


![Accuracy 1 face,1](https://github.com/user-attachments/assets/d146bc94-a525-4a7a-a67d-7d8b4a236ac4)
