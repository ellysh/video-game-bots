# Process Memory Access

## Open Process

There is [`OpenProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684320%28v=vs.85%29.aspx) WinAPI function that allows you to get a [**handle**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724457%28v=vs.85%29.aspx) of the process with specified process identifier ([PID](https://en.wikipedia.org/wiki/Process_identifier)). When you known a process's handle, you can access process's internals for example process's memory via WinAPI functions. 

All processes in Windows OS are special kind of objects. Objects are high-level abstractions for OS resources, such as a file, process or thread. All objects have an unified structure and they consist of header and body. Header contains meta information about an object that is used by [**Object Manager**](https://en.wikipedia.org/wiki/Object_Manager_%28Windows%29). Body contains object-specific data.

Windows [**security model**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374876%28v=vs.85%29.aspx) is responsible for controlling ability of a process to access objects or to perform various system administration tasks. The security model requires a process to have special privileges for accessing another process with `OpenProcess` function. [**Access token**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374909%28v=vs.85%29.aspx) is an object that allows you to manipulate of security attributes of a process. The access token can be used to grant necessary privileges for usage `OpenProcess` function.

This is a common algorithm of opening target process with `OpenProcess` function:

1. Get object's handle of a current process with [`GetCurrentProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683179%28v=vs.85%29.aspx) WinAPI function.
2. Get access token of the current process with a [`OpenProcessToken`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379295%28v=vs.85%29.aspx) WinAPI function.
3. Enable `SE_DEBUG_NAME` privilege for the current process by affecting process's access token with [`AdjustTokenPrivileges`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa375202%28v=vs.85%29.aspx) WinAPI function.
4. Get object's handle of the target process with `OpenProcess` function.

TODO: Detailed example of the `SetPrivilege` function:
https://msdn.microsoft.com/en-us/library/windows/desktop/aa446619%28v=vs.85%29.aspx
    
## Access Token

TODO: Check this MSDN article about Access Token:
https://technet.microsoft.com/en-us/library/cc759267%28v=ws.10%29.aspx

TODO: Check Object Manager subsystem of Windows:
https://en.wikipedia.org/wiki/Object_Manager_%28Windows%29

1. Access token is an object that contains information about the identity and privileges associated with a user account.

---

An access token is a protected object that contains information about the identity and privileges associated with a user account.

When a user logs on interactively or tries to make a network connection to a computer running Windows, the logon process authenticates the user’s logon credentials. If authentication is successful, the logon process returns a security identifier (SID) for the user and a list of SIDs for the user’s security groups. The Local Security Authority (LSA) on the computer uses this information to create an access token — in this case, the primary access token — that includes the SIDs returned by the logon process as well as a list of privileges assigned by local security policy to the user and to the users security groups.

After LSA creates the primary access token, a copy of the access token is attached to every process and thread that executes on the user’s behalf. Whenever a thread or process interacts with a securable object or tries to perform a system task that requires privileges, the operating system checks the access token associated with the thread to determine the level of authorization for the thread.

There are two kinds of access tokens, primary and impersonation. Every process has a primary token that describes the security context of the user account associated with the process. A primary access token is typically assigned to a process to represent the default security information for that process. Impersonation tokens, on the other hand, are usually used for client/server scenarios. Impersonation tokens enable a thread to execute in a security context that differs from the security context of the process that owns the thread.
