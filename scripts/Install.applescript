set appName to "SitWatcher"
set scriptPath to POSIX path of (path to me)
set parentPath to do shell script "dirname " & quoted form of scriptPath
set sourcePath to parentPath & "/" & appName & ".app"
set targetPath to "/Applications/" & appName & ".app"

-- Remove quarantine from source
do shell script "xattr -dr com.apple.quarantine " & quoted form of sourcePath & " 2>/dev/null || true"

-- Remove old version
do shell script "rm -rf " & quoted form of targetPath with administrator privileges

-- Copy to Applications
do shell script "cp -R " & quoted form of sourcePath & " " & quoted form of targetPath with administrator privileges

-- Remove quarantine from installed app
do shell script "xattr -dr com.apple.quarantine " & quoted form of targetPath & " 2>/dev/null || true"

-- Launch
do shell script "open " & quoted form of targetPath

display dialog "SitWatcher 已安装并启动！" buttons {"好的"} default button 1 with icon note
