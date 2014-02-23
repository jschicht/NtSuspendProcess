A simpel program using native api in ntdll.dll that can suspend/resume a given process by specifying its PID or name. 

Examples:
Suspend process with ID 2366:
NtSuspendProcess.exe -pid 2366

Suspend all processes with name notepad.exe:
NtSuspendProcess.exe -name notepad.exe

Resume process with ID 2366:
NtSuspendProcess.exe -rpid 2366

Resume all suspended processes with name notepad.exe:
NtSuspendProcess.exe -rname notepad.exe
