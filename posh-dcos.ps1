
function PascalName($name){
    $parts = $name.Split(" ")
    for($i = 0 ; $i -lt $parts.Length ; $i++){
        $parts[$i] = [char]::ToUpper($parts[$i][0]) + $parts[$i].SubString(1).ToLower();
    }
    $parts -join ""
}
function GetHeaderBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if ([char]::IsWhiteSpace($headerRow[$i]) -and [char]::IsWhiteSpace($headerRow[$i+1])){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function GetHeaderNonBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if (-not [char]::IsWhiteSpace($headerRow[$i])){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function GetColumnInfo($headerRow){
    $lastIndex = 0
    $i = 0
    while ($i -lt $headerRow.Length -and $lastIndex -ge 0){
        $i = GetHeaderBreak $headerRow $lastIndex
        if ($i -lt 0){
            $name = $headerRow.Substring($lastIndex)
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$lastIndex; End=-1}
            break
        } else {
            $name = $headerRow.Substring($lastIndex, $i-$lastIndex)
            $temp = $lastIndex
            $lastIndex = GetHeaderNonBreak $headerRow $i
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$temp; End=$lastIndex}
       }
    }
}
function ParseRow($row, $columnInfo) {
    $values = @{}
    $columnInfo | ForEach-Object {
        if ($_.End -lt 0) {
            $len = $row.Length - $_.Start
        } else {
            $len = $_.End - $_.Start
        }
        $values[$_.Name] = $row.SubString($_.Start, $len).Trim()
    }
    New-Object PSObject -Property $values
}
function ConvertFrom-Cli(){
    begin{
        $positions = $null;
    }
    process {
        if($positions -eq $null) {
            # header row => determine column positions
            $positions  = GetColumnInfo -headerRow $_  #-propertyNames $propertyNames
        } else {
            # data row => output!
            ParseRow -row $_ -columnInfo $positions
        }
    }
    end {
    }
}

#
# .SYNOPSIS
#
#     Complete parameters and arguments to dcos cli
#
function DcosExeCompletion
{
    param($wordToComplete, $commandAst)

    $commandTree = Get-CompletionPrivateData -Key DcosExeCompletionCommandTree
    if ($null -eq $commandTree)
    {
        Set-Alias -Name nct -Value New-CommandTree

        $commandTree = & {
            nct auth "Authenticate to DC/OS cluster" {
                nct -Argument 'login' "log in"
                nct -Argument 'logout' "log out"
                nct -Argument '--help' "help"
                nct -Argument '--info' "info"
            }

            nct config "Manage the DC/OS configuration file" {
                nct set "set <name> <value>"
                nct show "show [<name>]" # TODO - add completion of names
                nct unset "unset <name>" # TODO - add completion of names
                nct validate "validate"
                nct -Argument '--help' "help"
                nct -Argument '--info' "info"
            }

            nct help "Display help information about DC/OS"

            nct job "Deploy and manage jobs in DC/OS" {
                nct add "add <job-file>"
                nct remove "remove <job-id> [--stop-current-job-runs]" {
                    nct -Argument "--stop-current-job-runs" "stop-current-job-runs"
                    # TODO - complete ids, add switch 
                }
                nct show "show <job-id>"
                nct update "update <job-file>"
                nct kill "kill <job-id> [run-id][--all]" {
                    nct -Argument "--all" "all"
                }
                nct run "run <job-id>"
                nct list "list [--json]" {
                    nct -Argument "--json" "json"
                }
                nct schedule "schedule" { 
                    nct add "add <job-id> <schedule-file>"
                    nct show "show <job-id> [--json]" {
                        nct -Argument "--json" "json"
                    }
                    nct remove "remove <job-id> <schedule-id>"
                    nct update "update <job-id> <schedule-file>"
                }
                nct show "show" {
                    nct runs "runs <job-id> [--run-id <run-id>][--json][--q]" {
                        nct -Argument "--run-id" "run-id"
                        nct -Argument "--json" "json"
                        nct -Argument "--q" "q"
                    }
                }
                nct history "history <job-id> [--json][--show-failures]" {
                        nct -Argument "--json" "json"
                        nct -Argument "--show-failures" "show-failures"
                }
                nct -Argument '--help' "help"
                nct -Argument '--version' "version"
                nct -Argument '--config-schema' "config schema"
                nct -Argument '--info' "info"
            }

            nct marathon "Deploy and manage applications to DC/OS" {
                nct -Argument '--help' "help"
                nct -Argument '--config-schema' "config schema"
                nct -Argument '--info' "info"
                
                nct about "about"

                nct app "application" {
                    nct add "add [<app-resource>]"
                    nct list "list" {
                        nct -Argument '--json' "json"
                    }
                    nct remove "remove" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct restart "restart" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct show "show" {
                        nct -Argument '--app-version=' "appversion" # TODO complete version number
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct start "start [--force] <app-id> [<instances>]" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct stop "stop" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct kill "kill" {
                        nct -Argument '--scale' "scale"
                        nct -Argument '--host=' "host" ## TODO complete host
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct update "update [--force] <app-id> [<properties>...]" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct version "version" {
                        nct list "list [--max-count=<maxcount>] <app-id>" {
                            nct -Argument '--max-count=' "max-count"
                            nct {  
                                param($wordToComplete, $commandAst)
                                dcos marathon app list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                            }
                        }
                    }
                }

                nct deployment "deployment" {
                    nct list "list" {
                        nct -Argument "--json" "json"
                    }
                    nct rollback "rollback" {
                        nct {
                            param($wordToComplete, $commandAst)
                            dcos marathon deployment list | ConvertFrom-cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "DeploymentId: $($_.Id)"}
                        }
                    }
                    nct stop "stop" {
                        nct {
                            param($wordToComplete, $commandAst)
                            dcos marathon deployment list | ConvertFrom-cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "DeploymentId: $($_.Id)"}
                        }
                    }
                    nct watch "watch" {
                        nct -Argument '--max-count=' "max-count"
                        nct -Argument '--interval=' "interval"
                        nct {
                            param($wordToComplete, $commandAst)
                            dcos marathon deployment list | ConvertFrom-cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "DeploymentId: $($_.Id)"}
                        }
                    }
                }

                nct group "group"{
                    nct add "add [<group-resource>]"
                    nct list "list" {
                        nct -Argument '--json' "json"
                    }
                    nct scale "scale" {
                        nct -Argument '--force' "force"
                        nct {
                            param($wordToComplete, $commandAst)
                            dcos marathon group list | ConvertFrom-cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "GroupId: $($_.Id)"}
                        }
                    }
                    nct show "show" {
                        nct -Argument '--group-version=' "group-version" ## TODO complete version number
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon group list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "GroupId: $($_.Id)"}
                        }
                    }                    
                    nct remove "remove" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon group list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "AppId: $($_.Id)"}
                        }
                    }
                    nct update "update [--force] <group-id> [<properties>...]" {
                        nct -Argument '--force' "force"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon group list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "GroupId: $($_.Id)"}
                        }
                    }
                }
                
                # TODO add pod-id completion
                nct pod "pod"{
                    nct add "add [<pod-resource>]"
                    nct kill "kill <pod-id> [<instance-ids>...]"
                    nct list "list [--json]" {
                        nct -Argument "--json" "json"
                    }
                    nct remove "remove [--force] <pod-id>" {
                        nct -Argument "--force" "force"
                    }
                    nct show "show <pod-id>"
                    nct update "update [--force] <pod-id>" {
                        nct -Argument "--force" "force"
                    }
                }

                nct task "task" {
                    nct list "list [--json]" {
                        nct -Argument "--json" "json"
                    }
                    nct stop "stop [--wipe] <task-id>" {
                        nct -Argument '--wipe' "wipe"
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon task list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "TaskId: $($_.Id)"}
                        }
                    }     
                    nct show "show <task-id>" {
                        nct {  
                            param($wordToComplete, $commandAst)
                            dcos marathon task list | ConvertFrom-Cli | Where-Object { $_.Id -like "$wordToComplete*" } | ForEach-Object { New-CompletionResult $_.Id -ToolTip "TaskId: $($_.Id)"}
                        }
                    }                 
                }



            }

            nct node "Administer and manage DC/OS cluster nodes" {
                nct -Argument '--help' "help"
                nct -Argument '--info' "info"
                nct -Argument '--json' "json"
                nct log "log [--follow --lines=N --leader --master --mesos-id=<mesos-id> --slave=<slave-id>]"{
                    nct -Argument '--follow' "follow"
                    nct -Argument '--lines=' "lines=N"
                    nct -Argument '--master' "master"
                    nct -Argument '--mesos-id' "mesos-id=<mesos-id>"
                    nct -Argument '--slave' "slave-id=<slave-id>"
                }
                nct ssh " ssh [--option SSHOPT=VAL ...] [--config-file=<path>] [--user=<user>] [--master-proxy] (--leader | --master | --mesos-id=<mesos-id> | --slave=<slave-id>) [<command>]" {
                    nct -Argument '--option' "options SSHOPT=VAL..."
                    nct -Argument '--config-file=' "config-file=<path>"
                    nct -Argument '--user=' "user=<user>"
                    nct -Argument '--master-proxy' "master-proxy"
                    nct -Argument '--leader' "leader"
                    nct -Argument '--master' "master"
                    nct -Argument '--mesos-id' "mesos-id=<mesos-id>"
                    nct -Argument '--slave' "slave-id=<slave-id>"
                }
                nct diagnostics "diagnostics" {
                    nct create "create (<nodes>)..." #TODO complete nodes
                    nct delete "delete <bundle>" #TODO complete bundle
                    nct download "download <bundle> [--location=<location>]" {
                        nct -Argument "--location=" "location=<location>"
                    }
                    nct -Argument "--list" "list"
                    nct -Argument "--status" "status"
                    nct -Argument "--cancel" "cancel"
                    nct -Argument '--json' "json"
                }
            }

            nct package "Install and manage DC/OS software packages" {
                nct -Argument '--help' "help"
                nct -Argument '--config-schema' "config schema"
                nct -Argument '--info' "info"

                nct decribe "describe [--app --cli --config] [--render] [--package-versions] [--options=<file>] [--package-version=<package-version>] <package-name>" {
                    nct -Argument "--app" "app"
                    nct -Argument "--cli" "cli"
                    nct -Argument "--config" "config"
                    nct -Argument "--render" "render"
                    nct -Argument "--package-versions" "package-versions"
                    nct -Argument "--options=" "options=<file>"
                    nct -Argument "--package-version=" "package-version=<package-version>"
                    #TODO complete package-name
                }
                nct install "install [--cli | [--app --app-id=<app-id>]] [--package-version=<package-version>] [--options=<file>] [--yes] <package-name>" {
                    nct -Argument '--cli' "cli"
                    nct -Argument '--app' "app"
                    nct -Argument '--app-id=' "app-id=<app-id>"
                    nct -Argument '--package-version=' "package-version=<package-version>"
                    nct -Argument '--options=' "options=<file>"
                    nct -Argument '--yes' "yes"
                    #TODO complete package-name
                }
                nct list "list [--json --app-id=<app-id> --cli <package-name>]" {
                    nct -Argument '--json' "json"
                    nct -Argument '--cli' "cli"
                    nct -Argument '--app-id=' "app-id=<app-id>"
                    #TODO complete package-name
                }
                nct search "search [--json <query>]" {
                    nct -Argument '--json' "json"
                }
                nct repo {
                    nct add "add [--index=<index>] <repo-name> <repo-url>" {
                        nct -Argument "--index=" "index=<index>"
                    }
                    nct remove "remove <repo-name>" # TODO complete repo-name
                    nct list "list [--json]" {
                        nct -Argument '--json' "json"
                    }
                }
                nct uninstall "uninstall [--cli | [--app --app-id=<app-id> --all]] <package-name>" {
                    nct -Argument '--cli' "cli"
                    nct -Argument '--app' "app"
                    nct -Argument '--app-id=' "app-id=<app-id>"
                    nct -Argument '--all' "all"
                    #TODO complete package-name
                }
                nct update "update"
            }

            nct service "Manage DC/OS services"{
                nct -Argument '--help' "help"
                nct -Argument '--info' "info"
                nct -Argument '--completed' "completed"
                nct -Argument '--inactive' "inactive"
                nct -Argument '--json' "json"
                nct log "log [--follow --lines=N --ssh-config-file=<path>] <service> [<file>]"{
                    nct -Argument '--follow' "follow"
                    nct -Argument '--lines=' "lines=N"
                    nct -Argument '--ssh-config-file' "ssh-config-file=<path>"
                    # TODO complete service
                    # TODO complete file
                }
                nct shutdown "shutdown <service-id>" # TODO complete service-id
            }

            nct task "Manage DC/OS tasks" {
                nct -Argument '--help' "help"
                nct -Argument '--info' "info"
                nct -Argument '--completed' "completed"
                nct -Argument '--json' "json"
                nct log "log" {
                    nct -Argument '--completed' "--completed"
                    nct -Argument '--follow' "--follow"
                    nct -Argument '--lines=' "--lines=N"
                    nct {  
                            param($wordToComplete, $commandAst)
                            # handle output with task ids in "===>.... <===" form (with other lines interspersed)
                            dcos task ls | `
                                Where-Object { $_.StartsWith("===>")} | ` 
                                ForEach-Object {$_.SubString(5, $_.IndexOf("<===", 7) - 6)} | `
                                Where-Object { $_ -like "$wordToComplete*" } | `
                                ForEach-Object { New-CompletionResult $_ -ToolTip "TaskId: $_"}
                        }
                    # TODO handle file completion
                }
                nct ls "ls [--long --completed] [<task>] [<path>]" {
                    nct -Argument "--long" "--long"
                    nct -Argument "--completed" "--completed"
                     nct {
                        param($wordToComplete, $commandAst)
                            # handle output with task ids in "===>.... <===" form (with other lines interspersed)
                            dcos task ls | `
                                Where-Object { $_.StartsWith("===>")} | ` 
                                ForEach-Object {$_.SubString(5, $_.IndexOf("<===", 7) - 6)} | `
                                Where-Object { $_ -like "$wordToComplete*" } | `
                                ForEach-Object { New-CompletionResult $_ -ToolTip "TaskId: $_"}
                    }
                    # TODO handle path completion 
                }
            }
        }

        Set-CompletionPrivateData -Key DcosExeCompletionCommandTree -Value $commandTree
    }

    Get-CommandTreeCompletion $wordToComplete $commandAst $commandTree
}



Register-ArgumentCompleter `
    -Command 'dcos' `
    -Native `
    -Description 'Complete arguments to dcos.exe' `
    -ScriptBlock $function:DcosExeCompletion