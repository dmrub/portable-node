' Portable Node.js install script
' Author: Dmitri Rubinstein
' Version: 1.0
' 13.03.2013
'
'Copyright (c) 2013
'              DFKI - German Research Center for Artificial Intelligence
'              www.dfki.de
'
'Permission is hereby granted, free of charge, to any person obtaining a copy of
'this software and associated documentation files (the "Software"), to deal in
'the Software without restriction, including without limitation the rights to
'use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
'of the Software, and to permit persons to whom the Software is furnished to do
' so, subject to the following conditions:
'
'The above copyright notice and this permission notice shall be included in all
'copies or substantial portions of the Software.
'
'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
'SOFTWARE.

' Declare all global variables
Dim FSO, WshShell, WshEnv, thisDir, VERBOSE

' Create objects that will be shared by all following code
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = Wscript.CreateObject("Wscript.Shell")
Set WshEnv = WshShell.Environment("PROCESS")
Set stdout = FSO.GetStandardStream(1)
Set stderr = FSO.GetStandardStream(2)

thisDir = FSO.GetParentFolderName(Wscript.ScriptFullName)
If UCase(Right(thisDir, 4)) = "\BIN" Then
    baseDir = Left(thisDir, Len(thisDir)-4)
Else
    baseDir = thisDir
End If

' Check thisDir for existence
Assert FSO.FolderExists(thisDir), "Bootstrap: There is no directory " & thisDir & ", something is wrong"

' Set VERBOSE to True if we Wscript.Echo will print to console
VERBOSE = InConsole()

' Process command-line arguments
Set args = Wscript.Arguments

Dim nodeVersion, nodeArch, nodeURL, nodeMSIFile

nodeVersion = "0.10.0"
nodeArch = "x86"
forceInstall = False

If args.Count > 0 Then
    If args(0) = "-h" Or args(0) = "-?" Or _
        args(0) = "--help" Or args(0) = "/?" Then
        Wscript.Echo "Node Portable Environment Setup Script" & vbCrLf & _
                    "Usage : " & Wscript.ScriptName & " [ /? ] [/version:node-version /arch:x86|x86_64|32|64 /force]" & vbCrLf & vbCrLf & _
                    "Options: /version:node-version         select node version to download (default : " & nodeVersion & ")" & vbCrLf & _
                    "         /arch:x86|x64|x86_64|32|64    select node architecture to download (default : " & nodeArch & ")" & vbCrLf & _
                    "         /force                        force download and installation" & vbCrLf & _
                    "         /?                            print this" & vbCrLf
        Wscript.Quit
    End If
    If args.Named.Exists("version") Then
        nodeVersion = args.Named.Item("version")
    End If
    If args.Named.Exists("arch") Then
        nodeArch = args.Named.Item("arch")
    End If
    If nodeArch = "x86_64" Then nodeArch = "x64"
    If nodeArch = "32" Then nodeArch = "x86"
    If nodeArch = "64" Then nodeArch = "x64"
    ' Check
    If nodeArch <> "x86" And nodeArch <> "x64" Then
        Error "Unsupported architecture: " & nodeArch, 1
    End If
    
    For i = 0 to args.Count-1
        arg = args.Item(i)
        If arg = "/force" Or arg = "-force" Then forceInstall = True
    Next
    
End If

' Setup paths
nodePrefix = "node-v" & nodeVersion & "-" & nodeArch
nodeMSIFile = nodePrefix & ".msi"
If nodeArch = "x86" Then
    nodeURL = "http://nodejs.org/dist/" & "v" & nodeVersion & "/" & nodeMSIFile
Else
    nodeURL = "http://nodejs.org/dist/" & "v" & nodeVersion & "/x64/" & nodeMSIFile
End If

nodeBaseDirRel = "share\nodejs" 'relative to baseDir
nodeBaseDir = FSO.BuildPath(baseDir, nodeBaseDirRel)
nodeMSIPath = FSO.GetAbsolutePathName(FSO.BuildPath(nodeBaseDir, nodeMSIFile))
nodeInstallPathRel = nodeBaseDirRel & "\" & nodePrefix ' relative to baseDir
nodeInstallPath = FSO.GetAbsolutePathName(FSO.BuildPath(baseDir, nodeInstallPathRel))

