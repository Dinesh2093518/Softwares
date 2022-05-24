Set-ExecutionPolicy Bypass -Scope Process -Force;
#Installing PowerShell-7
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.2.2/PowerShell-7.2.2-win-x86.msi -OutFile .\PowerShell7.2.2winx86.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I PowerShell7.2.2winx86.msi /quiet'; rm .\PowerShell7.2.2winx86.msi;

#Installing AzureCLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi;

#Installing Chocolaty
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

#Installing kubectl
choco install kubernetes-cli -y
cd ~
mkdir .kube
cd .kube
New-Item config -type file
cd ~

#Installing helm
choco install kubernetes-helm -y;

#Installing chrome
choco install googlechrome -y;

#Installing docker desktop
choco install docker-desktop --pre -y;
#net localgroup docker-users "TCAdmin123" /ADD;

#Installing DotNet
#Invoke-WebRequest -Uri https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1 -OutFile .\dotnet-install.ps1;
#.\dotnet-install.ps1;
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/ae1014c7-a005-4a0e-9062-b6f3056ded09/da5d731f5ead9e385427a77412b88fb0/dotnet-hosting-6.0.5-win.exe -OutFile .\DotNet.exe;
.\DotNet.exe /install /quiet /norestart
