param(
    [Parameter(Mandatory=$true)]
    [string]$MarkdownFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SvgTemplatePath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory
)

function Convert-MarkdownToSVG {
    param([string]$text)
    
    $text = $text -replace '\*\*([^*]+)\*\*', '<tspan style="font-weight:bold">$1</tspan>'
    return $text
}

function Wrap-TextForSVG {
    param(
        [string]$text,
        [int]$maxCharsPerLine = 85,
        [double]$lineHeight = 76.8
    )
    
    # Split by line breaks first to handle the structure properly
    $inputLines = $text -split "`n"
    $wrappedLines = @()
    
    foreach ($inputLine in $inputLines) {
        $inputLine = $inputLine.Trim()
        if ($inputLine -eq "") { continue }
        
        # For lines with bold formatting, we need to be more careful
        if ($inputLine -match '<tspan style="font-weight:bold">') {
            # Split into segments: before bold, bold content, after bold
            $parts = $inputLine -split '(<tspan style="font-weight:bold">[^<]*</tspan>)'
            
            $currentLine = ""
            foreach ($part in $parts) {
                if ($part -eq "") { continue }
                
                if ($part -match '<tspan style="font-weight:bold">') {
                    # This is a bold segment - don't split it
                    if (($currentLine + $part).Length -le $maxCharsPerLine) {
                        $currentLine += $part
                    } else {
                        # Start a new line with the bold part
                        if ($currentLine -ne "") {
                            $wrappedLines += $currentLine.Trim()
                        }
                        $currentLine = $part
                    }
                } else {
                    # Regular text - can be wrapped normally
                    $words = $part -split '\s+'
                    foreach ($word in $words) {
                        if ($word -eq "") { continue }
                        
                        if (($currentLine + " " + $word).Length -le $maxCharsPerLine) {
                            if ($currentLine -eq "") {
                                $currentLine = $word
                            } else {
                                $currentLine += " " + $word
                            }
                        } else {
                            if ($currentLine -ne "") {
                                $wrappedLines += $currentLine.Trim()
                            }
                            $currentLine = $word
                        }
                    }
                }
            }
            
            if ($currentLine -ne "") {
                $wrappedLines += $currentLine.Trim()
            }
        } else {
            # No formatting - wrap normally
            $words = $inputLine -split '\s+'
            $currentLine = ""
            
            foreach ($word in $words) {
                if (($currentLine + " " + $word).Length -le $maxCharsPerLine) {
                    if ($currentLine -eq "") {
                        $currentLine = $word
                    } else {
                        $currentLine += " " + $word
                    }
                } else {
                    if ($currentLine -ne "") {
                        $wrappedLines += $currentLine
                    }
                    $currentLine = $word
                }
            }
            
            if ($currentLine -ne "") {
                $wrappedLines += $currentLine
            }
        }
    }
    
    # Convert to SVG tspan elements
    $svgText = ""
    for ($i = 0; $i -lt $wrappedLines.Count; $i++) {
        $y = 457.59209 + ($i * $lineHeight)
        $svgText += "<tspan x=`"98.253906`" y=`"$y`">$($wrappedLines[$i])</tspan>"
        if ($i -lt $wrappedLines.Count - 1) {
            $svgText += "`n"
        }
    }
    
    return $svgText
}

function Parse-PowersFromMarkdown {
    param([string]$content)
    
    # Split content by headers (### or ##) using multiline mode
    $powerEntries = $content -split '(?m)(?=^###?\s)' | Where-Object { $_.Trim() -ne "" }
    
    Write-Host "Found $($powerEntries.Count) power entries"
    
    # Debug: Show first few characters of each entry
    for ($i = 0; $i -lt [Math]::Min(5, $powerEntries.Count); $i++) {
        $preview = $powerEntries[$i].Substring(0, [Math]::Min(50, $powerEntries[$i].Length)).Replace("`n", " ")
        Write-Host "Power $i preview: $preview..."
    }
    
    return $powerEntries
}

function Process-PowerEntry {
    param(
        [string]$powerText,
        [string]$svgTemplate,
        [string]$outputDir
    )
    
    # Split the power text into lines
    $lines = $powerText -split "`n" | Where-Object { $_ -ne "" }
    
    # Extract power name (first line, remove # and trim)
    $powerName = $lines[0] -replace '^#+\s*', ''
    $powerName = $powerName.Trim()
    
    Write-Host "Processing power: $powerName"
    
    $quote = ""
    $bodyLines = @()
    $foundQuote = $false
    
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        
        if ($line -match '^\{([^}]+)\}$' -and -not $foundQuote) {
            $quote = $line -replace '^\{([^}]+)\}$', '$1'
            $foundQuote = $true
            Write-Host "Found quote: $quote"
        } elseif ($line -match '^\*\*([^*:]+):\*\*' -and $foundQuote) {
            $bodyLines += $line
            Write-Host "Added body line: $line"
        } elseif ($foundQuote -and $line -ne "" -and -not ($line -match '^\{([^}]+)\}$') -and -not ($line -match '^#+\s')) {
            $bodyLines += $line
            Write-Host "Added continuation: $line"
        }
    }
    
    $body = ($bodyLines -join "`n").Trim()
    $body = Convert-MarkdownToSVG $body
    $wrappedBody = Wrap-TextForSVG $body
    
    Write-Host "Final wrapped body length: $($wrappedBody.Length)"
    
    $svgContent = $svgTemplate
    $svgContent = $svgContent.Replace("ChangePower", $powerName)
    $svgContent = $svgContent.Replace("ChangeQuote", $quote)
    $svgContent = $svgContent.Replace("ChangeBody", $wrappedBody)
    
    $safeFileName = $powerName -replace '[<>:"/\\|?*]', '_'
    $outputPath = Join-Path $outputDir "$safeFileName.svg"
    
    $svgContent | Out-File -FilePath $outputPath -Encoding UTF8
    
    Write-Host "Generated: $outputPath"
}

try {
    if (-not (Test-Path $MarkdownFilePath)) {
        throw "Markdown file not found: $MarkdownFilePath"
    }
    
    if (-not (Test-Path $SvgTemplatePath)) {
        throw "SVG template file not found: $SvgTemplatePath"
    }
    
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        Write-Host "Created output directory: $OutputDirectory"
    }
    
    $svgTemplate = Get-Content $SvgTemplatePath -Raw
    $content = Get-Content $MarkdownFilePath -Raw
    
    # Parse powers into array
    $powers = Parse-PowersFromMarkdown $content
    
    Write-Host "Processing $($powers.Count) powers..."
    
    # Process each power entry
    for ($i = 0; $i -lt $powers.Count; $i++) {
        $powerText = $powers[$i]
        
        # Skip if this doesn't look like a power entry
        if (-not ($powerText -match '^###?\s')) {
            Write-Host "Skipping entry $i - doesn't start with header"
            continue
        }
        
        Write-Host "`nProcessing power $($i + 1) of $($powers.Count)..."
        Process-PowerEntry -powerText $powerText -svgTemplate $svgTemplate -outputDir $OutputDirectory
    }
    
    Write-Host "Card generation complete!"
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}