# Fixed Marvel RPG Plain Text to Properly Formatted Markdown

function Convert-PlainTextToMarkdown {
    param(
        [string]$PlainTextFile,
        [string]$OutputFile
    )
    
    Write-Host "Reading plain text file..."
    $content = Get-Content -Path $PlainTextFile -Raw -Encoding UTF8
    
    # Split into lines and process sequentially
    $lines = $content -split "\r?\n"
    
    $markdownContent = @()
    $markdownContent += "# Marvel RPG Powers"
    $markdownContent += ""
    $powerCount = 0
    
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i].Trim()
        
        # Skip empty lines and art credits
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match "^Art by") {
            $i++
            continue
        }
        
        # Power names are short and don't contain colons.
        if ($line -notmatch ":" -and $line.Length -lt 50) {
            
            # Find the next meaningful line to determine if this is a power
            $nextLineIndex = $i + 1
            $nextLine = ""
            while ($nextLineIndex -lt $lines.Count) {
                $potentialNextLine = $lines[$nextLineIndex].Trim()
                if ([string]::IsNullOrWhiteSpace($potentialNextLine) -or $potentialNextLine -match "^Art by") {
                    $nextLineIndex++
                } else {
                    $nextLine = $potentialNextLine
                    break
                }
            }

            # A power is followed by a description OR a field.
            $descriptionPattern = "^(The character|You won.t like|By manipulating|Nobody pushes|Seeing the enemy|Time seems|Ouch!|SMASH!|To be twice|Everything|Little|The targets|Few|Environmental|When|An|Silence|When the enemy|An unnatural|Silence falls|The temperature|Time seems|To be|Art by|A character|As long as|Aimed at|The attacker|This requires|For every|During|Any time|With|Characters|If a target|The result|The command|The player|It starts|Using a mirage|The target|If the character|The character’s|The communication|The duplicates|Friendly animals|Animals with|The vehicle’s|Simple machines|When in any|The next|Once per|Each affected|Any allies|The fall|For every point|The character can|The character makes|The character gains|The character splits|The character looks|The character fires|The character unleashes|The character summons|The character generates|The character extends|The character channels|The character creates|The character calls|The character puts|The character uses|The character’s body|The character mentally|The character instantly|The character is|The character has|The character pummels|The character envelops|The character stands|The character’s words|The character and|The character chooses|The character takes|The character prepares|The character becomes|The character continues|The character whips|The character may|The character cracks|The character’s mind|The character weaves|The character commands|The character runs|The character also|The character shoots|The character’s attacks|The character’s skeleton|The character’s bones|The character’s skin|The character’s body|The character is known|The character must|The character is not|The character is protected|The character picks|The character enters|The character’s melee|The character’s ranged|The character’s next|The character’s damage|The character’s powers|The character’s Focus|The character’s Health|The character’s defenses|The character’s attacks|The character’s abilities|The character’s traits|The character’s speed|The character’s size|The character’s form|The character’s appearance|The character’s equipment|The character’s attacks have|The character’s checks|The character’s rolls|The character’s Marvel die)"
            $fieldPattern = "^(Power Set|Prerequisites|Action|Trigger|Duration|Range|Cost|Effect):\s*(.*)$"

            if ($nextLine -match $descriptionPattern -or $nextLine -match $fieldPattern) {
                # This is a power!
                $powerName = $line
                
                Write-Host "Processing: $powerName"
                $powerCount++
                
                # Build the markdown for this power
                $powerMarkdown = @()
                $powerMarkdown += "### $powerName"
                $powerMarkdown += ""

                if ($nextLine -match $descriptionPattern) {
                    $description = $nextLine
                    Write-Host "Description found: '$description'"
                    $powerMarkdown += "{$description}"
                    $powerMarkdown += ""
                    # Move index past the description we just processed
                    $i = $nextLineIndex + 1
                } else {
                    # No description line, just a field. Move index to the field line.
                    $i = $nextLineIndex
                }
                
                # Parse fields until we hit the next power or end of file
                $currentField = ""
                $fieldValue = ""
                
                while ($i -lt $lines.Count) {
                    $fieldLine = $lines[$i].Trim()
                    
                    # Check if we've hit the next power before processing the line
                    if ([string]::IsNullOrWhiteSpace($fieldLine) -or $fieldLine -match "^Art by") {
                        $i++
                        continue
                    }

                    if ($fieldLine -notmatch ":" -and $fieldLine.Length -lt 50) {
                        # Potential next power. Look ahead to confirm.
                        $nextPotentialPowerIndex = $i + 1
                        $nextMeaningfulLine = ""
                        while ($nextPotentialPowerIndex -lt $lines.Count) {
                            $potentialNext = $lines[$nextPotentialPowerIndex].Trim()
                            if ([string]::IsNullOrWhiteSpace($potentialNext) -or $potentialNext -match "^Art by") {
                                $nextPotentialPowerIndex++
                            } else {
                                $nextMeaningfulLine = $potentialNext
                                break
                            }
                        }
                        
                        if ($nextMeaningfulLine -match $descriptionPattern -or $nextMeaningfulLine -match $fieldPattern) {
                            # It's the next power, so break out of field processing.
                            break
                        }
                    }
                    
                    $i++ # Consume the line now

                    # Check if this line starts a new field
                    if ($fieldLine -match $fieldPattern) {
                        # Save the previous field if we have one
                        if ($currentField -and $fieldValue) {
                            $powerMarkdown += "**$currentField" + ":** $fieldValue"
                            $powerMarkdown += ""
                        }
                        
                        # Start new field
                        $currentField = $matches[1]
                        $fieldValue = $matches[2].Trim()
                    }
                    elseif ($currentField) {
                        # Continue building the current field value
                        if ($fieldValue) {
                            $fieldValue += " " + $fieldLine
                        } else {
                            $fieldValue = $fieldLine
                        }
                    }
                }
                
                # Don't forget the last field
                if ($currentField -and $fieldValue) {
                    $powerMarkdown += "**$currentField" + ":** $fieldValue"
                    $powerMarkdown += ""
                }
                
                # Add this power to the main content
                $markdownContent += $powerMarkdown
            } else {
                $i++
            }
        } else {
            $i++
        }
    }
    
    # Join all content and save
    $finalMarkdown = $markdownContent -join "`n"
    
    # Clean up extra blank lines
    $finalMarkdown = $finalMarkdown -replace "\n\n\n+", "`n`n"
    
    Set-Content -Path $OutputFile -Value $finalMarkdown -Encoding UTF8
    Write-Host "`nConversion complete!"
    Write-Host "Processed $powerCount powers"
    Write-Host "Markdown file saved to: $OutputFile"
}

# Usage
$plainTextFile = "PowersPlainText.txt"  # Your plain text file
$outputFile = "Powers_Formatted.md"     # Output markdown file

# Check if input file exists
if (-not (Test-Path $plainTextFile)) {
    Write-Error "Plain text file not found: $plainTextFile"
    Write-Host "Make sure the file name matches your plain text file"
    exit 1
}

# Run the conversion
Convert-PlainTextToMarkdown -PlainTextFile $plainTextFile -OutputFile $outputFile

Write-Host "`nYou can now copy and paste the contents of '$outputFile'!"
Write-Host "Opening the file for you..."

# Try to open the file automatically
try {
    Start-Process notepad.exe $outputFile
} catch {
    Write-Host "Could not open automatically. Please open '$outputFile' manually."
}