$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$schemaPath = Join-Path $root 'docs\tre_schema_map.json'
$namespacePath = Join-Path $root 'NAMESPACE'
$legacyWrappersPath = Join-Path $root 'R\wrappers.R'
$corePath = Join-Path $root 'R\core.R'
$rdPath = Join-Path $root 'man\tre_command_wrappers.Rd'

$json = Get-Content $schemaPath -Raw | ConvertFrom-Json

function Normalize-ParamName {
    param([string]$Raw)

    $value = ($Raw | Out-String).Trim().ToLowerInvariant()
    $value = $value -replace '^[\-\s]+', ''
    $value = $value -replace '[^a-z0-9]+', '_'
    $value = $value -replace '^_+|_+$', ''
    $value = $value -replace '_{2,}', '_'
    if (-not $value) {
        return $null
    }
    if ($value -match '^[0-9]') {
        return ('x_' + $value)
    }
    $value
}

function Parse-CommandArgs {
    param([string]$Command)

    $parsed = New-Object System.Collections.Generic.List[object]
    if (-not $Command) {
        return $parsed
    }

    foreach ($match in [regex]::Matches($Command, '<([^>]+)>|\[([^\]]+)\]')) {
        $raw = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        $name = Normalize-ParamName $raw
        if ($name) {
            $parsed.Add([pscustomobject]@{ Param = $name; Key = $name })
        }
    }
    $parsed
}

function Parse-ImportantInputFlags {
    param([string]$ImportantInputs)

    $parsed = New-Object System.Collections.Generic.List[object]
    if (-not $ImportantInputs) {
        return $parsed
    }

    foreach ($match in [regex]::Matches($ImportantInputs, '--[a-zA-Z0-9-]+')) {
        $flag = $match.Value.Substring(2)
        $name = Normalize-ParamName $flag
        if ($name) {
            $parsed.Add([pscustomobject]@{ Param = $name; Key = $flag })
        }
    }
    $parsed
}

function Unique-Parameters {
    param([System.Collections.Generic.List[object]]$Items)

    $reserved = @('client', '...', '.body', '.protocol_version')
    $seen = @{}
    $unique = New-Object System.Collections.Generic.List[object]

    foreach ($item in $Items) {
        if (-not $item.Param -or $reserved -contains $item.Param) {
            continue
        }
        if ($seen.ContainsKey($item.Param)) {
            continue
        }
        $seen[$item.Param] = $true
        $unique.Add($item)
    }
    @($unique | ForEach-Object { $_ })
}

function To-AsciiText {
    param([string]$Text)

    if (-not $Text) {
        return ''
    }

    $flat = ($Text -replace '`r|`n', ' ').Trim()
    $ascii = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($flat))
    ($ascii -replace '\s{2,}', ' ').Trim()
}

function Normalize-CommandToken {
    param([string]$Token)

    $value = (To-AsciiText $Token).ToLowerInvariant().Trim()
    if (-not $value) {
        return $null
    }
    $value = $value -replace '[^a-z0-9\-\|]', ''
    $value
}

function Resolve-ChoiceToken {
    param(
        [string]$Token,
        [string[]]$FunctionTokens
    )

    if (-not $Token -or $Token.IndexOf('|') -lt 0) {
        return $Token
    }

    $choices = @($Token -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($choices.Count -eq 0) {
        return $Token
    }

    foreach ($choice in $choices) {
        $normalizedChoice = ($choice -replace '-', '_')
        if ($FunctionTokens -contains $normalizedChoice) {
            return $choice
        }
    }

    $choices[0]
}

function Protocol-KindFromCommand {
    param(
        [string]$Command,
        [string]$Function
    )

    if (-not $Command) {
        return ($Function -replace '_', '.')
    }

    $withoutArgs = (To-AsciiText $Command) -replace '<[^>]+>', '' -replace '\[[^\]]+\]', ''
    $parts = @($withoutArgs -split '\s+' | ForEach-Object { Normalize-CommandToken $_ } | Where-Object { $_ })
    if ($parts.Count -eq 0) {
        return ($Function -replace '_', '.')
    }

    $functionTokens = @($Function.ToLowerInvariant().Split('_'))
    $resolved = New-Object System.Collections.Generic.List[string]
    foreach ($part in $parts) {
        $resolved.Add((Resolve-ChoiceToken -Token $part -FunctionTokens $functionTokens))
    }

    ($resolved -join '.')
}

$rows = @()
foreach ($cat in $json.categories.PSObject.Properties) {
    foreach ($item in $cat.Value) {
        $fn = ($item.function | Out-String).Trim()
        $status = ($item.statusAndPurpose | Out-String).Trim()
        if ($fn -match '^[A-Za-z][A-Za-z0-9_]*$' -and $cat.Name -ne 'Runtime' -and $status -ne '') {
            $rows += [pscustomobject]@{
                Function = $fn
                Command = ($item.command | Out-String).Trim()
                Category = $cat.Name
                StudyContext = (($item.studyContext | Out-String).Trim())
                ImportantInputs = (($item.importantInputs | Out-String).Trim())
                Output = (($item.output | Out-String).Trim())
                StatusAndPurpose = $status
            }
        }
    }
}
$rows = $rows | Sort-Object Function -Unique

$kindRows = @()
foreach ($row in $rows) {
    $kindRows += [pscustomobject]@{
        Function = $row.Function
        Kind = (Protocol-KindFromCommand -Command $row.Command -Function $row.Function)
    }
}

$categoryFileMap = [ordered]@{
    'Assets, Datafiles, Datasets' = 'assets.R'
    'Authentication, Daemon, Sessions' = 'auth_session.R'
    'Datastore, Semantic Catalog' = 'datastore.R'
    'Entities, Relations, Transformations, Ingest' = 'entities.R'
    'Local Commands' = 'local.R'
    'Study, Governance' = 'study.R'
}

$core = New-Object System.Text.StringBuilder
[void]$core.AppendLine('TRE_PROTOCOL_VERSION <- "1.0.0"')
[void]$core.AppendLine('TRE_COMMAND_KIND_MAP <- list(')
for ($i = 0; $i -lt $kindRows.Count; $i++) {
    $entry = $kindRows[$i]
    $suffix = if ($i -eq ($kindRows.Count - 1)) { '' } else { ',' }
    [void]$core.AppendLine(('  "{0}" = "{1}"{2}' -f $entry.Function, $entry.Kind, $suffix))
}
[void]$core.AppendLine(')')
[void]$core.AppendLine('')
[void]$core.AppendLine('compact_null_fields <- function(x) {')
[void]$core.AppendLine('  if (length(x) == 0L) {')
[void]$core.AppendLine('    return(list())')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('  x[!vapply(x, is.null, logical(1))]')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('merge_request_body <- function(auto_fields = list(), dot_fields = list(), explicit_body = NULL) {')
[void]$core.AppendLine('  if (!is.null(explicit_body)) {')
[void]$core.AppendLine('    return(explicit_body)')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('')
[void]$core.AppendLine('  body <- compact_null_fields(auto_fields)')
[void]$core.AppendLine('  dots <- compact_null_fields(dot_fields)')
[void]$core.AppendLine('  if (length(dots) == 0L) {')
[void]$core.AppendLine('    return(body)')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('')
[void]$core.AppendLine('  named <- names(dots)')
[void]$core.AppendLine('  if (is.null(named)) {')
[void]$core.AppendLine('    return(c(body, dots))')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('')
[void]$core.AppendLine('  for (i in seq_along(dots)) {')
[void]$core.AppendLine('    key <- names(dots)[[i]]')
[void]$core.AppendLine('    if (is.null(key) || !nzchar(key)) {')
[void]$core.AppendLine('      next')
[void]$core.AppendLine('    }')
[void]$core.AppendLine('    body[[key]] <- dots[[i]]')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('  body')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('new_tre_protocol_request <- function(kind, body = list(), protocol_version = TRE_PROTOCOL_VERSION) {')
[void]$core.AppendLine('  list(')
[void]$core.AppendLine('    protocol_version = protocol_version,')
[void]$core.AppendLine('    kind = kind,')
[void]$core.AppendLine('    body = body %||% list()')
[void]$core.AppendLine('  )')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('tre_result_ok <- function(envelope) {')
[void]$core.AppendLine('  ok <- envelope$ok')
[void]$core.AppendLine('  if (is.logical(ok) && length(ok) == 1L) {')
[void]$core.AppendLine('    return(isTRUE(ok))')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('  is.null(envelope$error) && is.null(envelope$failure)')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('tre_extract_data <- function(envelope) {')
[void]$core.AppendLine('  for (key in c("data", "result", "output", "body")) {')
[void]$core.AppendLine('    if (!is.null(envelope[[key]])) {')
[void]$core.AppendLine('      return(envelope[[key]])')
[void]$core.AppendLine('    }')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('  envelope')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('tre_normalize_output <- function(result, output_label = NULL, status_and_purpose = NULL, function_name = NULL) {')
[void]$core.AppendLine('  envelope <- result$envelope %||% list()')
[void]$core.AppendLine('  if (!tre_result_ok(envelope)) {')
[void]$core.AppendLine('    failure <- protocol_failure_summary(envelope)')
[void]$core.AppendLine('    abort_ahri_tre(')
[void]$core.AppendLine('      sprintf("%s failed: %s", function_name %||% "TRE command", failure$message),')
[void]$core.AppendLine('      class = "ahri_tre_protocol_error"')
[void]$core.AppendLine('    )')
[void]$core.AppendLine('  }')
[void]$core.AppendLine('')
[void]$core.AppendLine('  structure(')
[void]$core.AppendLine('    list(')
[void]$core.AppendLine('      function_name = function_name,')
[void]$core.AppendLine('      output_label = output_label,')
[void]$core.AppendLine('      status_and_purpose = status_and_purpose,')
[void]$core.AppendLine('      data = tre_extract_data(envelope),')
[void]$core.AppendLine('      envelope = envelope,')
[void]$core.AppendLine('      payloads = result$payloads %||% list()')
[void]$core.AppendLine('    ),')
[void]$core.AppendLine('    class = "ahri_tre_wrapper_result"')
[void]$core.AppendLine('  )')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
[void]$core.AppendLine('tre_command_call <- function(')
[void]$core.AppendLine('  client,')
[void]$core.AppendLine('  kind,')
[void]$core.AppendLine('  ...,')
[void]$core.AppendLine('  .auto_fields = list(),')
[void]$core.AppendLine('  .body = NULL,')
[void]$core.AppendLine('  .protocol_version = TRE_PROTOCOL_VERSION,')
[void]$core.AppendLine('  .output_label = NULL,')
[void]$core.AppendLine('  .status_and_purpose = NULL,')
[void]$core.AppendLine('  .function_name = NULL')
[void]$core.AppendLine(') {')
[void]$core.AppendLine('  body <- merge_request_body(')
[void]$core.AppendLine('    auto_fields = .auto_fields,')
[void]$core.AppendLine('    dot_fields = list(...),')
[void]$core.AppendLine('    explicit_body = .body')
[void]$core.AppendLine('  )')
[void]$core.AppendLine('')
[void]$core.AppendLine('  result <- execute_json(')
[void]$core.AppendLine('    client = client,')
[void]$core.AppendLine('    request = new_tre_protocol_request(')
[void]$core.AppendLine('      kind = kind,')
[void]$core.AppendLine('      body = body,')
[void]$core.AppendLine('      protocol_version = .protocol_version')
[void]$core.AppendLine('    )')
[void]$core.AppendLine('  )')
[void]$core.AppendLine('')
[void]$core.AppendLine('  tre_normalize_output(')
[void]$core.AppendLine('    result = result,')
[void]$core.AppendLine('    output_label = .output_label,')
[void]$core.AppendLine('    status_and_purpose = .status_and_purpose,')
[void]$core.AppendLine('    function_name = .function_name')
[void]$core.AppendLine('  )')
[void]$core.AppendLine('}')
[void]$core.AppendLine('')
Set-Content -Path $corePath -Value $core.ToString() -Encoding UTF8

foreach ($categoryName in $categoryFileMap.Keys) {
    $categoryRows = $rows | Where-Object { $_.Category -eq $categoryName } | Sort-Object Function
    $categoryPath = Join-Path $root ("R\" + $categoryFileMap[$categoryName])
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine(("# Auto-generated command wrappers for {0}" -f $categoryName))
    [void]$sb.AppendLine('')

    foreach ($row in $categoryRows) {
        $kind = ($kindRows | Where-Object { $_.Function -eq $row.Function } | Select-Object -First 1).Kind

        $params = New-Object System.Collections.Generic.List[object]
        foreach ($arg in (Parse-CommandArgs $row.Command)) {
            $params.Add($arg)
        }

        if ($row.StudyContext -eq 'single-study') {
            $params.Add([pscustomobject]@{ Param = 'study'; Key = 'study' })
        }

        foreach ($flag in (Parse-ImportantInputFlags $row.ImportantInputs)) {
            $params.Add($flag)
        }

        $params = @(Unique-Parameters $params)

        $sigParts = New-Object System.Collections.Generic.List[string]
        $sigParts.Add('client')
        foreach ($p in $params) {
            $sigParts.Add(($p.Param + ' = NULL'))
        }
        $sigParts.Add('...')
        $sigParts.Add('.body = NULL')
        $sigParts.Add('.protocol_version = TRE_PROTOCOL_VERSION')

        [void]$sb.AppendLine(($row.Function + ' <- function(' + ($sigParts -join ', ') + ') {'))
        $fieldLines = @()
        foreach ($p in $params) {
            if ($null -eq $p -or -not $p.Param -or -not $p.Key) {
                continue
            }
            $fieldLines += ('    "{0}" = {1}' -f $p.Key, $p.Param)
        }

        [void]$sb.AppendLine('  auto_fields <- list(')
        if ($fieldLines.Count -eq 0) {
            [void]$sb.AppendLine('  )')
        } else {
            for ($i = 0; $i -lt $fieldLines.Count; $i++) {
                $suffix = if ($i -eq ($fieldLines.Count - 1)) { '' } else { ',' }
                [void]$sb.AppendLine(($fieldLines[$i] + $suffix))
            }
            [void]$sb.AppendLine('  )')
        }

        $outLabel = (To-AsciiText $row.Output) -replace '"', '\\"'
        $statusLabel = (To-AsciiText $row.StatusAndPurpose) -replace '"', '\\"'

        [void]$sb.AppendLine(('  tre_command_call('))
        [void]$sb.AppendLine(('    client = client,'))
        [void]$sb.AppendLine(('    kind = "{0}",' -f $kind))
        [void]$sb.AppendLine(('    ...,'))
        [void]$sb.AppendLine(('    .auto_fields = auto_fields,'))
        [void]$sb.AppendLine(('    .body = .body,'))
        [void]$sb.AppendLine(('    .protocol_version = .protocol_version,'))
        [void]$sb.AppendLine(('    .output_label = "{0}",' -f $outLabel))
        [void]$sb.AppendLine(('    .status_and_purpose = "{0}",' -f $statusLabel))
        [void]$sb.AppendLine(('    .function_name = "{0}"' -f $row.Function))
        [void]$sb.AppendLine(('  )'))
        [void]$sb.AppendLine('}')
        [void]$sb.AppendLine('')
    }

    Set-Content -Path $categoryPath -Value $sb.ToString() -Encoding UTF8
}

if (Test-Path $legacyWrappersPath) {
    Remove-Item -Path $legacyWrappersPath -Force
}

$nsLines = Get-Content $namespacePath
$useDynLib = $nsLines | Where-Object { $_ -like 'useDynLib(*' } | Select-Object -First 1
$currentExports = $nsLines | Where-Object { $_ -match '^export\(' } | ForEach-Object {
    ($_ -replace '^export\(', '') -replace '\)$', ''
}
$allExports = @($currentExports + ($rows | ForEach-Object { $_.Function })) | Sort-Object -Unique
$nextNamespace = @($useDynLib) + ($allExports | ForEach-Object { "export($_)" })
Set-Content -Path $namespacePath -Value ($nextNamespace -join "`n") -Encoding UTF8

$rdb = New-Object System.Text.StringBuilder
[void]$rdb.AppendLine('\name{tre-command-wrappers}')
foreach ($row in ($rows | Sort-Object Function)) {
    [void]$rdb.AppendLine(('\alias{{{0}}}' -f $row.Function))
}
[void]$rdb.AppendLine('\title{Generated TRE Command Wrapper Functions}')
[void]$rdb.AppendLine('\description{')
[void]$rdb.AppendLine('Auto-generated wrappers for TRE protocol commands. Function parameters are inferred from study context and important input metadata from the command schema.')
[void]$rdb.AppendLine('}')
[void]$rdb.AppendLine('\details{')
[void]$rdb.AppendLine('Wrappers build protocol envelopes through \code{tre_command_call()}, validate protocol-level failures, and return normalized outputs with command output metadata.')
[void]$rdb.AppendLine('Protocol command kinds are derived from the command metadata column (command words joined with dots, preserving hyphenated command segments).')
[void]$rdb.AppendLine('}')
[void]$rdb.AppendLine('\value{')
[void]$rdb.AppendLine('Each function returns an \code{ahri_tre_wrapper_result} containing normalized \code{data}, full \code{envelope}, payloads, and output/status metadata from the command schema.')
[void]$rdb.AppendLine('}')
[void]$rdb.AppendLine('\keyword{package}')

Set-Content -Path $rdPath -Value $rdb.ToString() -Encoding UTF8

Write-Output "WROTE wrappers: $($rows.Count)"
Write-Output "WROTE file: $corePath"
foreach ($name in $categoryFileMap.Values) {
    Write-Output ("WROTE file: " + (Join-Path $root ("R\\" + $name)))
}
if (-not (Test-Path $legacyWrappersPath)) {
    Write-Output "REMOVED file: $legacyWrappersPath"
}
Write-Output "WROTE file: $namespacePath"
Write-Output "WROTE file: $rdPath"