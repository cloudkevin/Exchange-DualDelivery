# PowerShell - Dual Delivery

## Script Requirements
```
* Account used must have Exchange admin rights for forwarding
* A directory account with full administrative access over the appropriate OU structure of the AD server.
  (This tool modifies user objects)
* OU for shadow contacts to be created in
* Client to confirm modules can be imported and run on the server(s) SADA has access to
```


## Required User Inputs
###### When the script is executed you will be prompted for multiple required inputs. The required formats are listed as examples below each description.
```
* Forwarding Domain = The forwarding domain to be used
tempdomain.com
* Path to CSV = The alias address/domain used for forwarding
* C:\EnterCSVPathHere.csv
* Organizational Unit = The OU shadow contact cards will be created in
* OU=XX,DC=XX,DC=COM
```


## Prerequisites
```
* Additional domain created and verified as a secondary domain in G Suite for forwarding
* For example: g.domain.com, forward.domain.com, routing.domain.com
* MX records on the secondary domain updated to Google
* SPF record(s) updated to include Google
* Aliases added to G Suite user profiles for forwarding
* Via the user provisioning tool or GAM
* Update inbound gateway(s) in G Suite (IPs of the Exchange servers)
```