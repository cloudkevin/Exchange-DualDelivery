function Show-Menu 
{
    param ([string]$Title = 'SADA Dual Delivery Script')

    cls
    Write-Host "==================== $Title ===================="
    Write-Host '================================================'
    Write-Host "1. Set mailbox forwards"
    Write-Host "2. Verify mailbox forwards"
    Write-Host "3. Clear PowerShell Session"
    Write-Host "Q. Quit to Console"
    Write-Host '=============================================='
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
                If ($DoesContactExist -eq $Null) { 
                    Write-Host ""
                    Write-Host "Creating mail contact for $($User)"
                    Write-Host ""
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
                    Write-Host ""
                    Write-Host "Shadow contact already exists. Skipping User: $($User)"
                    Write-Host ""
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