Wscript.Echo "Download and install locally node.js version: " & nodeVersion & " for architecture: " & nodeArch

' Download node.js
CreateFolderTree(nodeBaseDir)
If Not FSO.FileExists(nodeMSIPath) Or forceInstall Then
    If Not Download(nodeURL, nodeMSIPath) Then Error "Could not download URL: " & nodeURL, 2
Else
    Echo "File " & nodeMSIPath & " already exists, use /force to reload."
End If

' Extract node.js
nodeExePath = FSO.BuildPath(nodeInstallPath, "nodejs")
nodeExePathRel = FSO.BuildPath(nodeInstallPathRel, "nodejs")
nodeExeFile = FSO.BuildPath(nodeExePath, "node.exe")
nodeExeFileRel = FSO.BuildPath(nodeExePathRel, "node.exe")
If Not FSO.FileExists(nodeExeFile) Or forceInstall Then
    Dim extractCmd

    extractCmd = "msiexec.exe /a " & nodeMSIPath & " /qn TARGETDIR=" & nodeInstallPath
    
    If FSO.FolderExists(nodeInstallPath) Then
        Echo "Deleting folder: " & nodeInstallPath
        FSO.DeleteFolder(nodeInstallPath)
    End If

    Echo "Running: " & extractCmd
    result = WshShell.Run(extractCmd, 1, True)
    Echo "Result : " & result
    If result <> 0 Then Error "Could not install node.js", 3
    
    ' Delete MSI file produced by installer
    Dim msiFile2
    msiFile2 = FSO.BuildPath(nodeInstallPath, nodeMSIFile)
    If FSO.FileExists(msiFile2) Then
        Echo "Deleting file: " & msiFile2
        FSO.DeleteFile(msiFile2)
    End If
Else
    Echo "File " & nodeExeFile & " already exists, use /force to reinstall."
End If

' Create node launch script
Dim Script
scriptFile = FSO.BuildPath(baseDir, nodePrefix & ".bat")
Set script = FSO.CreateTextFile(scriptFile, True)
script.WriteLine("@echo off")
script.WriteLine("PATH %~dp0" & nodeExePathRel & ";%PATH%")
script.WriteLine("set NODE_PATH=%~dp0" & nodeExePathRel)
script.WriteLine("%~dp0" & nodeExeFileRel & " %*")
script.Close
Echo "Created node launch script: " & scriptFile

