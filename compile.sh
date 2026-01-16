#!/bin/bash

# Compile LaTeX presentation using Docker
# Make sure you have a LaTeX Docker image available

echo "Compiling basic.tex using Docker..."

# Using the official texlive Docker image
docker run --rm -v "$(pwd):/workspace" -w /workspace texlive/texlive:latest pdflatex -interaction=nonstopmode basic.tex

# Run twice for proper references and table of contents
docker run --rm -v "$(pwd):/workspace" -w /workspace texlive/texlive:latest pdflatex -interaction=nonstopmode basic.tex

echo "Compilation complete! Output: basic.pdf"

# Clean up auxiliary files
rm -f basic.aux basic.log basic.nav basic.out basic.snm basic.toc

echo "Cleaned up auxiliary files."
