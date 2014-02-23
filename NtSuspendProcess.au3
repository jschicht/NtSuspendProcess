#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Suspend and resume processes by PID or name
#AutoIt3Wrapper_Res_Description=Suspend and resume processes by PID or name
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; by Joakim Schicht
#include <WinAPI.au3>
Global Const $tagOBJECTATTRIBUTES = "ulong Length;hwnd RootDirectory;ptr ObjectName;ulong Attributes;ptr SecurityDescriptor;ptr SecurityQualityOfService"
Global Const $OBJ_CASE_INSENSITIVE = 0x00000040
Global Const $tagUNICODESTRING = "ushort Length;ushort MaximumLength;ptr Buffer"

Select
	Case $cmdline[0] <> 2
		_ShowHelp()
		$list = ProcessList()
		ConsoleWrite(@CRLF)
		ConsoleWrite("Found processes:" & @CRLF)
		For $i = 1 To $list[0][0]
			ConsoleWrite($list[$i][0] & "   " & $list[$i][1] & @CRLF)
		Next
	Case $cmdline[1] = "-rpid"
		_SetPrivilege("SeDebugPrivilege")
		$Test = _NtOpenProcess($cmdline[2])
		If @error Then
			ConsoleWrite("Error" & @CRLF)
		Else
			_NtResumeProcess($Test)
			If Not @error Then ConsoleWrite("Process resumed" & @CRLF)
		EndIf
	Case $cmdline[1] = "-rname"
		_SetPrivilege("SeDebugPrivilege")
		$list = ProcessList($cmdline[2])
		If $list[0][0] = 0 Then
			ConsoleWrite("Process name was not found: " & $cmdline[2] & @CRLF)
			Exit
		EndIf
		For $i = 1 To $list[0][0]
			ConsoleWrite("Found: " & $list[$i][0] & @CRLF)
			$Test = _NtOpenProcess($list[$i][1])
			If @error Then
				ConsoleWrite("Error" & @CRLF)
			Else
				_NtResumeProcess($Test)
				If @error Then
					ContinueLoop
				Else
					ConsoleWrite("Process resumed" & @CRLF)
				EndIf
			EndIf
			Exit
		Next
	Case $cmdline[1] = "-pid"
		_SetPrivilege("SeDebugPrivilege")
		$Test = _NtOpenProcess($cmdline[2])
		If @error Then
			ConsoleWrite("Error" & @CRLF)
		Else
			_NtSuspendProcess($Test)
			If Not @error Then ConsoleWrite("Process suspended" & @CRLF)
		EndIf
	Case $cmdline[1] = "-name"
		_SetPrivilege("SeDebugPrivilege")
		$list = ProcessList($cmdline[2])
		If $list[0][0] = 0 Then
			ConsoleWrite("Process name was not found: " & $cmdline[2] & @CRLF)
			Exit
		EndIf
		For $i = 1 To $list[0][0]
			ConsoleWrite("Found: " & $list[$i][0] & @CRLF)
			$Test = _NtOpenProcess($list[$i][1])
			If @error Then
				ConsoleWrite("Error" & @CRLF)
			Else
				_NtSuspendProcess($Test)
				If @error Then
					ContinueLoop
				Else
					ConsoleWrite("Process suspended" & @CRLF)
				EndIf
			EndIf
			Exit
		Next
	Case Else
		_ShowHelp()
		$list = ProcessList()
		ConsoleWrite(@CRLF)
		ConsoleWrite("Found processes:" & @CRLF)
		For $i = 1 To $list[0][0]
			ConsoleWrite($list[$i][0] & "   " & $list[$i][1] & @CRLF)
		Next
EndSelect

