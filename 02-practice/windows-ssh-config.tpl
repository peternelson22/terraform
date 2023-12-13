add-content -path c:/users/nelson/.ssh/config -value @"

Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
"@