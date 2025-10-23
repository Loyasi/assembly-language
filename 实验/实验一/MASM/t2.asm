.model small
.stack 100h

.data
    prompt_keyword db 'Enter keyword:$'
    prompt_sentence db 'Enter Sentence:$'
    match_msg db 'Match at location:$'
    no_match_msg db 'No match!$'
    hex_suffix db 'H of the sentence.$'
    newline db 0dh, 0ah, '$'
    exit_msg db 'Program terminated by Ctrl+C$'
    
    keyword_buffer db 200 dup(?)     ; 关键字缓冲区
    sentence_buffer db 200 dup(?)    ; 句子缓冲区
    keyword_len dw 0                 ; 关键字长度
    sentence_len dw 0                ; 句子长度
    match_position dw 0              ; 匹配位置

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; 显示关键字输入提示
    call input_keyword
    
    ; 主循环：输入句子并搜索
main_loop:
    call input_sentence
    call search_keyword
    call display_result
    jmp main_loop
    
    mov ah, 4ch
    int 21h
main endp

; 输入关键字
input_keyword proc
    push ax
    push dx
    push si
    push cx
    
    ; 显示提示
    mov dx, offset prompt_keyword
    mov ah, 09h
    int 21h
    
    ; 使用字符输入来检测Ctrl+C
    mov si, offset keyword_buffer
    mov cx, 0
    
keyword_input_loop:
    ; 读取单个字符
    mov ah, 01h
    int 21h
    
    ; 检查是否是Ctrl+C (ASCII 3)
    cmp al, 03h
    je ctrl_c_exit_keyword
    
    ; 检查是否是回车
    cmp al, 0dh
    je keyword_input_done
    
    ; 检查缓冲区是否已满
    cmp cx, 198
    jge keyword_input_loop
    
    ; 存储字符
    mov byte ptr [si], al
    inc si
    inc cx
    jmp keyword_input_loop
    
keyword_input_done:
    ; 存储长度
    mov keyword_len, cx
    
    ; 在关键字末尾添加结束符
    mov byte ptr [si], 0
    
    ; 换行
    call print_newline
    
    pop cx
    pop si
    pop dx
    pop ax
    ret
    
ctrl_c_exit_keyword:
    ; 显示退出消息
    mov dx, offset newline
    mov ah, 09h
    int 21h
    mov dx, offset exit_msg
    mov ah, 09h
    int 21h
    mov dx, offset newline
    mov ah, 09h
    int 21h
    
    ; 退出程序
    mov ah, 4ch
    int 21h
input_keyword endp

; 输入句子
input_sentence proc
    push ax
    push dx
    push si
    push cx
    
    ; 显示提示
    mov dx, offset prompt_sentence
    mov ah, 09h
    int 21h
    
    ; 使用字符输入来检测Ctrl+C
    mov si, offset sentence_buffer
    mov cx, 0
    
input_loop:
    ; 读取单个字符
    mov ah, 01h
    int 21h
    
    ; 检查是否是Ctrl+C (ASCII 3)
    cmp al, 03h
    je ctrl_c_exit_sentence
    
    ; 检查是否是回车
    cmp al, 0dh
    je input_done
    
    ; 检查缓冲区是否已满
    cmp cx, 198
    jge input_loop
    
    ; 存储字符
    mov byte ptr [si], al
    inc si
    inc cx
    jmp input_loop
    
input_done:
    ; 存储长度
    mov sentence_len, cx
    
    ; 在句子末尾添加结束符
    mov byte ptr [si], 0
    
    ; 换行
    call print_newline
    
    pop cx
    pop si
    pop dx
    pop ax
    ret
    
ctrl_c_exit_sentence:
    ; 显示退出消息
    mov dx, offset newline
    mov ah, 09h
    int 21h
    mov dx, offset exit_msg
    mov ah, 09h
    int 21h
    mov dx, offset newline
    mov ah, 09h
    int 21h
    
    ; 退出程序
    mov ah, 4ch
    int 21h
input_sentence endp

; 搜索关键字
search_keyword proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; 检查句子长度是否有效
    cmp sentence_len, 0
    je no_match_found
    
    mov cx, sentence_len
    cmp cx, keyword_len
    jl no_match_found
    
    ; 计算最大搜索位置
    mov ax, sentence_len
    sub ax, keyword_len
    inc ax
    mov cx, ax
    
    mov si, offset sentence_buffer  ; 句子开始位置
    mov di, offset keyword_buffer   ; 关键字开始位置
    mov bx, 1                       ; 当前位置计数器（从1开始）
    
search_loop:
    push cx
    push si
    push di
    push bx
    
    ; 比较当前位置的字符
    mov cx, keyword_len
compare_loop:
    mov al, byte ptr [si]
    mov bl, byte ptr [di]
    cmp al, bl
    jne not_match
    inc si
    inc di
    loop compare_loop
    
    ; 找到匹配
    pop bx
    pop di
    pop si
    pop cx
    
    ; 保存匹配位置
    mov match_position, bx
    jmp match_found
    
not_match:
    pop bx
    pop di
    pop si
    pop cx
    inc si
    inc bx
    loop search_loop
    
no_match_found:
    mov match_position, 0
    jmp search_end
    
match_found:
    ; 匹配成功，match_position已设置
    
search_end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
search_keyword endp

; 显示结果
display_result proc
    push ax
    push dx
    
    cmp match_position, 0
    je show_no_match
    
    ; 显示匹配信息
    mov dx, offset match_msg
    mov ah, 09h
    int 21h
    
    ; 显示位置（十六进制）
    mov ax, match_position
    call print_hex
    
    ; 显示后缀
    mov dx, offset hex_suffix
    mov ah, 09h
    int 21h
    
    call print_newline
    jmp display_end
    
show_no_match:
    mov dx, offset no_match_msg
    mov ah, 09h
    int 21h
    call print_newline
    
display_end:
    pop dx
    pop ax
    ret
display_result endp

; 打印十六进制数
print_hex proc
    push ax
    push bx
    push cx
    push dx
    
    mov bx, ax
    mov cx, 4
    
hex_loop:
    push cx
    mov ax, bx
    and ax, 0f000h
    mov cl, 12
    shr ax, cl
    
    cmp al, 9
    jle digit
    add al, 7
    
digit:
    add al, 30h
    mov dl, al
    mov ah, 02h
    int 21h
    
    mov cl, 4
    shl bx, cl
    pop cx
    loop hex_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex endp

; 打印换行
print_newline proc
    push ax
    push dx
    
    mov dx, offset newline
    mov ah, 09h
    int 21h
    
    pop dx
    pop ax
    ret
print_newline endp

end main