# Process Memory Access

## Open Process

There is [`OpenProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684320%28v=vs.85%29.aspx) WinAPI function that allows to get a [**handle**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724457%28v=vs.85%29.aspx) of the process with specified [**process identifier**](https://en.wikipedia.org/wiki/Process_identifier) (PID). When you known a process's handle, you can access process's internals for example process's memory via WinAPI functions. 

All processes in Windows OS are special kind of objects. Objects are high-level abstractions for OS resources, such as a file, process or thread. All objects have an unified structure and they consist of header and body. Header contains meta information about an object that is used by [**Object Manager**](https://en.wikipedia.org/wiki/Object_Manager_%28Windows%29). Body contains object-specific data.

Windows [**security model**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374876%28v=vs.85%29.aspx) is responsible for controlling ability of a process to access objects or to perform various system administration tasks. The security model requires a process to have special privileges for accessing another process with `OpenProcess` function. [**Access token**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374909%28v=vs.85%29.aspx) is an object that allows to manipulate of security attributes of a process. The access token can be used to grant necessary privileges for usage `OpenProcess` function.

This is a common algorithm of opening target process with `OpenProcess` function:

1. Get object's handle of a current process.
2. Get access token of the current process.
3. Enable `SE_DEBUG_NAME` privilege for the current process by affecting process's access token. The privilege allows process to debug other applications.
4. Get object's handle of the target process.

This is a source of the [`OpenProcess.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/OpenProcess.cpp) application that implements the opening process algorithm:
```C++
#include <windows.h>
#include <stdio.h>

BOOL SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
    TOKEN_PRIVILEGES tp;
    LUID luid;

    if (!LookupPrivilegeValue(NULL, lpszPrivilege, &luid))
    {
        printf("LookupPrivilegeValue error: %u\n", GetLastError());
        return FALSE;
    }

    tp.PrivilegeCount = 1;
    tp.Privileges[0].Luid = luid;
    if (bEnablePrivilege)
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    else
        tp.Privileges[0].Attributes = 0;

    if (!AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(TOKEN_PRIVILEGES),
                               (PTOKEN_PRIVILEGES)NULL, (PDWORD)NULL))
    {
        printf("AdjustTokenPrivileges error: %u\n", GetLastError());
        return FALSE;
    }

    if (GetLastError() == ERROR_NOT_ALL_ASSIGNED)
    {
        printf("The token does not have the specified privilege. \n");
        return FALSE;
    }
    return TRUE;
}

int main()
{
    HANDLE hProc = GetCurrentProcess();

    HANDLE hToken = NULL;
    if (!OpenProcessToken(hProc, TOKEN_ADJUST_PRIVILEGES, &hToken))
        printf("Failed to open access token\n");

    if (!SetPrivilege(hToken, SE_DEBUG_NAME, TRUE))
        printf("Failed to set debug privilege\n");
    
    DWORD pid = 1804;
    HANDLE hTargetProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (hTargetProc)
        printf("Target process handle = %p\n", hTargetProc);
    else
        printf("Failed to open process: %u\n", GetLastError());

    return 0;
}
```
The application opens process with PID equals to `1804`. You can specify any other PID of a process that is launched in your OS at the moment. Windows Task Manager allows to [know](http://support.kaspersky.com/us/general/various/6325#block1) PIDs of all launched processes. You can change a PID of a target process in this line of source file:
```C++
DWORD pid = 1804;
```
Each step of the opening process algorithm matches to a function call in the `main` function. First step is to get handle of the current process and to save it in the `hProc` variable. [`GetCurrentProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683179%28v=vs.85%29.aspx) WinAPI function is used here to get the process's handle. Next step is to get access token of the current process with [`OpenProcessToken`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379295%28v=vs.85%29.aspx) WinAPI function. Handle of the current process `hProc` and `TOKEN_ADJUST_PRIVILEGES` [access mask](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374905%28v=vs.85%29.aspx) are input parameters of the function. Output parameter of the function is `hToken` handle which stores a handle to the access token object. Next step is enabling `SE_DEBUG_NAME` privilege for the current process with `SetPrivilege` function. Enabling privilege happens in two steps in the `SetPrivilege` function:

1. Get [**locally unique identifier**](https://msdn.microsoft.com/en-us/library/ms721592%28v=vs.85%29.aspx#_security_locally_unique_identifier_gly) (LUID) for `SE_DEBUG_NAME` privilege constant with [`LookupPrivilegeValue`](https://msdn.microsoft.com/en-us/library/aa379180%28v=vs.85%29.aspx) WinAPI function.
2. Enable a privilege with the specified LUID with [`AdjustTokenPrivileges`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa375202%28v=vs.85%29.aspx) WinAPI function. `AdjustTokenPrivileges` function operates with LUID values instead of privilege constants.

Example of the `SetPrivilege` function with detailed explanations is available in a MSDN [article](https://msdn.microsoft.com/en-us/library/aa446619%28VS.85%29.aspx). `OpenProcess.cpp` application should be launched with administrator privileges to have rights for assigning `SE_DEBUG_NAME` privilege with `AdjustTokenPrivileges` function.

Last step of the opening process algorithm is a call of `OpenProcess` WinAPI function with `PROCESS_ALL_ACCESS` [access rights](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684880%28v=vs.85%29.aspx) input parameter. PID of an opening process is passed as third input parameter of the function. Result of the function is handle to the target process object in case of success. Handle of the target process provides read and write access to the memory of that process.

## Read and Write Access

WinAPI provides functions for reading and writing access to process's memory. [`ReadProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680553%28v=vs.85%29.aspx) function allows to read data from an area of memory in a specified process. [`WriteProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms681674%28v=vs.85%29.aspx) function performs writing data to the area of memory in a specified process.

There is [`ReadWriteProcessMemory.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/ReadWriteProcessMemory.cpp) application that demonstrates work of both `ReadProcessMemory` and `WriteProcessMemory` functions. The application writes "0xDEADBEEF" hexadecimal value at the specified absolute address, and then reads a value at the same address. If the read value equals to "0xDEADBEEF", write operation has been performed successfully.

This is a source of the `ReadWriteProcessMemory.cpp` application:
```C++
#include <windows.h>
#include <stdio.h>

BOOL SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
    // See function's implementation in the OpenProcess.cpp application
}

DWORD32 ReadDword(HANDLE hProc, DWORD64 address)
{
    DWORD result = 0;

    if (ReadProcessMemory(hProc, (void*)address, &result,
        sizeof(result), NULL) == 0)
    {
        printf("Failed to read memory: %u\n", GetLastError());
    }
    return result;
}

void WriteDword(HANDLE hProc, DWORD64 address, DWORD32 value)
{
    if (WriteProcessMemory(hProc, (void*)address, &value,
        sizeof(value), NULL) == 0)
    {
        printf("Failed to write memory: %u\n", GetLastError());
    }
}

int main()
{
    HANDLE hProc = GetCurrentProcess();

    HANDLE hToken = NULL;
    if (!OpenProcessToken(hProc, TOKEN_ADJUST_PRIVILEGES, &hToken))
        printf("Failed to open access token\n");

    if (!SetPrivilege(hToken, SE_DEBUG_NAME, TRUE))
        printf("Failed to set debug privilege\n");

    DWORD pid = 5356;
    HANDLE hTargetProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (hTargetProc)
        printf("Target process handle = %p\n", hTargetProc);
    else
        printf("Failed to open process: %u\n", GetLastError());

    DWORD64 address = 0x001E0000;
    WriteDword(hTargetProc, address, 0xDEADBEEF);
    printf("Result of reading dword at 0x%llx address = 0x%x\n", address, ReadDword(hTargetProc, address));

    return 0;
}
```
When `ReadWriteProcessMemory.cpp` application will write a "0xDEADBEEF" value to the memory of target process, It is not guaranteed that the target process still has capability to continue its execution. Therefore, it is recommended to not use any Windows system services as target process for this test. You can launch Notepad application and use it as a target process.

This is an algorithm to launch `ReadWriteProcessMemory.cpp` application:

1. Launch a Notepad application.
2. Get PID of the Notepad process with Windows Task Manager application.
3. Assign the Notepad process's PID to the `pid` variable in this line of `main` function:
```C++
DWORD pid = 5356;
```
4. Get base address of any heap segment of the Notepad process with WinDbg debugger. You can use `!address` command to get full memory map of the Notepad process.
5. Detach WinDbg debugger from the Notepad process with `.detach` command.
6. Assign the base address of the heap segment to `address` variable in this line of the `main` function:
```C++
DWORD64 address = 0x001E0000;
```
7. Rebuild `ReadWriteProcessMemory.cpp` application and launch it with the administrator privileges.

This is a console output after successful execution of the application:
```
Target process handle = 000000B4
Result of reading dword at 0x1e0000 address = 0xdeadbeef
```
There are `WriteDword` and `ReadDword` wrapper functions in our example application for both `WriteProcessMemory` and `ReadProcessMemory` WinAPI functions. The wrappers encapsulate type casts and error processing. Both WinAPI function have a similar set of parameters:

| Parameter | Description |
| -- | -- |
| `hProc` | Handle to a process object which memory will be accessed |
| `address` | Absolute address of a memory area to access |
| `&result` or `&value` | Pointer to a buffer that will store a read data in case of `ReadProcessMemory` function. The buffer contains a data which will be written to a target process's memory in case of `WriteProcessMemory` function. |
| `sizeof(...)` | Number of bytes to read from the target process's memory or to write there |
| `NULL` | Pointer to a variable that stores an actual number of transferred bytes |
