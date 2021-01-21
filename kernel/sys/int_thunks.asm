; Interrupt thunks

section .bss
global int_event
align 16
int_event: resq 256

%macro raise_int 1
align 16
raise_int_%1:
jmp $
    lock inc dword [int_event+%1*8]
    iretq
%endmacro

section .text

%assign i 0
%rep 256
raise_int i
%assign i i+1
%endrep

section .data

%macro raise_int_getaddr 1
dq raise_int_%1
%endmacro

global int_thunks
int_thunks:
%assign i 0
%rep 256
raise_int_getaddr i
%assign i i+1
%endrep

section .rodata

syscall_count equ ((syscall_table.end - syscall_table) / 8)

align 16
syscall_table:
    extern syscall_debug_log
    dq syscall_debug_log
    extern syscall_mmap
    dq syscall_mmap
  .end:

section .text

global syscall_entry
syscall_entry:
    cmp rax, syscall_count   ; is syscall_number too big?
    jae .too_big

    swapgs

    mov qword [gs:0024], rsp ; save the user stack
    mov rsp, qword [gs:0016] ; switch to the kernel space stack for the thread

    sti
    cld

    push 0x1b            ; ss
    push qword [gs:0024] ; rsp
    push r11             ; rflags
    push 0x23            ; cs
    push rcx             ; rip

    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rbp
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax

    mov rdi, rsp

    call [syscall_table + rax * 8]

    pop rbx  ; trashed pop
    pop rbx
    pop rcx
    pop rdx
    pop rdi
    pop rsi
    pop rbp
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15

    mov rdx, qword [gs:0032] ; return errno in rdx

    cli

    mov rsp, qword [gs:0024] ; restore the user stack

    swapgs

    o64 sysret

  .too_big:
    mov rax, -1
    mov rdx, 1051  ; return ENOSYS
    o64 sysret
