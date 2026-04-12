$source = "D:\audri\Xamp\htdocs\MaVieAuJapon\OLD"
$dest   = "D:\audri\Xamp\htdocs\MaVieAuJapon\Migrated"

# Nettoyage
if (Test-Path $dest) {
    Remove-Item -Recurse -Force $dest
}

Get-ChildItem -Recurse -Filter *.md $source | ForEach-Object {

    $content = Get-Content $_.FullName -Raw

    # =========================
    # 🔥 EXTRAIRE FRONTMATTER
    # =========================

    $frontmatter = ""
    $body = $content

    if ($content -match "(?s)^---(.*?)---") {
        $frontmatter = $matches[1]
        $body = $content -replace "(?s)^---.*?---", ""
    }

    $fm = $frontmatter

    # =========================
    # 🔥 SUPPRIMER GRAV
    # =========================

    $fm = $fm -replace '(?s)form:.*', ''
    $fm = $fm -replace '(?m)^published:.*\r?\n', ''
    $fm = $fm -replace '(?m)^publish_date:.*\r?\n', ''
    $fm = $fm -replace '(?s)process:.*?\n', ''
    $fm = $fm -replace '(?m)^\s*(twig|markdown):.*\r?\n', ''
    $fm = $fm -replace '(?m)^\s*null\s*\r?\n', ''

    # =========================
    # 🔄 TAXONOMY
    # =========================

    $fm = $fm -replace 'taxonomy:', ''
    $fm = $fm -replace 'category:', 'categories:'
    $fm = $fm -replace 'tag:', 'tags:'

    # =========================
    # 🕒 DATE SAFE
    # =========================

    if ($fm -match 'date:') {
        $fm = [regex]::Replace($fm, 'date:.*', 'date: 2025-01-01')
    } else {
        $fm = "date: 2025-01-01`n" + $fm
    }

    # =========================
    # 🧼 YAML FIX
    # =========================

    $fm = [regex]::Replace($fm, '(?m)^\s+(categories|tags|title|slug|description|keywords|robots):', '$1:')
    $fm = [regex]::Replace($fm, '(?m)^\s+-', '  -')

    # =========================
    # 🔥 KEYWORDS → LIST
    # =========================

    $fm = [regex]::Replace($fm, 'keywords:\s*(.+)', {
        param($m)
        $items = $m.Groups[1].Value -split ','
        $list = $items | ForEach-Object { "  - " + $_ }
        return "keywords:`n" + ($list -join "`n")
    })

    # =========================
    # 🧠 NORMALISATION MULTILANGUE
    # =========================

    $parent = $_.Directory.Parent.Name
    $current = $_.Directory.Name

    $parent = $parent -replace '^\d+\.', ''
    $current = $current -replace '^\d+\.', ''
    $current = $current -replace '-(fr|en|ja)$', ''

    $cleanPath = "\" + $parent + "\" + $current + "\"

    # =========================
    # 📄 NOM DE FICHIER
    # =========================

    if ($_.Name -match '\.(\w+)\.md$') {
        $lang = $matches[1]
        $filename = "index.$lang.md"
    } else {
        $filename = "index.md"
    }

    $cleanPath += $filename

    # =========================
    # 🧾 FRONTMATTER FINAL
    # =========================

    if ([string]::IsNullOrWhiteSpace($fm)) {
        $fm = "title: 'Untitled'`ndate: 2025-01-01"
    }

    $content = "---`n$($fm)`n---`n$body"

    # =========================
    # 📂 WRITE
    # =========================

    $targetPath = Join-Path $dest $cleanPath

    New-Item -ItemType Directory -Force -Path (Split-Path $targetPath) | Out-Null
    Set-Content -Path $targetPath -Value $content
}