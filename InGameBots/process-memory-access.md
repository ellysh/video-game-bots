# Process Memory Access

## Open Process

There is [`OpenProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684320%28v=vs.85%29.aspx) WinAPI function that allows to get a [**handle**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724457%28v=vs.85%29.aspx) of the process with specified [**process identifier**](https://en.wikipedia.org/wiki/Process_identifier) (PID). When you known this process handle, you can access process internals for example process memory via WinAPI functions. 

All processes in Windows are system objects of specific type. These objects are high-level abstractions for OS resources such as a file, process or thread. Each object has an unified structure and they consist of header and body. Header contains meta information about the object and it is used by [**Object Manager**](https://en.wikipedia.org/wiki/Object_Manager_%28Windows%29). Body contains the object-specific data.

Windows [**security model**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374876%28v=vs.85%29.aspx) restricts processes to access the system objects or to perform various system administration tasks. The security model requires a process to have special privileges to access another process with `OpenProcess` WinAPI function. [**Access token**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374909%28v=vs.85%29.aspx) is a system object that allows us to manipulate with security attributes of the process. The access token can be used to grant necessary privileges, which are required to use `OpenProcess` function.

This is a common algorithm to open a target process with the `OpenProcess` function:

1. Get a handle of a current process.
2. Get access token of the current process.
3. Grant `SE_DEBUG_NAME` privilege for process' access token. This privilege allows the process to debug other launched ones.
4. Get a handle of the target process with the `OpenProcess` function.

This is a source code of the [`OpenProcess.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/OpenProcess.cpp) application that opens process with the specific PID:
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

    CloseHandle(hTargetProc);
    return 0;
}
```
The application opens process with a PID equals to `1804`. You should change this value to the actual PID of the launched process. Windows Task Manager allows you to [know](http://support.kaspersky.com/us/general/various/6325#block1) PIDs of all launched processes. This is a code line to change:
```C++
DWORD pid = 1804;
```
Each step of the opening process algorithm matches to the function call in the `main` function. 

First step is to get a handle of the current process with the [`GetCurrentProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683179%28v=vs.85%29.aspx) WinAPI function. This handle is saved in the `hProc` variable. 

Next step is to get access token of the current process with the [`OpenProcessToken`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379295%28v=vs.85%29.aspx) WinAPI function. We pass the `hProc` variable and `TOKEN_ADJUST_PRIVILEGES` [access mask](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374905%28v=vs.85%29.aspx) to this function. Resulting `hToken` value is a handle to the access token.

Next step is to grant `SE_DEBUG_NAME` privilege for the current process. The `SetPrivilege` function encapsulates this action. There are two steps to grant the privilege:

