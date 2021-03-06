Function Get-NessusOutdatedSoftware {
param($NessusFile,$ConsolidateCVEAfter=99999,[switch]$IncludeMSBulletins)

    begin
    {

        $NessusXML = New-Object Xml
        $NessusXML.Load((Convert-Path $NessusFile))

        #[xml]$NessusXML = [System.IO.File]::ReadAllLines((Resolve-Path $NessusFile).Path)

        $NessusSoft = $NessusXML.NessusClientData_v2.Report.ReportHost.ReportItem | ?{ ($_.'plugin_output' -like '*Reported version*' -or $_.'plugin_output' -like '*installed version*') -and [int]$_.severity -gt 0 }
        if(-not $IncludeMSBulletins)
        {
        	$NessusSoft = $NessusSoft | ?{ $_.pluginName -notmatch '^MS\d{2}-\d{3}(\s:|:)' }
        }

        if(-not $NessusSoft)
        {
            Write-Warning 'No vuln software found within Nessus file.'
            return
        }

        $Consolidate = @(
            @{Match='Oracle Java SE*';Name='Oracle Java SE'}
            @{Match='Adobe Shockwave Player*';Name='Adobe Shockwave Player'}
            @{Match='Google Chrome*';Name='Google Chrome'}
            @{Match='Adobe Reader*';Name='Adobe Reader'}
            @{Match='Adobe Flash Player*';Name='Adobe Flash Player'}
            @{Match='Adobe Acrobat*';Name='Adobe Acrobat'}
            @{Match='Citrix XenServer Windows Guest Tools Remote DoS';Name='Citrix XenServer Guest Tools'}
            @{Match='Symantec Endpoint Protection Client*';Name='Symantec Endpoint Protection Client'}
            @{Match='*Java JDK*/*JRE*';Name='Java JDK/JRE'}
            @{Match='Juniper Installer Service*';Name='Juniper Installer Service'}
            @{Match='*Microsoft Malware Protection Engine*';Name='Microsoft Malware Protection Engine'}            
            @{Match='VLC*';Name='VLC Media Player'}
            @{Match='VMware Player*';Name='VMware Player'}
            @{Match='WinSCP*';Name='WinSCP'}
            @{Match='Wireshark*';Name='Wireshark'}
            @{Match='Adobe AIR*';Name='Adobe AIR'}
            @{Match='Autodesk Design Review*';Name='Autodesk Design Review'}
            @{Match='Autodesk DWG TrueView*';Name='Autodesk DWG TrueView'}
            @{Match='Cisco Jabber*';Name='Cisco Jabber'}
            @{Match='Cisco WebEx*';Name='Cisco WebEx'}
            @{Match='*Firefox*';Name='Mozilla Firefox'}
            @{Match='Flash Player*';Name='Flash Player'}
            @{Match='*Microsoft Silverlight*';Name='Microsoft Silverlight'}
            @{Match='*Microsoft Malicious Software Removal Tool*';Name='Microsoft Malicious Software Removal Tool'}
            @{Match='*Microsoft Office Web Components*';Name='Microsoft Office Web Components'}
            @{Match='*Microsoft Excel*';Name='Microsoft Excel'}
            @{Match='*Microsoft Word*';Name='Microsoft Word'}
            @{Match='*Microsoft Office*';Name='Microsoft Office'}
            @{Match='Oracle VM VirtualBox*';Name='Oracle VM VirtualBox'}
            @{Match='*Java JRE*';Name='Java JRE'}
            @{Match='Apache Tomcat*';Name='Apache Tomcat'}
            @{Match='Apache*';Name='Apache HTTP Server'}
            @{Match='CodeMeter*';Name='CodeMeter'}
            @{Match='FileZilla Client*';Name='FileZilla Client'}
            @{Match='VMware vCenter*';Name='VMware vCenter Server'}
            @{Match='HP System Management Homepage*';Name='HP System Management Homepage'}
            @{Match='PHP*';Name='PHP'}
            @{Match='Veritas Backup Exec Remote Agent*';Name='Veritas Backup Exec Remote Agent'}
            @{Match='7-Zip*';Name='7-Zip'}
            @{Match='HP Version Control Agent (VCA)*';Name='HP Version Control Agent (VCA)'}
            @{Match='Microsoft SQL Server*';Name='Microsoft SQL Server'}
            @{Match='*.NET Framework*';Name='Microsoft .NET Framework'}
            @{Match='McAfee ePolicy Orchestrator Agent*';Name='McAfee ePolicy Orchestrator Agent'}
            @{Match='IBM Domino*';Name='IBM Domino'}
            @{Match='IBM BigFix Platform*';Name='IBM BigFix Platform'}
            @{Match='IBM WebSphere Application Server*';Name='IBM WebSphere Application Server'}
            @{Match='OpenSSL*';Name='OpenSSL'}          
        )

        $CommonRemovals = @(
        	'Remote Code Execution'
        	'Code Execution'
        	'Multiple Vulnerabilities'
            'Multiple Buffer Overflows'
            'Buffer Overflow'
        	'Insecure Transport'
            'Unsupported Version Detection'
        	','
        )
    }
    
    process
    {
        if($NessusSoft)
        {
            $Interim = foreach($Finding in $NessusSoft)
            {
                # regex split on install version and then only ouput if the line starts with a digit (version number)
                $Software = $Finding.'plugin_output' -split "Remote\sversion.*?:\s(.*?)`n|installed\sversion.*?:\s(.*?)`n|installed\sversion.*?:\s(.*?)`n`n|Reported\sversion.*?:\s(.*?)`n" | Where-Object { $_ -match "^\d" }
                
                foreach($SofItem in $Software)
                {

                    $Out = '' | Select-Object Host, DNSName, Name, CVE, CVSSBasev3, CVSSBasev2, Installed
                    $Out.Host = $Finding.ParentNode.name
                    $hostname = $Finding.ParentNode.HostProperties.SelectSingleNode('tag[@name="host-fqdn"]').'#text'
                    if([String]::IsNullOrWhitespace($hostname))
                    {
                        $Out.DNSName = $hostname
                        }
                        else{
                        $Out.DNSName = '-'
                    }
                    $Out.CVSSBasev3 = $Finding.cvss3_base_score
                    $Out.CVSSBasev2 = $Finding.cvss2_base_score
                    # remove the annoying java multiple vulnerabilities and others
                    $Out.Name = $Finding.pluginName
                    foreach($MatchItem in $Consolidate)
                    {                        
                        if($Finding.pluginName -like $MatchItem.Match)
                        {                        
                            $Out.Name = $MatchItem.Name
                        }
                    }
                    # remove common words to capture everything else
                    foreach($Phrase in $CommonRemovals)
                    {
                        $Out.Name = ($Out.Name -Replace $Phrase).Trim()
                    }

                    $Out.CVE = $Finding.cve
                    $Out.Installed = $SofItem
                    $Out
                }
                Remove-Variable Software
            }
            
            $Interim | Sort-Object 'Software Name', 'Installed Version', Host
        }
    }
        
}