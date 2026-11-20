org 100h

; ============================================================
;  STUDENT INFORMATION SYSTEM - Simplified Version
;  NASM 16-bit COM file for DOSBox
; ============================================================

section .data

; ---- MENU ----
main_menu   db 13,10,'===== STUDENT INFORMATION SYSTEM =====',13,10
            db '1. Add New Student',13,10
            db '2. View Student',13,10
            db '3. Update Fee',13,10
            db '4. Update Attendance',13,10
            db '5. Update Marks',13,10
            db '6. Update Status',13,10
            db '7. Update Health',13,10
            db '0. Exit',13,10
            db 'Enter choice: $'

; ---- PROMPTS ----
pr_name     db 13,10,'Enter Name: $'
pr_age      db 13,10,'Enter Age (10-30): $'
pr_age_inv  db 13,10,'Invalid! Age must be 10-30.',13,10,'$'
pr_cls      db 13,10,'Enter Class: $'
pr_id       db 13,10,'Enter Student ID (1-5): $'
pr_fee      db 13,10,'Enter Fee (0-9): $'
pr_att      db 13,10,'Attendance days (0-9): $'
pr_marks    db 13,10,'Enter Marks (0-9 for tens): $'
pr_status   db 13,10,'Status: 1=In-Study  2=Left  3=Complete : $'
pr_health   db 13,10,'Any disability? 1=Yes  0=No : $'
pr_dis      db 13,10,'Enter disability note: $'

; ---- MESSAGES ----
msg_saved   db 13,10,'Saved!',13,10,'$'
msg_nf      db 13,10,'Not Found!',13,10,'$'
msg_full    db 13,10,'System Full!',13,10,'$'
msg_empty   db 13,10,'No students yet.',13,10,'$'
msg_bye     db 13,10,'Goodbye!',13,10,'$'
msg_inv     db 13,10,'Invalid!',13,10,'$'
msg_sep     db 13,10,'---------------------------',13,10,'$'

; ---- STATUS STRINGS ----
st_in       db 'In-Study$'
st_lft      db 'Left$'
st_cmp      db 'Complete$'

; ---- HEALTH STRINGS ----
str_yes     db 'Yes$'
str_no      db 'No$'
lb_dis      db 13,10,' Disab: $'

; ---- DISPLAY LABELS ----
lb_id       db ' ID    : $'
lb_name     db 13,10,' Name  : $'
lb_age      db 13,10,' Age   : $'
lb_cls      db 13,10,' Class : $'
lb_fee      db 13,10,' Fee   : $'
lb_att      db 13,10,' Att   : $'
lb_mrk      db 13,10,' Marks : $'
lb_stat     db 13,10,' Status: $'
lb_hlth     db 13,10,' Health: $'
lb_nl       db 13,10,'$'

; ============================================================
; STUDENT DATA ARRAYS (max 5 students)
; ============================================================
MAX_S       equ 5

s_count     db 0

s_id        db 0,0,0,0,0
s_name      times 5*21 db '$'
s_age       db 0,0,0,0,0
s_cls       times 5*21 db '$'
s_fee       db 0,0,0,0,0
s_att       db 0,0,0,0,0
s_marks     db 0,0,0,0,0
s_status    db 1,1,1,1,1        ; 1=In-Study, 2=Left, 3=Complete
s_health    db 0,0,0,0,0        ; 0=No disability, 1=Has disability
s_disnote   times 5*21 db '$'   ; disability description

found_idx   db 0

section .text

; ============================================================
; START
; ============================================================
start:
    call clrscr
.loop:
    mov dx, main_menu
    call pstr
    call getch

    cmp al, '1'
    je  .add
    cmp al, '2'
    je  .view
    cmp al, '3'
    je  .fee
    cmp al, '4'
    je  .att
    cmp al, '5'
    je  .mrk
    cmp al, '6'
    je  .stat
    cmp al, '7'
    je  .hlth
    cmp al, '0'
    je  .quit
    mov dx, msg_inv
    call pstr
    jmp .loop

.add:   call add_student  
        jmp .loop
.view:  call view_student 
        jmp .loop
.fee:   call upd_fee      
        jmp .loop
.att:   call upd_att      
        jmp .loop
.mrk:   call upd_marks    
        jmp .loop
.stat:  call upd_status   
        jmp .loop
.hlth:  call upd_health   
        jmp .loop
.quit:
    mov dx, msg_bye
    call pstr
    mov ax, 4C00h
    int 21h

; ============================================================
; ADD STUDENT
; ============================================================
add_student:
    push ax
    push bx
    push si

    mov al, [s_count]
    cmp al, MAX_S
    jl  .ok
    mov dx, msg_full
    call pstr
    jmp .done

