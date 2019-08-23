function Show-Menu 
{
    param ([string]$Title = 'SADA Dual Delivery Script')

    cls
    Write-Output "==================== $Title ===================="
    Write-Output '==================================================================='
    Write-Output "1. Set mailbox forwards"
    Write-Output "2. Verify mailbox forwards"
    Write-Output "3. Clear PowerShell Session"
    Write-Output "Q. Quit to Console"
    Write-Output '=================================================================='
}

function Clear-Session
{
    Get-PSSession | Where{$_.ConfigurationName -match "Microsoft.Exchange"} | Remove-PSSession 
}

$hostname = Read-Host -Prompt "Enter the hostname of the Exchange server"

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$hostname/PowerShell/ -Authentication Kerberos -Credential $UserCredential 
Import-PSSession $Session

$tempDomain = Read-Host -Prompt "Enter the forwarding domain"
$csvPath = Read-Host -Prompt "Enter full CSV path"
$contactOU = Read-Host -Prompt "Enter OU for mail contacts(OU=XX,DC=XX,DC=COM)"

$GSuiteUsers = import-csv $csvPath


Import-Module ActiveDirectory
Start-Sleep -Seconds 10



do {
    Show-Menu
    $input = Read-Host -Prompt "What would you like to do?"
    switch($input)
    {
        '1'
        {
            Foreach ($Member in $GSuiteUsers) { 
                $User = $($Member.email)
                $SamAccountName = $($Member.SamAccountName)
                $Lastname = $($Member.Lastname)
                $FirstName = $($Member.GivenName)

            # If the contact doesn't exist, create it

                $Externaladdress = "$($User.split('@')[0])@$($tempDomain)"
                $DoesContactExist = Get-MailContact -Identity $Externaladdress -ErrorAction SilentlyContinue
                If ($Null -eq $DoesContactExist) { 
                    Write-Output ""
                    Write-Output "Creating mail contact for $($User)"
                    Write-Output ""
                    $Args1 = @{ 
                        Name                 = "$($SamAccountName) (GSuite contact)"
                        Alias                = "$($SamAccountName).GSuite-contact"

            # OU where the contacts are stored.

                        OrganizationalUnit   = $contactOU 
                        ExternalEmailAddress = $Externaladdress
                        DisplayName          = "$($Lastname), $($FirstName) - GSuite contact"
                    }

            # Create the contact using the arguments above.
            # Hide the contact from the address book.

                    New-MailContact @Args1
                    $Args2 = @{ 
                        Identity = $Externaladdress
                        HiddenFromAddressListsEnabled = $True 
                    }

            # Arguments for forwarding messages to G-Suite.
            # Setup forwarding to send messages to G-Suite account using the arguments above.

                    Set-MailContact @Args2 
                    $Args3 = @{ 
                        Identity = "$($SamAccountName)"
                        ForwardingAddress = "$($SamAccountName).GSuite-contact"
                        DeliverToMailboxAndForward = $true 
                    }
                    Set-Mailbox @Args3 
                }
                else {
                    Write-Output ""
                    Write-Output "Shadow contact already exists. Skipping User: $($User)"
                    Write-Output ""
                }
            }
        }

        '2'
        {
            $GSuiteUsers | ForEach {Get-Mailbox -Identity $User | Select WindowsEmailAddress,ForwardingAddress,DeliverToMailboxAndForward} >> ddVerify.csv
        }
        '3'
        {
            Clear-Session
        }

        'q'
        
        {
            return
        }
        }
        pause
}
until ($input -eq 'q')