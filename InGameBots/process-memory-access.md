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

## TEB and PEB

### Current Process

Now we will consider ways to get TEB segment's address in a process's memory. TEB segment stores information about PEB absolute address. Therefore, when a task of accessing TEB is solved, you already have an access to information of PEB segment too.

There are several ways to get TEB segment's address of the current process. First one is to use segment registers to access 
thread-specific memory or [**thread-local storage**](https://en.wikipedia.org/wiki/Thread-local_storage) (TLS) in the same way as OS system do it. There is **FS segment register** for x86 architecture and **GS register** for x64 architecture that are to point to TLS. This is a source of `GetTeb` function that retrieves pointer to the `TEB` structure for x86 architecture application:
```C++
PTEB GetTeb()
{
    PTEB pTeb;

    __asm {
        mov EAX, FS:[0x18]
        mov pTeb, EAX
    }
    return pTeb;
}
```
Definition of `TEB` structure may differ between Windows versions. The structure is defined in `winternal.h` header file. You should clarify, how the structure looks like for your Windows version before to start working with it. This is an example of the structure for Windows 8.1 version:
```C++
typedef struct _TEB {
    PVOID Reserved1[12];
    PPEB ProcessEnvironmentBlock;
    PVOID Reserved2[399];
    BYTE Reserved3[1952];
    PVOID TlsSlots[64];
    BYTE Reserved4[8];
    PVOID Reserved5[26];
    PVOID ReservedForOle;  // Windows 2000 only
    PVOID Reserved6[4];
    PVOID TlsExpansionSlots;
} TEB, *PTEB;
```
This approach of accessing a segment register via assembler inline code is not appropriate for x64 architecture. Visual Studio C++ compiler [does not support](https://msdn.microsoft.com/en-us/library/wbk4z78b.aspx) inline assembler for x64 target architecture. The [**compiler intrinsics**](https://msdn.microsoft.com/en-us/library/26td21ds.aspx) should be used instead of the inline assembler in this case.

There is a source of the `GetTeb` function that have been rewritten with the compiler intrinsics:
```C++
PTEB GetTeb()
{
#if defined(_M_X64)
    PTEB pTeb = reinterpret_cast<PTEB>(__readgsqword(0x30));
#else
    PTEB pTeb = reinterpret_cast<PTEB>(__readfsdword(0x18));
#endif
    return pTeb;
}
```
You can see that [`__readgsqword`](https://msdn.microsoft.com/en-us/library/htss0hyy.aspx) compiler intrinsic is used here to read quadword with "0x30" offset from GS segment register in case of x64 architecture. The [`__readfsdword`](https://msdn.microsoft.com/en-us/library/3887zk1s.aspx) intrinsic is used for reading double word with "0x18" offset from FS segment register in case of x86 architecture. This code is legal for both architectures and it can be used in your applications.

There is a question, why offset to value with absolute address of TEB structure equals to "0x18" for x86 architecture and it differs for x64 architecture. [**Protected processor mode**](https://en.wikipedia.org/wiki/Protected_mode) is used by most of modern OS. Windows works in protected mode too. It means that [segments addressing](https://en.wikipedia.org/wiki/X86_memory_segmentation#Protected_mode) works via [**descriptor tables**](https://en.wikipedia.org/wiki/Global_Descriptor_Table) in our case. FS and GS registers contains a selector that defines the index of an entry inside a descriptor table. The descriptor table contains an actual base address of the TEB segment that matches to the specified index. This kind of request to descriptor table is performed by a segmentation unit of the CPU. Resulting address of segmentation unit calculations is kept inside CPU, and neither user application nor OS cannot access it. Therefore, TEB segment contains own absolute address.

There is a definition of the `NT_TIB` structure that is used for interpretation [**NT subsystem**](https://en.wikipedia.org/wiki/Architecture_of_Windows_NT) independent part of TEB segment:
```C++
typedef struct _NT_TIB {
    struct _EXCEPTION_REGISTRATION_RECORD *ExceptionList;
    PVOID StackBase;
    PVOID StackLimit;
    PVOID SubSystemTib;
     union
     {
          PVOID FiberData;
          ULONG Version;
     };
    PVOID ArbitraryUserPointer;
    struct _NT_TIB *Self;
} NT_TIB;
```
`Self` field of the `NT_TIB` structure have an offset that equals to "0x18" for x86 architecture according to this definition. The field's offset equals to "0x30" for x64 architecture because pointer size equals to 64 bit instead of 32 bit one for x86 architecture.

### Another Process