' Create git bash launch script
gitShell = GetMsysGitShell()
If gitShell <> "" Then
    scriptFile = FSO.BuildPath(baseDir, "git-bash-" & nodePrefix & ".bat")
    Set script = FSO.CreateTextFile(scriptFile, True)
    script.WriteLine("@echo off")
    script.WriteLine("PATH %~dp0" & nodeExePathRel & ";%PATH%")
    script.WriteLine("set NODE_PATH=%~dp0" & nodeExePathRel)
    script.WriteLine("if not exist %~dp0\share\git-bash-profile.sh (")
    script.WriteLine("  mkdir %~dp0\share")
    script.WriteLine("  echo source /etc/profile > %~dp0\share\git-bash-profile.sh")
    script.WriteLine(")")
    script.WriteLine("""" & gitShell & """ --rcfile %~dp0\share\git-bash-profile.sh")
    script.Close

    Echo "Created git bash launch script: " & scriptFile
End If

Wscript.Echo "Installation finished"

'Cygwin not yet supported
'cygwinShell = GetCygwinShell()

Wscript.Quit

' Help procedures and functions

' Download url and save to path
' http://www.codeproject.com/Tips/506439/Downloading-files-with-VBScript
Function Download(url, path)
    Dim objHTTP, objFSO
    ' Get file name from URL.
    ' http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab -> wsusscn2.cab

    Echo "Download URL: " & url & " to: " & path

    ' Create an HTTP object
    Set objHTTP = CreateObject( "WinHttp.WinHttpRequest.5.1" )

    ' Download the specified URL
    objHTTP.Open "GET", url, False
    ' Use HTTPREQUEST_SETCREDENTIALS_FOR_PROXY if user and password is for proxy, not for download the file.
    ' objHTTP.SetCredentials "User", "Password", HTTPREQUEST_SETCREDENTIALS_FOR_SERVER
    objHTTP.Send

    Set objFSO = CreateObject("Scripting.FileSystemObject")
    If objFSO.FileExists(path) Then
        objFSO.DeleteFile(path)
    End If

    If objHTTP.Status = 200 Then
        Dim objStream
        Set objStream = CreateObject("ADODB.Stream")
        With objStream
            .Type = 1 'adTypeBinary
            .Open
            .Write objHTTP.ResponseBody
            .SaveToFile path
            .Close
        End With
        set objStream = Nothing
    Else
        stderr.WriteLine "Could not download: " & url & " : " & objHTTP.Status & " " & objHTTP.StatusText
    End If

    If objFSO.FileExists(path) Then
        Echo "Download to `" & path & "` completed successfully."
        Download = True
    Else
        Download = False
    End If
End Function

Sub CreateFolderTree(folderPath)
    Dim objFSO, parent
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    parent = objFSO.GetParentFolderName(folderPath)
    If Len(parent) > 0 And Not objFSO.FolderExists(parent) Then
        CreateFolderTree(parent)
    End If
    If Not objFSO.FolderExists(folderPath) Then
        objFSO.CreateFolder(folderPath)
    End If
End Sub

' Detect MsysGit
Function GetMsysGitShell()
    Dim GIT_DIR, GIT_SHELL
    GIT_SHELL = ""
    GIT_DIR = RegRead("HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1\InstallLocation", "")
    If GIT_DIR <> "" Then
      GIT_SHELL = FSO.BuildPath(GIT_DIR, "bin\sh.exe")
    Else
      ' Check on 64-bit Windows
      GIT_DIR = RegRead("HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1\InstallLocation", "")
      If GIT_DIR <> "" Then
        GIT_SHELL = FSO.BuildPath(GIT_DIR, "bin\sh.exe")
      End If
    End If
    GetMsysGitShell = GIT_SHELL
End Function

' Detect Cygwin
Function GetCygwinShell()
    Dim CYGWIN_DIR, CYGWIN_SHELL
    CYGWIN_SHELL = ""
    CYGWIN_DIR = RegRead("HKLM\Software\Cygnus Solutions\Cygwin\mounts v2\/\native", "")
    If CYGWIN_DIR = "" Then
      CYGWIN_DIR = RegRead("HKLM\Software\Wow6432Node\Cygwin\setup\rootdir", "")
    End If
    If CYGWIN_DIR <> "" Then
      CYGWIN_SHELL = FSO.BuildPath(CYGWIN_DIR, "bin\bash.exe")
    End If
    GetCygwinShell = CYGWIN_SHELL
End Function

' Checks whether the script is started in text console (through CSCRIPT.EXE)
' or not
Function InConsole()
  InConsole = (UCase(Left(FSO.GetFileName(Wscript.FullName),7))  = "CSCRIPT")
End Function

' Read registry key, return defaultValue if the key with specified name
' does not exists
Function RegRead(key, defaultValue)
  RegRead = defaultValue
  On Error Resume Next
  RegRead = WshShell.RegRead(key)
End Function

Function WinToMsysPath(path)
  WinToMsysPath = Replace(Replace(path, "\", "/"), " ", "\ ")
End Function

' Echoes message if the script is in VERBOSE mode
' VERBOSE mode will be set at script start through call to InConsole
Sub Echo(msg)
    If VERBOSE Then Wscript.Echo msg
End Sub

' Show error message in message box or console and exit
Sub Error(msg, exitCode)
    If InConsole() Then
        stderr.WriteLine "Setup Error: " & msg 
    Else
        MsgBox msg, vbExclamation, "Setup Error"
    End If
    Wscript.Quit exitCode
End Sub

Sub Assert(cond, msg)
  If Not cond Then
    Error msg, 1
  End If
End Sub

' If VBasic error was happened exit script
Sub CheckVBError(msg,exitCode)
  If Err.Number <> 0 Then
    MsgBox msg & vbCrLf & Err.Description,vbExclamation, "Error"
    Wscript.Quit exitCode
  End If
End Sub
