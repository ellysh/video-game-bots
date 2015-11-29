# Process Memory Analyzing

## Process Memory Overview

Process memory topic has been already described in many books in articles. We will consider points of the topic here that are the most important for practical goal of analyzing process memory.

First of all, it will be useful to emphasize a difference between an executable binary file and a working process from point of view of provided information for analyzing. We can compare executable file with a bowl. This bowl defines a future form of the poured liquid of data. Executable file contains algorithms for processing data, implicit description of ways to interpret data, global and static variables. Data description is represented by encoded rules of [**type system**](https://en.wikipedia.org/wiki/Type_system). Therefore, it is possible to investigate ways of data processing and representation, and values of initialized global and static variables from analyzing the executable file. When executable file is launched the liquid starts to pour in into the bowl. OS load executable file into the memory and starts to execute file's instructions. Typical results of instructions execution are allocation, modification or deallocation memory. It means that you can get actual information of application's work in the [**run-time**](https://en.wikipedia.org/wiki/Run_time_%28program_lifecycle_phase%29) only.

TODO: Make a picture of the Windows process components (process, modules, threads)

TODO: Make a picture of process memory (stack, heap, module's segments)

## Variables Searching 

### Search in Module's Segments

### Search in Heap

TODO: Describe the heap growing process with example application

TODO: Describe WinAPI functions for looking for all heap's segments

### Search in Stack

TODO: Describe the stack growing process with example application

TODO: Describe WinAPI functions for looking for all stack's segments
