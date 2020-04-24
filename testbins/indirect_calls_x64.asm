; The point here is to test the ability to pass runtime information to analysis.
;
; The same `call ebx` is executed 4 times, see label ".dispatch".
; The first two times are with functions identified by analysis.
; The second two times evade analysis and require runtime information.
; Binja should make functions in the second two cases and add comments of runtime
; annotation option is enabled.

default rel
global start
section .text

start:
	mov		rcx, 4

.next:
	push	rcx

.test4:
	cmp		rcx, 4
	jne		.test3
	lea		rbx, [print_00]
	jmp		.dispatch

.test3:
	cmp		rcx, 3
	jne		.test2
	lea		rbx, [print_01]
	jmp		.dispatch

.test2:
	cmp		rcx, 2
	jne		.test1
	lea		rbx, [junk]
	mov		rdi, 96 ; -> 48
	call	mapper
	add		rbx, rax
	jmp		.dispatch

.test1:
	cmp		rcx, 1
	lea		rbx, [junk]
	mov		rdi, 284 ; -> 142
	call	mapper
	add		rbx, rax

.dispatch:
	call	rbx						; <-------- HERE

.check:
	pop		rcx
	loop	.next

	; done
	mov		rax, 0x2000001 ; exit
	mov		rdi, 0
	syscall
	ret

print_00:
	lea		rsi, [.msg_start]
	lea		rdx, [.done]
	sub		rdx, rsi
	mov		rdi, 1 ; stdout
	mov		rax, 0x2000004 ; write
	syscall
	jmp		.done
.msg_start:
	db		"I'm print_00!", 0x0a
.done:
	ret

print_01:
	mov		rsi, .msg_start
	mov		rdx, .done
	sub		rdx, rsi
	mov		rdi, 1 ; stdout
	mov		rax, 0x2000004 ; write
	syscall
	jmp		.done
.msg_start:
	db		"I'm print_01!", 0x0a
.done:
	ret

junk:
; junk
db 0xEF, 0x3D, 0x53, 0x7C, 0xFB, 0x80, 0x3B, 0x28,
db 0x15, 0xD1, 0xA2, 0xCD, 0x5E, 0x7E, 0xBC, 0xE1,
db 0xC6, 0x1B, 0x63, 0x05, 0xB7, 0xD3, 0xBA, 0x3B,
db 0x39, 0xCA, 0x46, 0xA1, 0x32, 0xD9, 0x8A, 0xB5,
db 0x8F, 0xD6, 0xFA, 0xAE, 0x08, 0x2D, 0xD5, 0x6F,
db 0x1E, 0xD6, 0xB8, 0x72, 0xA9, 0x8D, 0x86, 0xE8

; junk + 0x30
; hidden function
db 0x48, 0x8D, 0x35, 0x18, 0x00, 0x00, 0x00,        ; lea        rsi, [.msg_start]
db 0x48, 0x8D, 0x15, 0x1F, 0x00, 0x00, 0x00,        ; lea        rdx, [.done]
db 0x48, 0x29, 0xF2                                 ; sub        rdx, rsi
db 0xBF, 0x01, 0x00, 0x00, 0x00                     ; mov        rdi, 1 ; stdout
db 0xB8, 0x04, 0x00, 0x00, 0x02                     ; mov        rax, 0x2000004 ; write
db 0x0F, 0x05                                       ; syscall
db 0xEB, 0x0E                                       ; jmp        .done
; .msg_start: "YOU FOUND ME1"
db  0x59, 0x4F, 0x55, 0x20, 0x46, 0x4F, 0x55, 0x4E, 0x44, 0x20, 0x4D, 0x45, 0x31, 0x0a
; .done:
db 0xC3                                             ; ret

; junk + 0x5e
db 0xB4, 0xDE, 0xF0, 0x6B, 0x54, 0x40, 0x08, 0x46,
db 0xF6, 0xAC, 0xDD, 0x82, 0x8C, 0x74, 0x2C, 0x7F,
db 0xBD, 0x0B, 0xC1, 0xBA, 0x12, 0x1F, 0xD0, 0x7C,
db 0x44, 0xFF, 0x43, 0x5F, 0xC6, 0x85, 0xF3, 0x23,
db 0x6B, 0x65, 0x41, 0x2C, 0xB4, 0x4A, 0x5E, 0x24,
db 0x35, 0xBA, 0x57, 0x76, 0x18, 0xAB, 0xE0, 0x51

; junk + 0x8e
; hidden function
db 0x48, 0x8D, 0x35, 0x18, 0x00, 0x00, 0x00,        ; lea        rsi, [.msg_start]
db 0x48, 0x8D, 0x15, 0x1F, 0x00, 0x00, 0x00,        ; lea        rdx, [.done]
db 0x48, 0x29, 0xF2                                 ; sub        rdx, rsi
db 0xBF, 0x01, 0x00, 0x00, 0x00                     ; mov        rdi, 1 ; stdout
db 0xB8, 0x04, 0x00, 0x00, 0x02                     ; mov        rax, 0x2000004 ; write
db 0x0F, 0x05                                       ; syscall
db 0xEB, 0x0E                                       ; jmp        .done
; .msg_start: "YOU FOUND ME2"
db  0x59, 0x4F, 0x55, 0x20, 0x46, 0x4F, 0x55, 0x4E, 0x44, 0x20, 0x4D, 0x45, 0x32, 0x0a
; .done:
db 0xC3                                             ; ret

mapper:
	mov		rax, rdi	; arg0: number to map
	shr		rax, 1
	ret