Func _ShowHelp()
	ConsoleWrite("The syntax is: NtSuspendProcess.exe -switch param1" & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("Examples:" & @CRLF)
	ConsoleWrite("Suspend process with ID 2366:" & @CRLF)
	ConsoleWrite("NtSuspendProcess.exe -pid 2366" & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("Suspend all processes with name notepad.exe:" & @CRLF)
	ConsoleWrite("NtSuspendProcess.exe -name notepad.exe" & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("Resume process with ID 2366:" & @CRLF)
	ConsoleWrite("NtSuspendProcess.exe -rpid 2366" & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("Resume all suspended processes with name notepad.exe:" & @CRLF)
	ConsoleWrite("NtSuspendProcess.exe -rname notepad.exe" & @CRLF)
EndFunc

Func _NtResumeProcess($PID)
	Local $aCall = DllCall("ntdll.dll", "int", "NtResumeProcess", "dword", $PID)
    If Not NT_SUCCESS($aCall[0]) Then
        ConsoleWrite("Error in NtResumeProcess: " & Hex($aCall[0], 8) & @CRLF)
        Return SetError(1, 0, $aCall[0])
	Else
		Return True
	EndIf
EndFunc

Func _NtSuspendProcess($hProc)
	Local $aCall = DllCall("ntdll.dll", "int", "NtSuspendProcess", "handle", $hProc)
    If Not NT_SUCCESS($aCall[0]) Then
        ConsoleWrite("Error in NtSuspendProcess: " & Hex($aCall[0], 8) & @CRLF)
        Return SetError(1, 0, $aCall[0])
	Else
		Return True
	EndIf
EndFunc

Func _NtOpenProcess($PID)
    Local $sOA = DllStructCreate($tagOBJECTATTRIBUTES)
    DllStructSetData($sOA, "Length", DllStructGetSize($sOA))
    DllStructSetData($sOA, "RootDirectory", 0)
    DllStructSetData($sOA, "ObjectName", 0)
    DllStructSetData($sOA, "Attributes", $OBJ_CASE_INSENSITIVE)
    DllStructSetData($sOA, "SecurityDescriptor", 0)
    DllStructSetData($sOA, "SecurityQualityOfService", 0)

    Local $ClientID = DllStructCreate("dword_ptr UniqueProcessId;dword_ptr UniqueThreadId")
    DllStructSetData($ClientID, "UniqueProcessId", $PID)
    DllStructSetData($ClientID, "UniqueThreadId", 0)

    Local $aCall = DllCall("ntdll.dll", "hwnd", "NtOpenProcess", "handle*", 0, "dword", 0x001F0FFF, "struct*", $sOA, "struct*", $ClientID)
    If Not NT_SUCCESS($aCall[0]) Then
        ConsoleWrite("Error in NtOpenProcess: " & Hex($aCall[0], 8) & @CRLF)
        Return SetError(1, 0, $aCall[0])
    Else
        Return $aCall[1]
    EndIf
EndFunc

Func NT_SUCCESS($status)
    If 0 <= $status And $status <= 0x7FFFFFFF Then
        Return True
    Else
        Return False
    EndIf
EndFunc

Func _SetPrivilege($Privilege)
    Local $tagLUIDANDATTRIB = "int64 Luid;dword Attributes"
    Local $count = 1
    Local $tagTOKENPRIVILEGES = "dword PrivilegeCount;byte LUIDandATTRIB[" & $count * 12 & "]" ; count of LUID structs * sizeof LUID struct
    Local $TOKEN_ADJUST_PRIVILEGES = 0x20
    Local $SE_PRIVILEGE_ENABLED = 0x2

    Local $curProc = DllCall("kernel32.dll", "ptr", "GetCurrentProcess")
	Local $call = DllCall("advapi32.dll", "int", "OpenProcessToken", "ptr", $curProc[0], "dword", $TOKEN_ALL_ACCESS, "ptr*", "")
    If Not $call[0] Then Return False
    Local $hToken = $call[3]

    $call = DllCall("advapi32.dll", "int", "LookupPrivilegeValue", "str", "", "str", $Privilege, "int64*", "")
    Local $iLuid = $call[3]

    Local $TP = DllStructCreate($tagTOKENPRIVILEGES)
	Local $TPout = DllStructCreate($tagTOKENPRIVILEGES)
    Local $LUID = DllStructCreate($tagLUIDANDATTRIB, DllStructGetPtr($TP, "LUIDandATTRIB"))

    DllStructSetData($TP, "PrivilegeCount", $count)
    DllStructSetData($LUID, "Luid", $iLuid)
    DllStructSetData($LUID, "Attributes", $SE_PRIVILEGE_ENABLED)

    $call = DllCall("advapi32.dll", "int", "AdjustTokenPrivileges", "ptr", $hToken, "int", 0, "ptr", DllStructGetPtr($TP), "dword", DllStructGetSize($TPout), "ptr", DllStructGetPtr($TPout), "dword*", 0)
	$lasterror = _WinAPI_GetLastError()
	If $lasterror <> 0 Then
		ConsoleWrite("AdjustTokenPrivileges: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	EndIf
    DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
    Return ($call[0] <> 0) ; $call[0] <> 0 is success
EndFunc