.ok:
    xor bh, bh
    mov bl, [s_count]       ; BL = index

    ; Set ID
    mov al, bl
    inc al
    mov [s_id + bx], al

    ; Name
    mov dx, pr_name
    call pstr
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_name
    add si, ax
    pop bx
    call read_str

    ; Age (10-30)
.age_retry:
    mov dx, pr_age
    call pstr
    call read_num_byte
    cmp al, 10
    jl  .age_bad
    cmp al, 30
    jg  .age_bad
    mov [s_age + bx], al
    jmp .age_ok
.age_bad:
    mov dx, pr_age_inv
    call pstr
    jmp .age_retry
.age_ok:

    ; Class
    mov dx, pr_cls
    call pstr
    push bx
    mov ax, bx
    push ax
    mov bx, 21
    mul bx
    mov si, s_cls
    add si, ax
    pop ax
    pop bx
    call read_str

    ; Defaults
    mov byte [s_fee    + bx], 0
    mov byte [s_att    + bx], 0
    mov byte [s_marks  + bx], 0
    mov byte [s_status + bx], 1   ; In-Study
    mov byte [s_health + bx], 0   ; No disability

    ; Default disnote = '$'
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_disnote
    add si, ax
    pop bx
    mov byte [si], '$'

    inc byte [s_count]
    mov dx, msg_saved
    call pstr

.done:
    pop si
    pop bx
    pop ax
    ret

; ============================================================
; FIND STUDENT BY ID
; Returns BX = index (0-based), CF=0 found / CF=1 not found
; ============================================================
find_student:
    push ax
    push cx

    mov dx, pr_id
    call pstr
    call getch
    sub al, '0'

    xor bx, bx
    mov cl, [s_count]
    xor ch, ch

.lp:
    cmp bx, cx
    jge .nf
    cmp [s_id + bx], al
    je  .found
    inc bx
    jmp .lp

.found:
    mov [found_idx], bl
    clc
    pop cx
    pop ax
    ret
.nf:
    stc
    pop cx
    pop ax
    ret

; ============================================================
; SHOW ONE STUDENT  (BX = 0-based index)
; ============================================================
show_student:
    push ax
    push si

    mov dx, msg_sep
    call pstr

    ; ID
    mov dx, lb_id
    call pstr
    mov al, [s_id + bx]
    add al, '0'
    call putch

    ; Name
    mov dx, lb_name
    call pstr
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_name
    add si, ax
    pop bx
    mov dx, si
    call pstr

    ; Age
    mov dx, lb_age
    call pstr
    mov al, [s_age + bx]
    call print_byte_dec

    ; Class
    mov dx, lb_cls
    call pstr
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_cls
    add si, ax
    pop bx
    mov dx, si
    call pstr

    ; Fee
    mov dx, lb_fee
    call pstr
    mov al, [s_fee + bx]
    add al, '0'
    call putch

    ; Attendance
    mov dx, lb_att
    call pstr
    mov al, [s_att + bx]
    add al, '0'
    call putch

    ; Marks
    mov dx, lb_mrk
    call pstr
    mov al, [s_marks + bx]
    add al, '0'
    call putch
    mov al, '0'
    call putch

    ; Status
    mov dx, lb_stat
    call pstr
    mov al, [s_status + bx]
    cmp al, 2
    je  .slft
    cmp al, 3
    je  .scmp
    mov dx, st_in
    jmp .pstat
.slft:
    mov dx, st_lft
    jmp .pstat
.scmp:
    mov dx, st_cmp
.pstat:
    call pstr

    ; Health
    mov dx, lb_hlth
    call pstr
    mov al, [s_health + bx]
    cmp al, 1
    je  .has_dis
    mov dx, str_no
    call pstr
    jmp .done
.has_dis:
    mov dx, str_yes
    call pstr
    mov dx, lb_dis
    call pstr
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_disnote
    add si, ax
    pop bx
    mov dx, si
    call pstr

.done:
    mov dx, lb_nl
    call pstr
    pop si
    pop ax
    ret

; ============================================================
; VIEW ONE STUDENT (by ID)
; ============================================================
view_student:
    push bx
    call find_student
    jc  .nf
    call show_student
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop bx
    ret

; ============================================================
; UPDATE FEE
; ============================================================
upd_fee:
    push ax
    push bx
    call find_student
    jc  .nf
    mov dx, pr_fee
    call pstr
    call getch
    sub al, '0'
    mov [s_fee + bx], al
    mov dx, msg_saved
    call pstr
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop bx
    pop ax
    ret

