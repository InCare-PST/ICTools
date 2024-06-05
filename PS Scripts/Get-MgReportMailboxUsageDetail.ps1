              [OutputType([System.Boolean])]
              [CmdletBinding(DefaultParameterSetName='Get', PositionalBinding=$false)]
              param(
                  [Parameter(ParameterSetName='Get', Mandatory)]
                  [ArgumentCompleter({'D7', 'D30', 'D90', 'D180'})]
                  [Microsoft.Graph.PowerShell.Category('Path')]
                  [System.String]
                  # Usage: period='{period}'
                  ${Period},

                  [Parameter(ParameterSetName='GetViaIdentity', Mandatory, ValueFromPipeline)]
                  [Microsoft.Graph.PowerShell.Category('Path')]
                  [Microsoft.Graph.PowerShell.Models.IReportsIdentity]
                  # Identity Parameter
                  # To construct, see NOTES section for INPUTOBJECT properties and create a hash table.
                  ${InputObject},

                  [Parameter(Mandatory)]
                  [ValidateNotNull()]
                  [Microsoft.Graph.PowerShell.Category('Body')]
                  [System.String]
                  # Path to write output file to
                  ${OutFile},

                  [Parameter()]
                  [Alias('RHV')]
                  [Microsoft.Graph.PowerShell.Category('Body')]
                  [System.String]
                  # Optional Response Headers Variable.
                  ${ResponseHeadersVariable},

                  [Parameter(DontShow)]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Management.Automation.SwitchParameter]
                  # Wait for .NET debugger to attach
                  ${Break},

                  [Parameter(ValueFromPipeline)]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Collections.IDictionary]
                  # Optional headers that will be added to the request.
                  ${Headers},

                  [Parameter(DontShow)]
                  [ValidateNotNull()]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [Microsoft.Graph.PowerShell.Runtime.SendAsyncStep[]]
                  # SendAsync Pipeline Steps to be appended to the front of the pipeline
                  ${HttpPipelineAppend},

                  [Parameter(DontShow)]
                  [ValidateNotNull()]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [Microsoft.Graph.PowerShell.Runtime.SendAsyncStep[]]
                  # SendAsync Pipeline Steps to be prepended to the front of the pipeline
                  ${HttpPipelinePrepend},

                  [Parameter()]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Management.Automation.SwitchParameter]
                  # Returns true when the command succeeds
                  ${PassThru},

                  [Parameter(DontShow)]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Uri]
                  # The URI for the proxy server to use
                  ${Proxy},

                  [Parameter(DontShow)]
                  [ValidateNotNull()]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Management.Automation.PSCredential]
                  # Credentials for a proxy server to use for the remote call
                  ${ProxyCredential},

                  [Parameter(DontShow)]
                  [Microsoft.Graph.PowerShell.Category('Runtime')]
                  [System.Management.Automation.SwitchParameter]
                  # Use the default credentials for the proxy
                  ${ProxyUseDefaultCredentials}
              )

              begin {
                  try {
                      $outBuffer = $null
                      if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                          $PSBoundParameters['OutBuffer'] = 1
                      }
                      $parameterSet = $PSCmdlet.ParameterSetName

                      $mapping = @{
                          Get = 'Microsoft.Graph.Reports.private\Get-MgReportMailboxUsageDetail_Get';
                          GetViaIdentity = 'Microsoft.Graph.Reports.private\Get-MgReportMailboxUsageDetail_GetViaIdentity';
                      }
                      $cmdInfo = Get-Command -Name $mapping[$parameterSet]
                      [Microsoft.Graph.PowerShell.Runtime.MessageAttributeHelper]::ProcessCustomAttributesAtRuntime($cmdInfo, $MyInvocation, $parameterSet, $PSCmdlet)
                      $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(($mapping[$parameterSet]), [System.Management.Automation.CommandTypes]::Cmdlet)
                      $scriptCmd = {& $wrappedCmd @PSBoundParameters}
                      $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
                      $steppablePipeline.Begin($PSCmdlet)
                  } catch {

                      throw
                  }
              }

              process {
                  try {
                      $steppablePipeline.Process($_)
                  } catch {

                      throw
                  }

              }
              end {
                  try {
                      $steppablePipeline.End()

                  } catch {

                      throw
                  }
              }

