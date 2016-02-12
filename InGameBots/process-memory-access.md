# Process Memory Access

## Open Process

There is [`OpenProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684320%28v=vs.85%29.aspx) WinAPI function that allows to get a [**handle**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724457%28v=vs.85%29.aspx) of the process with specified [**process identifier**](https://en.wikipedia.org/wiki/Process_identifier) (PID). When you known this process handle, you can access process internals for example process's memory via WinAPI functions. 

All processes in Windows are system objects of specific type. System objects are high-level abstractions for OS resources, such as a file, process or thread. All objects have an unified structure and they consist of header and body. Header contains meta information about the object that is used by [**Object Manager**](https://en.wikipedia.org/wiki/Object_Manager_%28Windows%29). Body contains the object-specific data.

Windows [**security model**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374876%28v=vs.85%29.aspx) is responsible for controlling ability of a process to access the system objects or to perform various system administration tasks. The security model requires a process to have special privileges for accessing another process with `OpenProcess` WinAPI function. [**Access token**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374909%28v=vs.85%29.aspx) is a system object that allows to manipulate with security attributes of the process. The access token can be used to grant necessary privileges for usage `OpenProcess` function.

This is a common algorithm of opening a target process with `OpenProcess` function:

1. Get object's handle of a current process.
2. Get access token of the current process.
3. Enable `SE_DEBUG_NAME` privilege for the current process by affecting process's access token. The privilege allows process to debug other launched processes.
4. Get object's handle of the target process.

This is a source code of the [`OpenProcess.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/OpenProcess.cpp) application that implements the opening process algorithm:
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
The application opens process with PID equals to `1804`. You can specify any other PID of the target process that is launched in your system at the moment. Windows Task Manager allows you to [know](http://support.kaspersky.com/us/general/various/6325#block1) PIDs of all launched processes. You can change a PID of the target process in this line of the source code file:
```C++
DWORD pid = 1804;
```
Each step of the opening process algorithm matches to the function call in the `main` function. First step is to get handle of the current process and to save it in the `hProc` variable. [`GetCurrentProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683179%28v=vs.85%29.aspx) WinAPI function is used here to get handle of the current process. Next step is to get access token of the current process with [`OpenProcessToken`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379295%28v=vs.85%29.aspx) WinAPI function. Handle of the current process `hProc` and `TOKEN_ADJUST_PRIVILEGES` [access mask](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374905%28v=vs.85%29.aspx) are input parameters of the function. Output parameter of the function is `hToken` handle which stores a handle to the access token. Next step is enabling `SE_DEBUG_NAME` privilege for the current process with `SetPrivilege` function. Enabling privilege happens in two steps in the `SetPrivilege` function:

1. Get [**locally unique identifier**](https://msdn.microsoft.com/en-us/library/ms721592%28v=vs.85%29.aspx#_security_locally_unique_identifier_gly) (LUID) for `SE_DEBUG_NAME` privilege constant with [`LookupPrivilegeValue`](https://msdn.microsoft.com/en-us/library/aa379180%28v=vs.85%29.aspx) WinAPI function.
2. Enable a privilege with the specified LUID with [`AdjustTokenPrivileges`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa375202%28v=vs.85%29.aspx) WinAPI function. The `AdjustTokenPrivileges` function operates with LUID values instead of privilege constants.

Example of the `SetPrivilege` function with a detailed explanation is available in the MSDN [article](https://msdn.microsoft.com/en-us/library/aa446619%28VS.85%29.aspx). The `OpenProcess.cpp` application should be launched with administrator privileges. This is a necessary requirement for assigning `SE_DEBUG_NAME` privilege with the `AdjustTokenPrivileges` function.

Last step of the opening process algorithm is the call of `OpenProcess` WinAPI function with `PROCESS_ALL_ACCESS` [access rights](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684880%28v=vs.85%29.aspx) input parameter. PID of the opening process is passed as third input parameter of the function. Result of the function is a handle to the target process object in case of success. Handle of the target process provides read and write access to the memory of that process.

## Read and Write Operations

WinAPI provides functions for accessing data in memory of the specified process. [`ReadProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680553%28v=vs.85%29.aspx) function allows to read data from a memory area in the target process to the memory of current process. [`WriteProcessMemory`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms681674%28v=vs.85%29.aspx) function performs writing data to a memory area in the target process.

There is [`ReadWriteProcessMemory.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/ReadWriteProcessMemory.cpp) application that demonstrates work of both `ReadProcessMemory` and `WriteProcessMemory` functions. The application writes 0xDEADBEEF hexadecimal value at the specified absolute address. Then it reads a value at the same absolute address. If the read value equals to the written value 0xDEADBEEF, it means that a write operation has been performed successfully.

This is a source of the `ReadWriteProcessMemory.cpp` application:
```C++
#include <windows.h>
#include <stdio.h>

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
When the `ReadWriteProcessMemory.cpp` application will write a 0xDEADBEEF value to the memory of target process, It is not guaranteed that the target process still has capability to continue its execution. Therefore, it is not recommended to use any Windows system services as target process for this test. You can launch Notepad application, and use it as a target process.

This is an algorithm to launch `ReadWriteProcessMemory.cpp` application:

1. Launch a Notepad application.
2. Get PID of the Notepad process with the Windows Task Manager application.
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
7. Rebuild `ReadWriteProcessMemory.cpp` application and launch it with the administrator privileges. You should specify the same target architecture for building as the Notepad application has.

This is a console output after successful execution of the application:
```
Result of reading dword at 0x1e0000 address = 0xdeadbeef
```
Output of the application contains a target absolute address of the both read and write operations. Also the read value from this address is printed too.

There are `WriteDword` and `ReadDword` wrapper functions in our example application for both `WriteProcessMemory` and `ReadProcessMemory` WinAPI functions. The wrappers encapsulate type casts and error processing. Both WinAPI function have a similar set of parameters:

| Parameter | Description |
| -- | -- |
| `hProc` | Handle of the process object which memory will be accessed |
| `address` | Absolute address of a memory area to access |
| `&result` or `&value` | Pointer to the buffer that will store a read data in case of `ReadProcessMemory` function. The buffer contains a data which will be written to a target process's memory in case of `WriteProcessMemory` function. |
| `sizeof(...)` | Number of bytes to read from the target process's memory or to write there |
| `NULL` | Pointer to a variable that stores an actual number of transferred bytes |

## TEB and PEB Access

Now we will consider ways to get a base addresses of the TEB segments in process's memory. Each thread of the process has own TEB segment. Each TEB segment stores information about a base address of the singular PEB segment. Therefore, when a task of accessing TEB is solved, you already have an access to information of PEB segment too. Accessing of TEB and PEB segments is important step for our task of analyzing the process's memory. TEB segment contains a base address of the corresponding thread's stack segment. PEB segment contains a base address of the default heap segment.

### Current Process

Methods, that allow to access a TEB segment of the current thread, will be considered here. Current thread is a thread from which the method of TEB segment accessing has been called. It is implied that the current thread is executed in the current process always.

There are several ways to get a TEB segment's base address of the current thread. First one is to use segment registers to access TEB segment in the same way as OS system do it. There are **FS segment register** for x86 architecture and **GS segment register** for x64 architecture. Both of these registers point to the TEB segment of the thread that is executed at the moment.
 
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
Definition of `TEB` structure may differ between Windows versions. The structure is defined in `winternal.h` header file that is provided by Windows SDK. You should clarify, how the structure looks like for your environment before to start working with it. This is an example of the structure for Windows 8.1 version:
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
You can see that `TEB` structure has a `ProcessEnvironmentBlock` field with a pointer to the `PEB` structure. This pointer can be used to access information of the PEB segment.

The approach of accessing a segment register via assembler inline code is not appropriate for x64 architecture. Visual Studio C++ compiler [does not support](https://msdn.microsoft.com/en-us/library/wbk4z78b.aspx) inline assembler for x64 target architecture. The [**compiler intrinsics**](https://msdn.microsoft.com/en-us/library/26td21ds.aspx) should be used instead of the inline assembler in this case.

There is a source code of the `GetTeb` function that has been rewritten with the compiler intrinsics:
```C++
#include <windows.h>
#include <winternl.h>

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
You can see that [`__readgsqword`](https://msdn.microsoft.com/en-us/library/htss0hyy.aspx) compiler intrinsic is used here to read a qword of 64-bit size with `0x30` offset from the GS segment register in case of x64 architecture. The [`__readfsdword`](https://msdn.microsoft.com/en-us/library/3887zk1s.aspx) intrinsic is used to read a double word of 32-bit size with `0x18` offset from the FS segment register in case of x86 architecture. This code is legal for both architectures and it can be used in your applications.

There is a question why a TEB segment should contain own linear address? [**Protected processor mode**](https://en.wikipedia.org/wiki/Protected_mode) is used by most of modern OS. Windows works in protected mode too. It means that [**segments addressing**](https://en.wikipedia.org/wiki/X86_memory_segmentation#Protected_mode) works via [**descriptor tables**](https://en.wikipedia.org/wiki/Global_Descriptor_Table) mechanism in our case. FS and GS registers actually contain a selector that defines the index of an entry inside the descriptor table. The descriptor table contains an actual base address of the TEB segment that matches to the specified index. This kind of request to descriptor table is performed by a segmentation unit of the CPU. Resulting address of a calculation performed by the segmentation unit is kept inside the CPU, and neither user application nor OS cannot access it. It is possible to access entries of the descriptor tables via [`GetThreadSelectorEntry `](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679363%28v=vs.85%29.aspx) and [`Wow64GetThreadSelectorEntry`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd709484%28v=vs.85%29.aspx) WinAPI functions. But this kind of memory reading operations leads to overhead. Overcome of the overhead is a probable reason, why TEB segment contains own linear address. There is [an example](http://reverseengineering.stackexchange.com/questions/3139/how-can-i-find-the-thread-local-storage-tls-of-a-windows-process-thread) of usage the `GetThreadSelectorEntry` function.

There is another question, why a memory area with a TEB segment's linear address has the different offsets inside the TEB segment for x86 and x64 architectures? There is a definition of the `NT_TIB` structure that is used for interpretation [**NT subsystem**](https://en.wikipedia.org/wiki/Architecture_of_Windows_NT) independent part of the TEB segment:
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
There are six fields with pointer values before the `Self` field in the `NT_TIB` structure. The pointer size equals to 32 bit or 4 byte for x86 architecture. It is increased to 64 bit or 8 byte for x64 architecture. Therefore, this is a calculation of the `Self` field's offset for the x86 architecture:
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
There is a [project](https://www.autoitscript.com/forum/topic/164693-implementation-of-a-standalone-teb-and-peb-read-method-for-the-simulation-of-getmodulehandle-and-getprocaddress-functions-for-loaded-pe-module/) where this code was originally presented. You can see that the same `__readgsqword` and `__readfsdword` compiler intrinsics are used here. Only one difference with the previous implementation of `GetTeb` function is usage of `PNT_TIB` pointer to the `NT_TIB` structure. It provides a portable calculation of the `Self` field's offset inside the `NT_TIB` structure.

Second way to get a TEB segment's base address of the current thread is usage of WinAPI functions. There is [`NtCurrentTeb`](https://msdn.microsoft.com/en-us/library/windows/hardware/hh285210%28v=vs.85%29.aspx) WinAPI function that performs exact the same work as the `GetTeb` functions above. It allows to get `TEB` structure for the current thread. This is an example of the `NtCurrentTeb` function usage:
```C++
#include <windows.h>
#include <winternl.h>

PTEB pTeb = NtCurrentTeb();
```
Now Windows should select an appropriate calculation with segment registers to obtain a TEB segment's base address. This is a primary benefit of usage the `NtCurrentTeb` function. Therefore, the function retrieves a correct result for all architectures supported by Windows such as x86, x64 and ARM.

[`NtQueryInformationThread`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684283%28v=vs.85%29.aspx) is a WinAPI function that allows you to retrieve information of any thread that is specified by thread object's handler. Base address of the TEB segment is provided by this information too. This is an implementation of the `GetTeb` function that is based on `NtQueryInformationThread` function usage:
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
There is a description of the input parameters of the `NtQueryInformationThread` function:

| Parameter | Description |
| -- | -- |
| `GetCurrentThread()` | Handle of the thread object which information will be retrieved. There is a handle to the current thread in this case. |
| `ThreadBasicInformation` | Constant of the `THREADINFOCLASS` enumeration type. Value of the constant defines a type of the resulting information i.e. type of the returning structure. |
| `&threadInfo` | Pointer to a structure for writing the function's result. |
| `sizeof(...)` | Size of the structure where function's result will be written |
| `NULL` | Pointer to a variable that stores an actual number of read bytes to the resulting structure |

There is only one constant with `ThreadIsIoPending` name in the `THREADINFOCLASS` enumeration, that is officially documented and defined in the `winternl.h` header file. All other possible constants are not documented officially by Microsoft, but you can find these in [the Internet](http://undocumented.ntinternals.net/UserMode/Undocumented%20Functions/NT%20Objects/Thread/THREAD_INFORMATION_CLASS.html). Your application should define own `THREADINFOCLASS` enumeration with extra undocumented constants. We have named this enumeration as `THREADINFOCLASS2`, and we have renamed a `ThreadIsIoPending` constant to `_ThreadIsIoPending` in our example. It allows to avoid a name conflict with the official `THREADINFOCLASS` enumeration from the included `winternl.h` header file. Also you should define the appropriate structure which will be used for receiving result of `NtQueryInformationThread` function. There is the `THREAD_BASIC_INFORMATION` structure in our case, that is match to `ThreadBasicInformation` enumeration constant. As you see, `THREAD_BASIC_INFORMATION` structure has the `TebBaseAddress` field. This field contains a linear address of the TEB segment.

`NtQueryInformationThread` function is provided by Windows Native API. The function is implemented in the `ntdll.dll` dynamic library. Windows SDK provides both `winternl.h` header file and `ntdll.lib` [**import library**](https://en.wikipedia.org/wiki/Dynamic-link_library#Import_libraries) that allow you to link with `ntdll.dll` library for calling its functions. We use a [**pragma directive**](https://msdn.microsoft.com/en-us/library/d9x1s805.aspx) here. This is a line that adds `ntdll.lib` file to the linker's list of import libraries:
```C++
#pragma comment(lib, "ntdll.lib")
```
There is a [`TebPebSelf.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebSelf.cpp) application that demonstrates all consider ways to get a TEB segment's base address of the current process.

### Another Process

Now we will consider methods to access TEB segments of the threads from another process. 

All following examples of analyzing another process have the same algorithm of launching:

1. Launch a 32-bit or 64-bit target application.
2. Get PID of the target process with Windows Task Manager application.
3. Assign the target process's PID to the `pid` variable in this line of `main` function:
```C++
DWORD pid = 5356;
```
4. Launch an example application with the administrator privileges.

First approach to get TEB segment's base address relies on assumption that base addresses of TEB segments are the same for all processes in system. We should get base addresses of the TEB segments for the current process, and than read memory at the same base addresses from the another process. There is a source code of [`TebPebMirror.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebMirror.cpp) application that implements this algorithm:
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
The application output contains three values in case of application's successful execution. There are a base address of the TEB segment of the main thread, a base address of the PEB segment and a base address of the stack segment. Base address of the TEB segment is printed from the `GetMainThreadTeb` function.

You can see that we are using here already considered approach to enable a `SE_DEBUG_NAME` privilege for the current process with `OpenProcessToken` and `SetPrivilege` functions. Then there is a call of `GetMainThreadTeb` function with the target process's PID parameter. This function contains three steps:

1. Call `NtCurrentTeb` WinAPI function to get TEB segment's base address of the current thread.
2. Call `OpenProcess` WinAPI function to receive a handler of the target process with `PROCESS_VM_READ` access.
3. Call `ReadProcessMemory` WinAPI function to read a memory of the target process at the base address that is equal to the TEB segment's base address of the current thread in the current process.

This approach is able to give stable results for analyzing 32-bit applications. The applications have the similar base addresses of TEB segments in case of the same environment. But the approach is totally not reliable for analyzing 64-bit applications. Base addresses of the TEB segments is able to vary each time when you launch 64-bit applications. Primary advantage of this approach is the ease of implementation.

It is important to emphasize that bitness of the `TebPebMirror.cpp` application should be the same as bitness of the analyzing process. If you want to analyze a 32-bit process, you should select a "x86" target architecture in the "Solution Platforms" control of the Visual Studio window. The "x64" target architecture should be chosen for analyzing 64-bit processes. This rule is appropriate for all our example applications which analyzes an another process.

Second approach to get TEB segment's base address from an another process relies on a set of WinAPI functions for traversing all thread objects in the system. This is a list of used WinAPI functions:

1. [`CreateToolhelp32Snapshot`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682489%28v=vs.85%29.aspx) function provides a system snapshot with processes and threads system objects, plus modules and heaps. You can specify the PID function's parameter to get modules and heaps of the specific process. The snapshot contains all threads that are launched in the system at the moment.
2. [`Thread32First`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686728%28v=vs.85%29.aspx) function is used to start a threads traversing for the specified system snapshot. It has output parameter with a pointer to [`THREADENTRY32`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686735%28v=vs.85%29.aspx) structure with information of the first thread in the snapshot.
3. [`Thread32Next`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686731%28v=vs.85%29.aspx) function is used to continue the threads traversing for the system snapshot. It has the same output parameter as the `Thread32First` function.

There is a source code of [`TebPebTraverse.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProcessMemoryAccess/TebPebTraverse.cpp) application that implements this algorithm:
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
The application output contains a list of threads of the target process in case of application's successful execution. Thread ID in terms of the system and a base address of the thread's TEB segment will be printed for each thread in the list.

There is only one call of `ListProcessThreads` function with the target process's PID parameter in the `main` function of the application. We do not need to enable a `SE_DEBUG_NAME` privilege for the current process here. The `TebPebTraverse.cpp` application does not debug any process. Instead it makes a system snapshot that requires the administrator privileges only.

The `ListProcessThreads` function performs these steps:

1. Make a system snapshot of all threads in the system with the `CreateToolhelp32Snapshot` WinAPI function.
2. Start traversing of the threads in the snapshot with `Thread32First` WinAPI function.
3. Check PID of the owner process for the current thread in the traversing loop. Call `GetTeb` function with a thread's handle parameter to get `TEB` structure via `NtQueryInformationThread` WinAPI function.
4. Print handle of the current thread in loop and resulting base address of its TEB segment.
5. Repeat steps 3 and 4 until all threads in the system snapshot are not enumerated with the `Thread32Next` WinAPI function.

This approach of accessing TEB segments of the target process provides more reliable results when previous one. It guarantees that TEB segments of all threads in the target process will be processed. Otherwise, you should create manually the same number of threads in the `TebPebMirror.cpp` application as the target process has. It allows you to get a base addresses of all TEB segments for the target process. But this threads counting and threads manually creation approach is error prone.

There is a question, how to distinguish threads that have been traversed with `Thread32Next` WinAPI function? For example, you are looking a base address of the stack for the main thread. `THREADENTRY32` structure does not contain information about thread's ID in term of the process. There are threads' IDs in term of the Object Manager of Windows. But you can rely on assumption that TEB segments is sorted in the reverse order. It means that the TEB segment with the maximum base address matches to the main thread. The TEB segment with the next lower base address matches to the thread with ID equals to 1 in terms of the target process. Then TEB segment with ID equals to 2 has the next lower base address and so on. You can check this assumption with a memory map of the target process that is provided by WinDbg debugger.

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

Also it is important to emphasize, that the order of a traversing heap segments matches to an ID numbering of the segments in terms of the target process. It means that segment with ID equal to 1 will be processed first by the `ListProcessHeaps` function. Then the segment with ID 2 will be processed and so on. This segments ordering allows to distinguish them when a bot application will looking for the game state variables.