; ============================================================
; UPDATE ATTENDANCE
; ============================================================
upd_att:
    push ax
    push bx
    call find_student
    jc  .nf
    mov dx, pr_att
    call pstr
    call getch
    sub al, '0'
    mov [s_att + bx], al
    mov dx, msg_saved
    call pstr
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop bx
    pop ax
    ret

; ============================================================
; UPDATE MARKS
; ============================================================
upd_marks:
    push ax
    push bx
    call find_student
    jc  .nf
    mov dx, pr_marks
    call pstr
    call getch
    sub al, '0'
    mov [s_marks + bx], al
    mov dx, msg_saved
    call pstr
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop bx
    pop ax
    ret

; ============================================================
; UPDATE STATUS  (1=In-Study  2=Left  3=Complete)
; ============================================================
upd_status:
    push ax
    push bx
    call find_student
    jc  .nf
    mov dx, pr_status
    call pstr
    call getch
    cmp al, '1'
    je  .s1
    cmp al, '2'
    je  .s2
    cmp al, '3'
    je  .s3
    mov dx, msg_inv
    call pstr
    jmp .done
.s1:
    mov byte [s_status + bx], 1
    jmp .save
.s2:
    mov byte [s_status + bx], 2
    jmp .save
.s3:
    mov byte [s_status + bx], 3
.save:
    mov dx, msg_saved
    call pstr
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop bx
    pop ax
    ret

; ============================================================
; UPDATE HEALTH
; ============================================================
upd_health:
    push ax
    push bx
    push si
    call find_student
    jc  .nf

    mov dx, pr_health
    call pstr
    call getch
    cmp al, '1'
    je  .has_dis
    ; No disability
    mov byte [s_health + bx], 0
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_disnote
    add si, ax
    pop bx
    mov byte [si], '$'
    jmp .save

.has_dis:
    mov byte [s_health + bx], 1
    mov dx, pr_dis
    call pstr
    push bx
    mov ax, bx
    mov bx, 21
    mul bx
    mov si, s_disnote
    add si, ax
    pop bx
    call read_str

.save:
    mov dx, msg_saved
    call pstr
    jmp .done
.nf:
    mov dx, msg_nf
    call pstr
.done:
    pop si
    pop bx
    pop ax
    ret

; ============================================================
; READ STRING into SI — reads until Enter, max 20 chars, '$' terminated
; ============================================================
read_str:
    push ax
    push cx
    push si
    mov cx, 20
.rl:
    mov ah, 01h
    int 21h
    cmp al, 13
    je  .rd
    cmp cx, 0
    je  .rd
    mov [si], al
    inc si
    dec cx
    jmp .rl
.rd:
    mov byte [si], '$'
    mov dx, lb_nl
    call pstr
    pop si
    pop cx
    pop ax
    ret

; ============================================================
; READ 2-DIGIT NUMBER — returns AL = value
; ============================================================
read_num_byte:
    push bx
    push cx
    xor bx, bx
.rn:
    mov ah, 01h
    int 21h
    cmp al, 13
    je  .rnd
    cmp al, '0'
    jl  .rn
    cmp al, '9'
    jg  .rn
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov cx, 10
    mul cx
    pop cx
    add ax, cx
    mov bx, ax
    jmp .rn
.rnd:
    mov ax, bx
    mov dx, lb_nl
    call pstr
    pop cx
    pop bx
    ret

; ============================================================
; PRINT BYTE AS DECIMAL  AL = value (0-99)
; ============================================================
print_byte_dec:
    push ax
    push cx
    push dx
    xor ah, ah
    mov cl, 10
    div cl
    cmp al, 0
    je  .sk
    add al, '0'
    call putch
.sk:
    mov al, ah
    add al, '0'
    call putch
    pop dx
    pop cx
    pop ax
    ret

; ============================================================
; PRINT STRING   DX = address ending with '$'
; ============================================================
pstr:
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret

; ============================================================
; GET SINGLE CHAR  -> AL
; ============================================================
getch:
    push bx
    push cx
    push dx
    mov ah, 01h
    int 21h
    pop dx
    pop cx
    pop bx
    ret

; ============================================================
; PRINT SINGLE CHAR  AL = char
; ============================================================
putch:
    push ax
    push bx
    push dx
    mov dl, al
    mov ah, 02h
    int 21h
    pop dx
    pop bx
    pop ax
    ret

; ============================================================
; CLEAR SCREEN
; ============================================================
clrscr:
    push ax
    push bx
    push cx
    push dx
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dx, 0000h
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret