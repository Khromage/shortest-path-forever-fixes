# Re-applies the Questie tracker patch after CurseForge has updated ForeverCore or Shortest Path Forever.
#
#   .\apply.ps1            apply (only over the exact upstream files the patch was built on)
#   .\apply.ps1 -Check     report the state of each file, change nothing
#   .\apply.ps1 -Revert    restore the .orig backups
#
# A file that is neither the known upstream original nor already patched means upstream changed it. The script
# leaves it alone: the patch in patches/ has to be re-ported onto the new upstream version first.
param(
	[string]$AddOns = "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns",
	[switch]$Check,
	[switch]$Revert
)

$files = @(
	@{
		Path     = "ForeverCore\UI\TrackerHost.lua"
		Original = "c217ef2e8d00c9e6702dfc08062589c88a024e1e2168dc65a3dd06bde409a890"
		Patched  = "d22250b8aac33ecff2caa77db45b08e5a1d189dc256393bf75945d05b620ddc5"
	},
	@{
		Path     = "ShortestPathForever\UI\Settings.lua"
		Original = "32acf675ccfd4eb4a487347054f8963a2f27bab389525803737972533d30d86b"
		Patched  = "2bc5618b0e0a29c5897d604a2a1fe8ab11a30402e5b53c5f54444fadccb7cf53"
	}
)

foreach ($file in $files) {
	$installed = Join-Path $AddOns $file.Path
	$source = Join-Path $PSScriptRoot (Join-Path "files" $file.Path)
	$backup = "$installed.orig"
	if (-not (Test-Path $installed)) {
		Write-Host "missing    $($file.Path)"
		continue
	}
	if ($Revert) {
		if (Test-Path $backup) {
			Copy-Item $backup $installed -Force
			Write-Host "reverted   $($file.Path)"
		} else {
			Write-Host "no backup  $($file.Path)"
		}
		continue
	}
	$hash = (Get-FileHash $installed -Algorithm SHA256).Hash.ToLower()
	if ($hash -eq $file.Patched) {
		Write-Host "patched    $($file.Path)"
	} elseif ($hash -ne $file.Original) {
		Write-Host "CHANGED    $($file.Path)  upstream differs from the version this patch was built on; re-port needed"
	} elseif ($Check) {
		Write-Host "original   $($file.Path)  (patch not applied)"
	} else {
		Copy-Item $installed $backup -Force
		Copy-Item $source $installed -Force
		Write-Host "applied    $($file.Path)"
	}
}