1. Get [**locally unique identifier**](https://msdn.microsoft.com/en-us/library/ms721592%28v=vs.85%29.aspx#_security_locally_unique_identifier_gly) (LUID) of the `SE_DEBUG_NAME` privilege constant with the [`LookupPrivilegeValue`](https://msdn.microsoft.com/en-us/library/aa379180%28v=vs.85%29.aspx) WinAPI function.

2. Grant the privilege with the specified LUID with [`AdjustTokenPrivileges`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa375202%28v=vs.85%29.aspx) WinAPI function. This function operates with LUID values instead of privilege constants.

Example of the `SetPrivilege` function with a detailed explanation is available in the MSDN [article](https://msdn.microsoft.com/en-us/library/aa446619%28VS.85%29.aspx). The `OpenProcess.cpp` application should be launched with administrator privileges. This is a necessary requirement to grant the `SE_DEBUG_NAME` privilege with the `AdjustTokenPrivileges` function.

Last step of the `OpenProcess.cpp` application is to call the `OpenProcess` WinAPI function. We pass the `PROCESS_ALL_ACCESS` [access rights](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684880%28v=vs.85%29.aspx) and a PID of the target process to this function. The function returns process' handle, which we can use to access memory of this process.

## Read and Write Operations

WinAPI provides functions to access memory of the target process. The [`ReadProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680553%28v=vs.85%29.aspx) function allows us to read data from a memory area of the target process to the memory of current process. [`WriteProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms681674%28v=vs.85%29.aspx) function performs writing specified data to a memory area in the target process. 

We will consider usage of these functions with an example application. The application writes 0xDEADBEEF hexadecimal value at the specified absolute address of the target process memory. Then it reads a value at the same absolute address. If the write operation succeeds, read operation returns 0xDEADBEEF value.

This is a source of the [`ReadWriteProcessMemory.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/ReadWriteProcessMemory.cpp) application:
```C++
#include <stdio.h>
#include <windows.h>

BOOL SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
    // See function's implementation in the OpenProcess.cpp application
}

DWORD ReadDword(HANDLE hProc, DWORD_PTR address)
{
    DWORD result = 0;

    if (ReadProcessMemory(hProc, (void*)address, &result, sizeof(result), NULL) == 0)
    {
        printf("Failed to read memory: %u\n", GetLastError());
    }
    return result;
}

void WriteDword(HANDLE hProc, DWORD_PTR address, DWORD value)
{
    if (WriteProcessMemory(hProc, (void*)address, &value, sizeof(value), NULL) == 0)
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
    if (!hTargetProc)
        printf("Failed to open process: %u\n", GetLastError());

    DWORD_PTR address = 0x001E0000;
    WriteDword(hTargetProc, address, 0xDEADBEEF);
    printf("Result of reading dword at 0x%llx address = 0x%x\n", address,
           ReadDword(hTargetProc, address));

    CloseHandle(hTargetProc);
    return 0;
}
```
Write operation to the random `0x001E0000` absolute address can crash the target process. Therefore, it is not recommended to use any Windows system services as target process to test this application. You can launch Notepad and use it as a target process.

This is an algorithm to launch `ReadWriteProcessMemory.cpp` application:

1. Launch a Notepad.
2. Get a PID of the Notepad process with the Windows Task Manager.
3. Assign the Notepad process's PID to the `pid` variable in this line of the `main` function:
```C++
DWORD pid = 5356;
```
4. Get a base address of any heap segment of the Notepad process with WinDbg debugger. You can use `!address` command to get full memory map of the Notepad process.
5. Detach WinDbg debugger from the Notepad process with `.detach` command.
6. Assign the base address of the heap segment to `address` variable in this line of the `main` function:
```C++
DWORD_PTR address = 0x001E0000;
```
7. Rebuild the `ReadWriteProcessMemory.cpp` application. The application binary should have the same target architecture (x86 or x64) as Notepad.
8. Launch the example application with administrator privileges.

This is a console output after successful execution of the application:
```
Result of reading dword at 0x1e0000 address = 0xdeadbeef
```
The output contains a memory address where data was read and written. Also there is a read value from this address.

We use `WriteDword` and `ReadDword` wrapper functions for WinAPI ones. These wrappers encapsulate type casts and error processing. Both `WriteProcessMemory` and `ReadProcessMemory` WinAPI functions have similar parameters:

| Parameter | Description |
| -- | -- |
| `hProc` | Handle of the target process, which memory will be accessed |
| `address` | Absolute address of a memory area to access |
| `&result` or `&value` | Pointer to the buffer to store a read data in case of `ReadProcessMemory` function. The buffer contains a data to write to a target process memory in case of `WriteProcessMemory` function. |
| `sizeof(...)` | Number of bytes to read from memory or to write there |
| `NULL` | Pointer to a variable that stores an actual number of transferred bytes |

## TEB and PEB Access

Now we will consider ways to get a base addresses of the TEB segments in process memory. Each thread of the process has own TEB segment. Each TEB segment contains information about a base address of the singular PEB segment. Therefore, when a task of accessing TEB is solved, you already have an access to information of PEB segment too. Accessing of TEB and PEB segments is important step for our task of analyzing the process memory. TEB segment contains a base address of the corresponding thread's stack segment. PEB segment contains a base address of the default heap segment.

### Current Process

Let us consider methods to access a TEB segment. We will start to explore these methods from a simplest case. This case is to access the TEB of the main thread of our example application.

There are several ways to access TEB segment. First one is to use segment registers in the same way as Windows do it. There are **FS segment register** for x86 architecture and **GS segment register** for x64 architecture. Both of these registers point to the TEB segment of the thread that is executed at the moment.
 
This is a source code of `GetTeb` function that retrieves a pointer to the `TEB` structure for x86 architecture application:
```C++
#include <winternl.h>

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
You can see that we read 32-bit value with `0x18` offset from the TEB segment. This value matches to the base address of TEB segment.

The `TEB` structure may vary between different Windows versions. This structure is defined in the `winternal.h` header file, which is provided by Windows SDK. You should clarify, how the structure looks like for your environment before to start working with it. This is an example of the structure for Windows 8.1 version:
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
You can see that `TEB` structure has the `ProcessEnvironmentBlock` field, which points to the `PEB` structure. We can use this pointer to access PEB segment.

This approach to access a TEB segment register via assembler inline code does not work for x64 architecture. Visual Studio C++ compiler [does not support](https://msdn.microsoft.com/en-us/library/wbk4z78b.aspx) inline assembler for x64 target architecture. The [**compiler intrinsics**](https://msdn.microsoft.com/en-us/library/26td21ds.aspx) should be used instead of the inline assembler in this case.

There is a source code of the `GetTeb` function, which uses compiler intrinsics:
```C++
#include <windows.h>
#include <winternl.h>

PTEB GetTeb()
{
#if defined(_M_X64) // x64
    PTEB pTeb = reinterpret_cast<PTEB>(__readgsqword(0x30));
#else // x86
    PTEB pTeb = reinterpret_cast<PTEB>(__readfsdword(0x18));
#endif
    return pTeb;
}
```
This version of the `GetTeb` function is appropriate for both x86 and x64 target architectures. We use the [`_M_X64`](https://msdn.microsoft.com/en-us/library/b0084kay.aspx) macro to define an architecture of the application.

You can see that [`__readgsqword`](https://msdn.microsoft.com/en-us/library/htss0hyy.aspx) compiler intrinsic is used here to read a qword of 64-bit size with `0x30` offset from the GS segment register in case of x64 architecture. The [`__readfsdword`](https://msdn.microsoft.com/en-us/library/3887zk1s.aspx) intrinsic is used to read a double word of 32-bit size with `0x18` offset from the FS segment register in case of x86 architecture.

There is a question, why a TEB segment contains own base address? [**Protected processor mode**](https://en.wikipedia.org/wiki/Protected_mode) is used by most of modern OS. Windows works in protected mode too. It means that [**segments addressing**](https://en.wikipedia.org/wiki/X86_memory_segmentation#Protected_mode) works via [**descriptor tables**](https://en.wikipedia.org/wiki/Global_Descriptor_Table) mechanism in our case. FS and GS registers actually contain a selector that defines the index of an entry inside the descriptor table. The descriptor table contains an actual base address of the TEB segment that matches to the specified index. This kind of request to descriptor table is performed by a segmentation unit of the CPU. Resulting address of a calculation performed by the segmentation unit is kept inside the CPU, and neither user application nor OS can access it. There is a way to access entries of the descriptor tables via [`GetThreadSelectorEntry `](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679363%28v=vs.85%29.aspx) and [`Wow64GetThreadSelectorEntry`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd709484%28v=vs.85%29.aspx) WinAPI functions. But this kind of memory reading operations leads to overhead. Overcome of the overhead is a probable reason, why TEB segment contains own base address. 

There is [an example](http://reverseengineering.stackexchange.com/questions/3139/how-can-i-find-the-thread-local-storage-tls-of-a-windows-process-thread) of usage the `GetThreadSelectorEntry` function.

There is another question, why a memory area with TEB segment's base address has the different offsets inside the TEB segment for x86 and x64 architectures? Let us look at the definition of the `NT_TIB` structure, which is used for interpretation [**NT subsystem**](https://en.wikipedia.org/wiki/Architecture_of_Windows_NT) independent part of the TEB segment:
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
There are six pointers before the `Self` field in the `NT_TIB` structure. The pointer size equals to 32 bit (or 4 byte) for x86 architecture. It is increased to 64 bit (or 8 byte) for x64 architecture. This is a calculation of the `Self` field's offset for the x86 architecture:
```
6 * 4 = 24
```
The 24 number in the decimal numeral system equals to 0x18 in the hexadecimal one. The same offset calculation for x64 architecture gives 0x30 result in the hexadecimal numeral system.

There is a more portable implementation of the `GetTeb` function with an explicit usage of the `NT_TIB` structure:
```C++
#include <windows.h>
#include <winternl.h>

PTEB GetTeb()
{
#if defined(_M_X64) // x64
    PTEB pTeb = reinterpret_cast<PTEB>(__readgsqword(reinterpret_cast<DWORD>(
                                       &static_cast<PNT_TIB>(nullptr)->Self)));
#else // x86
    PTEB pTeb = reinterpret_cast<PTEB>(__readfsdword(reinterpret_cast<DWORD>(
                                       &static_cast<PNT_TIB>(nullptr)->Self)));
#endif
    return pTeb;
}
```
There is a [project](https://www.autoitscript.com/forum/topic/164693-implementation-of-a-standalone-teb-and-peb-read-method-for-the-simulation-of-getmodulehandle-and-getprocaddress-functions-for-loaded-pe-module/) where this code was originally presented. You can see that the same `__readgsqword` and `__readfsdword` compiler intrinsics are used here. But now we use the `NT_TIB` structure to calculate offset to base TEB address. This allows us to avoid magical numbers and to adapt our application to future Windows versions where `NT_TIB` structure may change.

Second way to access TEB segment is to use WinAPI functions. There is the [`NtCurrentTeb`](https://msdn.microsoft.com/en-us/library/windows/hardware/hh285210%28v=vs.85%29.aspx) function that performs exact the same work as the `GetTeb` above. It allows us to get the `TEB` structure of the current thread. This code snippet illustrates the `NtCurrentTeb` usage:
```C++
#include <windows.h>
#include <winternl.h>

PTEB pTeb = NtCurrentTeb();
```
Now we shift the responsibility to choose an appropriate registers calculation to Windows. Therefore, the function retrieves a correct result for all architectures, which are supported by Windows such as x86, x64 and ARM.

The [`NtQueryInformationThread`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684283%28v=vs.85%29.aspx) WinAPI function allows you to get information about any thread. You should pass the thread handler to this function. This is a version of the `GetTeb` function that uses the `NtQueryInformationThread` one internally:
```C++
#include <windows.h>
#include <winternl.h>

#pragma comment(lib,"ntdll.lib")

typedef struct _CLIENT_ID {
    DWORD UniqueProcess;
    DWORD UniqueThread;
} CLIENT_ID, *PCLIENT_ID;

typedef struct _THREAD_BASIC_INFORMATION {
    typedef PVOID KPRIORITY;
    NTSTATUS ExitStatus;
    PVOID TebBaseAddress;
    CLIENT_ID ClientId;
    KAFFINITY AffinityMask;
    KPRIORITY Priority;
    KPRIORITY BasePriority;
} THREAD_BASIC_INFORMATION, *PTHREAD_BASIC_INFORMATION;

typedef enum _THREADINFOCLASS2 {
    ThreadBasicInformation,
    ThreadTimes,
    ThreadPriority,
    ThreadBasePriority,
    ThreadAffinityMask,
    ThreadImpersonationToken,
    ThreadDescriptorTableEntry,
    ThreadEnableAlignmentFaultFixup,
    ThreadEventPair_Reusable,
    ThreadQuerySetWin32StartAddress,
    ThreadZeroTlsCell,
    ThreadPerformanceCount,
    ThreadAmILastThread,
    ThreadIdealProcessor,
    ThreadPriorityBoost,
    ThreadSetTlsArrayAddress,
    _ThreadIsIoPending,
    ThreadHideFromDebugger,
    ThreadBreakOnTermination,
    MaxThreadInfoClass
} THREADINFOCLASS2;

PTEB GetTeb()
{
    THREAD_BASIC_INFORMATION threadInfo;
    if (NtQueryInformationThread(GetCurrentThread(),
                                 (THREADINFOCLASS)ThreadBasicInformation,
                                 &threadInfo, sizeof(threadInfo), NULL))
    {
        printf("NtQueryInformationThread return error\n");
        return NULL;
    }
    return reinterpret_cast<PTEB>(threadInfo.TebBaseAddress);
}
```
There is a description of the `NtQueryInformationThread` function parameters:

| Parameter | Description |
| -- | -- |
| `GetCurrentThread()` | Handle of the target thread. There is a handle of the current thread in this case. |
| `ThreadBasicInformation` | Constant of the `THREADINFOCLASS` enumeration type. Value of the constant defines a type of the resulting information i.e. type of the returning structure. |
| `&threadInfo` | Pointer to a structure to write the function's result. |
| `sizeof(...)` | Size of the structure where function's result will be written |
| `NULL` | Pointer to a variable that stores an actual number of bytes, which were written to the resulting structure |

There is only one constant with `ThreadIsIoPending` name in the `THREADINFOCLASS` enumeration, which is officially documented and defined in the `winternl.h` header file. All other possible constants are not documented by Microsoft. But you can find them [here](http://undocumented.ntinternals.net/UserMode/Undocumented%20Functions/NT%20Objects/Thread/THREAD_INFORMATION_CLASS.html). Your application should define own `THREADINFOCLASS` enumeration with extra undocumented constants. We have named this enumeration as `THREADINFOCLASS2`, and we have renamed a `ThreadIsIoPending` constant to `_ThreadIsIoPending` in our example. This allows us to avoid a name conflict with the official `THREADINFOCLASS` enumeration from the included `winternl.h` header file. Also you should define a structure to receive a result of the `NtQueryInformationThread` function. There is the `THREAD_BASIC_INFORMATION` structure in our case, that is match to the `ThreadBasicInformation` enumeration constant. As you see, `THREAD_BASIC_INFORMATION` structure has the `TebBaseAddress` field. This field contains a base address of the TEB segment.

The `NtQueryInformationThread` function is provided by Windows Native API. The `ntdll.dll` dynamic library provides this API. Windows SDK contains both `winternl.h` header file and `ntdll.lib` [**import library**](https://en.wikipedia.org/wiki/Dynamic-link_library#Import_libraries). They allows you to link with `ntdll.dll` library and to call its functions. We use a [**pragma directive**](https://msdn.microsoft.com/en-us/library/d9x1s805.aspx) here. This is a line that adds the `ntdll.lib` file to linker's list of import libraries:
```C++
#pragma comment(lib, "ntdll.lib")
```
This is the [`TebPebSelf.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebSelf.cpp) application that demonstrates all consider ways to access TEB and PEB of the current process.

### Another Process

Now we will consider methods to access TEB and PEB segments of another process. 

This is an algorithm to launch example applications of this subsection:

1. Launch a 32-bit or 64-bit target application.
2. Get PID of the target process with Windows Task Manager application.
3. Assign the target process's PID to the `pid` variable in this line of `main` function:
```C++
DWORD pid = 5356;
```
4. Launch an example application with the administrator privileges.

First approach to access TEB segment relies on assumption that base addresses of TEB segments are the same for all processes in a system. We should get base addresses of the TEB segments for the current process, and than read memory at the same addresses from another process. This is a source code of [`TebPebMirror.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebMirror.cpp) application that implements this algorithm:
```C++
#include <windows.h>
#include <winternl.h>

BOOL SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
    // See function's implementation in the OpenProcess.cpp application
}

BOOL GetMainThreadTeb(DWORD dwPid, PTEB pTeb)
{
    LPVOID tebAddress = NtCurrentTeb();
    printf("TEB = %p\n", tebAddress);

    HANDLE hProcess = OpenProcess(PROCESS_VM_READ, FALSE, dwPid);
    if (hProcess == NULL)
        return false;

    if (ReadProcessMemory(hProcess, tebAddress, pTeb, sizeof(TEB), NULL) == FALSE)
    {
        CloseHandle(hProcess);
        return false;
    }

    CloseHandle(hProcess);
    return true;
}

int main()
{
    HANDLE hProc = GetCurrentProcess();

    HANDLE hToken = NULL;
    if (!OpenProcessToken(hProc, TOKEN_ADJUST_PRIVILEGES, &hToken))
        printf("Failed to open access token\n");

    if (!SetPrivilege(hToken, SE_DEBUG_NAME, TRUE))
        printf("Failed to set debug privilege\n");

    DWORD pid = 7368;

    TEB teb;
    if (!GetMainThreadTeb(pid, &teb))
        printf("Failed to get TEB\n");
    
    printf("PEB = %p StackBase = %p\n", teb.ProcessEnvironmentBlock,
           teb.Reserved1[1]);

    return 0;
}
```
This application prints base addresses of three segments of a target process:

1. TEB segment.
2. PEB segment.
3. Stack segment of main thread.

We use an already considered approach to grant the `SE_DEBUG_NAME` privilege to the current process with the `OpenProcessToken` and `SetPrivilege` functions. Then we call the `GetMainThreadTeb` function. This function receives the PID of the target process and returns a pointer to the `TEB` structure. These are steps of the function:

1. Call the `NtCurrentTeb` WinAPI function to get base address of TEB segment of the current thread.
2. Call the `OpenProcess` WinAPI function to receive a handler of the target process with the `PROCESS_VM_READ` access.
3. Call the `ReadProcessMemory` WinAPI function to read a `TEB` structure from the target process.

This approach provides stable results for 32-bit target processes. These processes have the same base address of TEB segment in case of the same environment. But considered approach is totally not reliable for 64-bit processes. Base address of the TEB segment vary each time when you launch 64-bit applications. Nevertheless, this approach have significant advantage. It is easy to implement.

This is important to emphasize that bitness of the `TebPebMirror.cpp` application should be the same as bitness of an analyzing process.  This rule is appropriate for all examples of this chapter. You can select the target architecture in the "Solution Platforms" control of the Visual Studio window.

Second approach to access TEB segment is to use WinAPI functions to traverse all threads, which are launched in the system at the moment. This is a list of these functions:

1. [`CreateToolhelp32Snapshot`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682489%28v=vs.85%29.aspx) provides a system snapshot with processes and threads system objects, plus modules and heaps. You can pass the PID parameter to get modules and heaps of the specific process. The snapshot always contains all threads that are launched in the system at the moment.

2. [`Thread32First`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686728%28v=vs.85%29.aspx) starts to traverse threads of the specified system snapshot. Output parameter of the function is a pointer to the [`THREADENTRY32`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686735%28v=vs.85%29.aspx) structure. This structure contains information about the first thread in the snapshot.

3. [`Thread32Next`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686731%28v=vs.85%29.aspx) continues to traverse threads of the snapshot. It has the same output parameter as the `Thread32First` function.

There is a source code of the [`TebPebTraverse.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebTraverse.cpp) application that implements traversing algorithm:
```C++
#include <windows.h>
#include <tlhelp32.h>
#include <winternl.h>

#pragma comment(lib,"ntdll.lib")

typedef struct _CLIENT_ID {
    // See struct definition in the TebPebSelf.cpp application
} CLIENT_ID, *PCLIENT_ID;

typedef struct _THREAD_BASIC_INFORMATION {
    // See struct definition in the TebPebSelf.cpp application
} THREAD_BASIC_INFORMATION, *PTHREAD_BASIC_INFORMATION;

typedef enum _THREADINFOCLASS2
{
    // See enumeration definition in the TebPebSelf.cpp application
}   THREADINFOCLASS2;

PTEB GetTeb(HANDLE hThread)
{
    THREAD_BASIC_INFORMATION threadInfo;
    NTSTATUS result = NtQueryInformationThread(hThread,
                                    (THREADINFOCLASS)ThreadBasicInformation,
                                    &threadInfo, sizeof(threadInfo), NULL);
    if (result)
    {
        printf("NtQueryInformationThread return error: %d\n", result);
        return NULL;
    }
    return reinterpret_cast<PTEB>(threadInfo.TebBaseAddress);
}

void ListProcessThreads(DWORD dwOwnerPID)
{
    HANDLE hThreadSnap = INVALID_HANDLE_VALUE;
    THREADENTRY32 te32;

    hThreadSnap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);

    if (hThreadSnap == INVALID_HANDLE_VALUE)
        return;

    te32.dwSize = sizeof(THREADENTRY32);

    if (!Thread32First(hThreadSnap, &te32))
    {
        CloseHandle(hThreadSnap);
        return;
    }

    DWORD result = 0;
    do
    {
        if (te32.th32OwnerProcessID == dwOwnerPID)
        {
            printf("\n     THREAD ID = 0x%08X", te32.th32ThreadID);

            HANDLE hThread = OpenThread(THREAD_ALL_ACCESS, FALSE,
                                        te32.th32ThreadID);
            PTEB pTeb = GetTeb(hThread);
            printf("\n     TEB = %p\n", pTeb);

            CloseHandle(hThread);
        }
    } while (Thread32Next(hThreadSnap, &te32));

    printf("\n");
    CloseHandle(hThreadSnap);
}

int main()
{
    DWORD pid = 4792;

    ListProcessThreads(pid);

    return 0;
}
```
The application prints a list of threads of the target process. Also a thread ID in terms of OS and a TEB segment base address are printed for each thread in this list.

The `main` function calls `ListProcessThreads` with the PID of target process. The `SE_DEBUG_NAME` privilege is not needed to traverse threads. It happens because the `TebPebTraverse.cpp` application does not debug any process. Instead it makes a system snapshot. This action requires administrator privileges only.

These are steps of the `ListProcessThreads` function:

1. Call the `CreateToolhelp32Snapshot` function to make a system snapshot.

2. Call `Thread32First` to start traversing of the threads in the snapshot.

3. Compare a PID of the owner process with the PID of target process for each thread.

4. If the PIDs match, call the `GetTeb` function to get the `TEB` structure.

5. Print thread handle and resulting base address of its TEB segment.

6. Call `Thread32Next` to continue thread traversing. Repeat steps 3, 4 and 5 for each thread.

This approach to access TEB segments is more reliable than the previous one. It provides access to TEB segments of all threads of the target process. You can reach the same result with the `TebPebMirror.cpp` application. You should create the same number of threads as the target process has. Then you can get base addresses of all own TEB segments and use them to access TEBs of the target process. But this approach is error prone.

There is a question, how to distinguish threads that are traversed by the `Thread32Next` WinAPI function? For example, you are trying to find a base address of the stack for the main thread. `THREADENTRY32` structure does not contain information about thread's ID in term of the process. There are threads' IDs in term of the Object Manager of Windows. But you can rely on assumption that TEB segments is sorted in the reverse order. This means that the TEB segment with the maximum base address matches to the main thread. The TEB segment with the next lower base address matches to the thread with the 1st ID in terms of the target process. Then TEB segment with the 2nd ID has the next lower base address and so on. You can check this assumption with a memory map of the target process that is provided by WinDbg debugger.

## Heap Analyzing

WinAPI provides a set of functions to traverse heap segments and blocks of the specified process. This approach is similar to traversing all threads in the system with a system snapshot. There are WinAPI functions that will be used in our example:

1. `CreateToolhelp32Snapshot` function that makes a system snapshot.
2. [`Heap32ListFirst`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683432%28v=vs.85%29.aspx) function is used to start a heap segments traversing of the specified system snapshot. Output parameter of the function is a pointer to  [`HEAPLIST32`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683449%28v=vs.85%29.aspx) structure with information of the first heap segment in the snapshot.
3. [`Heap32ListNext `](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683436%28v=vs.85%29.aspx) function is used to continue the heap segments traversing for the system snapshot. It has the same output parameter as the `Heap32ListFirst` function.

There are two extra WinAPI functions: [`Heap32First`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683245%28v=vs.85%29.aspx) and [`Heap32Next`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683440%28v=vs.85%29.aspx). These functions allow to traverse memory blocks inside the each heap segment. We will not use these functions in our example. Operation of traversing all memory blocks of a heap segment can take a considerable time for complex applications.

There is a source code of [`HeapTraverse.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/HeapTraverse.cpp) application that retrieves base addresses of heap segments for a target process:
```C++
#include <windows.h>
#include <tlhelp32.h>

void ListProcessHeaps(DWORD pid)
{
    HEAPLIST32 hl;

    HANDLE hHeapSnap = CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, pid);

    hl.dwSize = sizeof(HEAPLIST32);

    if (hHeapSnap == INVALID_HANDLE_VALUE)
    {
        printf("CreateToolhelp32Snapshot failed (%d)\n", GetLastError());
        return;
    }

    if (Heap32ListFirst(hHeapSnap, &hl))
    {
        do
        {
            printf("\nHeap ID: 0x%lx\n", hl.th32HeapID);
            printf("\Flags: 0x%lx\n", hl.dwFlags);
        } while (Heap32ListNext(hHeapSnap, &hl));
    }
    else
        printf("Cannot list first heap (%d)\n", GetLastError());

    CloseHandle(hHeapSnap);
}

int main()
{
    DWORD pid = 6712;

    ListProcessHeaps(pid);

    return 0;
}
```
Algorithm of `ListProcessHeaps` function is very similar to algorithm of the `ListProcessThreads` function from the `TebPebTraverse.cpp` example application. These are steps of this algorithm:

1. Make a system snapshot with all heap segments of specified by PID process with the `CreateToolhelp32Snapshot` WinAPI function.
2. Start a traversing of heap segments with the `Heap32ListFirst` WinAPI function.
3. Print ID of the current heap segment in the loop and a value of its flags.
4. Repeat step 3 until all heap segments in the system snapshot are not enumerated with the `Heap32ListNext` WinAPI function.

What is a meaning of the values, that were printed to the application's output? ID of the heap segment matches to the base address of this segment. Value of the segment's flags allows to distinguish a default heap segment. Only the default heap segment will have a not zeroed value of the flags. 

Also it is important to emphasize, that the order of a traversing heap segments matches to an ID numbering of the segments in terms of the target process. It means that segment with ID equal to 1 will be processed first by the `ListProcessHeaps` function. Then the segment with ID 2 will be processed and so on. This segments ordering allows to distinguish them when a bot application searches the game state variables.