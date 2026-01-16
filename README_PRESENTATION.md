# Multimedia Technology Fundamentals Presentation

## Overview
This is a comprehensive 50-slide presentation covering multimedia technology fundamentals including:
- Multimedia Basics (Multimedia, Hypermedia, WWW, Internet, Software Tools)
- Graphics and Image Data Representation
- Color in Images (Color Science and Models)
- Concepts in Digital Video

## Features
- **Interactive Content**: Real-world examples and case scenarios
- **Visual Diagrams**: TikZ-generated illustrations for better understanding
- **Professional Theme**: Madrid Beamer theme with clean layout
- **Comprehensive Coverage**: 50 slides covering all major topics

## Files
- `basic.tex` - Main LaTeX presentation source file
- `basic.pdf` - Compiled PDF presentation (246 KB)
- `compile.sh` - Shell script to compile using Docker
- `images/` - Directory for additional images (if needed)

## Compilation

### Using Docker (Recommended)
The presentation uses the `danteev/texlive` Docker image for compilation.

```bash
# Make the script executable
chmod +x compile.sh

# Run the compilation script
./compile.sh
```

### Manual Compilation with Docker
```bash
# First pass
docker run --rm -v "$(pwd):/workspace" -w /workspace danteev/texlive:latest pdflatex -interaction=nonstopmode basic.tex

# Second pass (for table of contents)
docker run --rm -v "$(pwd):/workspace" -w /workspace danteev/texlive:latest pdflatex -interaction=nonstopmode basic.tex
```

### Using Local LaTeX Installation
If you have LaTeX installed locally:
```bash
pdflatex basic.tex
pdflatex basic.tex
```

## Presentation Structure

### Section 1: Multimedia Basics (Slides 1-12)
- What is Multimedia?
- Multimedia Applications
- Hypermedia Explained
- World Wide Web (WWW)
- Internet Architecture
- Internet vs WWW
- Multimedia Software Categories
- Editing Tools (Image, Video, Audio)
- Authoring Tools and Paradigms

### Section 2: Graphics and Image Data (Slides 13-22)
- Graphics Data Types (Raster vs Vector)
- Image Resolution and Quality
- Popular File Formats (JPEG, PNG, GIF, SVG, WebP)
- Format Comparisons and Use Cases

### Section 3: Color in Images (Slides 23-32)
- Color Science Fundamentals
- Additive vs Subtractive Color
- RGB Color Model
- CMYK Color Model
- HSV/HSB and HSL Color Models
- YUV/YCbCr Color Model
- Color Depth and Bit Depth
- Color Spaces and Gamut
- Gamma Correction
- Color Management

### Section 4: Digital Video (Slides 33-48)
- What is Digital Video?
- Video Resolution Standards
- Aspect Ratios
- Interlaced vs Progressive Scan
- Video Compression Necessity
- Compression Types (Spatial/Temporal)
- Video Codecs (H.264, H.265, VP9, AV1)
- Video Container Formats
- Bitrate and Quality
- Chroma Subsampling
- Video Streaming Technologies
- Video Editing Workflow

### Summary and References (Slides 49-50)

## Real-World Examples Included
- Netflix streaming technology
- YouTube video formats
- iPhone display specifications
- Amazon.com client-server architecture
- Digital camera image processing
- Professional printing workflows
- Gaming and VR applications
- E-learning platforms

## Visual Elements
The presentation includes:
- TikZ diagrams for technical concepts
- Color-coded blocks for different information types
- Comparison tables
- Visual representations of color models
- Network architecture diagrams
- Video compression visualizations

## Requirements
- Docker with `danteev/texlive` image, OR
- Local LaTeX installation with:
  - Beamer class
  - TikZ package
  - Listings package
  - Hyperref package

## Customization
To customize the presentation:
1. Edit `basic.tex` with your preferred text editor
2. Modify the theme by changing `\usetheme{Madrid}` to another Beamer theme
3. Add images to the `images/` directory and include them using `\includegraphics`
4. Adjust colors using the `\usecolortheme` command

## Notes
- The presentation is designed for 16:9 aspect ratio
- All content fits within standard Beamer frames
- Interactive elements include clickable table of contents
- PDF bookmarks are automatically generated

## Author
MMT Class

## License
Educational use

## Compilation Time
Approximately 10-15 seconds per pass with Docker
