; 程序功能：计算(A + B*20 - 30)/C + D，并以十进制输出结果

.MODEL SMALL    ; 定义程序为小型模型
.STACK 100H   ; 定义堆栈大小
.DATA
    ; 定义四个带符号自变量，可根据需要修改值
    A   DW  -10      ; 带符号变量A
    B   DW  3       ; 带符号变量B
    C   DW  2       ; 带符号变量C（注意不能为0,否则会导致除零错误）
    D   DW  -4       ; 带符号变量D
    
    ; 用于输出的常量和缓冲区
    MSG_RESULT DB 'Result: $'   ; 提示信息字符串
    BUFFER     DB 6 DUP(?) ; 用于存储十进制数字的缓冲区
    MINUS      DB '-'      ; 负号

.CODE
MAIN PROC   ; 主程序入口
    MOV AX, @DATA   ; 初始化数据段
    MOV DS, AX    ; 初始化数据段寄存器
    
    ; 显示提示信息
    MOV AH, 09H   ; 显示字符串功能码
    LEA DX, MSG_RESULT  ; 加载提示信息地址到DX
    INT 21H    ; 调用DOS中断
    
    ; 计算 B * 20
    MOV AX, B       ; AX = B
    MOV BX, 20      ; BX = 20
    IMUL BX         ; AX = B * 20 (带符号乘法)
    
    ; 计算 A + (B * 20)
    ADD AX, A       ; AX = A + B*20
    
    ; 计算 A + B*20 - 30
    SUB AX, 30      ; AX = A + B*20 - 30
    
    ; 计算 (A + B*20 - 30) / C
    MOV BX, C       ; BX = C
    IDIV BX         ; AX = (A + B*20 - 30) / C (带符号除法)
    
    ; 计算最终结果: (A + B*20 - 30)/C + D
    ADD AX, D       ; AX = 最终结果
    
    ; 输出结果
    CALL PRINT_SIGNED_DECIMAL
    
    ; 程序结束
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; 子程序：打印带符号十进制数（输入：AX=要打印的数）
PRINT_SIGNED_DECIMAL PROC
    PUSH AX   ; 保存寄存器状态
    PUSH BX   ; 保存寄存器状态
    PUSH CX   ; 保存寄存器状态
    PUSH DX     ; 保存寄存器状态
    PUSH SI     ; 保存寄存器状态
    
    ; 检查是否为负数
    CMP AX, 0   ; 检查AX是否为0或正数
    JGE POSITIVE    ; 如果是非负数，直接处理
    
    ; 是负数，先输出负号
    MOV AH, 02H   ; 显示字符功能码
    MOV DL, MINUS   ; 加载负号到DL
    INT 21H     ; 显示负号
    
    ; 取绝对值
    NEG AX          ; AX = -AX

POSITIVE:
    MOV SI, OFFSET BUFFER + 5  ; 指向缓冲区末尾
    MOV BX, 10                 ; 除数为10
    MOV CX, 0                  ; 计数：记录数字位数
    
; 将数字按位分解并存储到缓冲区（逆序）
DIVIDE_LOOP:
    MOV DX, 0                  ; 扩展AX到DX:AX
    IDIV BX                    ; 除以10，商在AX，余数在DX
    
    ADD DL, '0'                ; 将余数转换为ASCII码
    MOV [SI], DL               ; 存储到缓冲区
    DEC SI                     ; 移动到前一个位置
    INC CX                     ; 位数加1
    
    CMP AX, 0                  ; 如果商不为0，继续分解
    JNE DIVIDE_LOOP            ; 继续循环
    
; 从缓冲区输出数字（正序）
PRINT_LOOP:
    INC SI                     ; 移动到下一个位置
    MOV AH, 02H                 ; 显示字符功能码
    MOV DL, [SI]               ; 取出数字
    INT 21H                    ; 输出
    LOOP PRINT_LOOP             ; 继续循环直到所有数字都输出
    
    POP SI    ; 恢复寄存器状态
    POP DX    
    POP CX    
    POP BX    
    POP AX
    RET   ; 返回调用者
PRINT_SIGNED_DECIMAL ENDP  

END MAIN