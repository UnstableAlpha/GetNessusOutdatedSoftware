# GetNessusOutdatedSoftware
PowerShell script to extract outdated software packages, plus CVE &amp; CVSS info

## Download & Import the Script
`. .\Get-NessusOutdatedSoftware.ps1`

## Point at Nessus File & Execute (Export to csv)
`Get-NessusOutdatedSoftware '\path\to\Nessus' | export-csv results.csv -notypeinfo`
