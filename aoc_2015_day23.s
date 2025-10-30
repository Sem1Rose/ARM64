.section .text
.global _start

_start:
    adr     x0, file
    mov     x1, xzr
    bl      open_relative

    mov     x19, x0         // save the fd
    sub     sp, sp, #0xf0
    mov     x20, sp         // read buffer 16 bytes
    add     x20, x20, #0x10

    mov     x21, xzr        // a register
    mov     x22, xzr        // b register
    mov     x23, x20        // line/byte offset table
    add     x23, x23, #0x20 // 104 total entries 
    mov     x24, xzr        // bytes read, half-word
    mov     x25, xzr        // line num

loop:
    mov     x0, #2
    mul     x0, x25, x0
    strh    w24, [x23, x0]

    mov     x0, x19
    mov     x1, x20
    mov     x2, #4
    bl      read
    cbz     x0, loop_end

    ldr     w0, [x20]
    and     w1, w0, #0xff
    cmp     w1, #'h'
    bne     skiph

    bl      hlf

    b       continue
skiph:
    cmp     w1, #'t'
    bne     skipt

    bl      tpl

    b       continue
skipt:
    cmp     w1, #'i'
    bne     skipi

    bl      inc

    b       continue
skipi:
    cmp     w1, #'j'
    mov     x2, x0
    mov     x0, #1
    bne     exit
    mov     x0, x2
    

    lsr     w0, w0, #8
    and     w1, w0, #0xff
    cmp     w1, 'm'
    bne     skipm
    
    bl      jmp
    
    b       continue
skipm:
    cmp     w1, #'i'
    mov     x2, x0
    mov     x0, #1
    bne     exit
    mov     x0, x2
    
    lsr     w0, w0, #8
    and     w1, w0, #0xff
    cmp     w1, #'o'
    bne     skipo
    
    bl      jio

    b       continue
skipo:
    cmp     w1, #'e'
    mov     x0, #1
    bne     exit
    
    bl      jie
continue:
    add     x25,x25, #1
    b       loop
loop_end:
    mov     x0, x19
    bl      close

    sub     sp, sp, #0x30
    mov     x7, sp

    mov     w0, 0x2061          // "a "
    movk    w0, 0x203d, lsl #16 // "= "
    str     x0, [x7], #4

    mov     x0, x21
    mov     x1, x7
    bl      u64_to_ascii
    add     x7, x7, x0
    
    mov     w0, 0x2062          // "b "
    movk    w0, 0x203d, lsl #16 // "= "
    str     x0, [x7], #4

    mov     x0, x22
    mov     x1, x7
    bl      u64_to_ascii
    add     x7, x7, x0

    mov     x0, sp
    sub     x1, x7, x0
    bl      write

    add     sp, sp, #0x30

    mov     x0, xzr
    b       exit


get_register:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    mov     x0, x19
    mov     x1, x20
    mov     x2, #2
    bl      read
    
    ldr     w0, [x20]
    and     w1, w0, #0xff
    cmp     w1, #'a'

    mov     x0, xzr
    beq     not_b
    mov     x0, #1
not_b:
    ldp     fp, lr, [sp], #0x10
    ret


get_offset:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    mov     x0, x19
    mov     x1, x20
    mov     x2, #1
    bl      read
    
    ldrb    w0, [x20]
    cmp     w0, '-'

    mov     x1, xzr
    bne     no_minus
    mov     x1, #1
no_minus:
    mov     x3, xzr     // num
    mov     x4, x1      // negative?
    mov     x5, #10
read_loop:
    mov     x0, x19
    mov     x1, x20
    mov     x2, #1
    bl      read

    ldrb    w0, [x20]
    cmp     w0, 0xA         // ascii line feed
    ble     read_end

    sub     x0, x0, #'0'
    madd    x3, x3, x5, x0
    
    b       read_loop
read_end:
    cbz     x4, not_neg
    neg     x3, x3
not_neg:
    mov     x0, x3

    ldp     fp, lr, [sp], #0x10
    ret


hlf:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    bl      get_register
    cbnz    x0, hlf_b

    lsr     x21, x21, #1
    b       hlf_end
hlf_b:
    lsr     x22, x22, #1
hlf_end:
    ldp     fp, lr, [sp], #0x10
    ret


tpl:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    bl      get_register

    mov     x1, #3
    cbnz    x0, tpl_b

    mul     x21, x21, x1
    b       tpl_end
tpl_b:
    mul     x22, x22, x1
tpl_end:
    ldp     fp, lr, [sp], #0x10
    ret


inc:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    bl      get_register
    cbnz    x0, inc_b

    add     x21, x21, #1
    b       inc_end
inc_b:
    add     x22, x22, #1
inc_end:
    ldp     fp, lr, [sp], #0x10
    ret


jump_to_offset:
    stp     fp, lr, [sp, #-0x20]!
    stp     x26, x27, [sp, #0x10]
    mov     fp, sp

    cbz     x0, offset_zero
    cmp     x0, #1
    beq     jump_end
    cmp     x0, xzr
    bgt     offset_positive
offset_negative:
    adds    x25, x25, x0
    mov     x0, #1
    bmi     exit            // branch if (mi)nus / negative

    mov     x1, #2
    mul     x1, x25, x1
    ldrh    w24, [x23, x1]
    sub     x25, x25, #1

    b       jump_end
offset_positive:
    sub     x26, x0, #1
positive_loop:
    add     x25, x25, #1
    mov     x1, #2
    mul     x1, x25, x1
    strh    w24, [x23, x1]
line_end_loop:    
    mov     x0, x19
    mov     x1, x20
    mov     x2, #1
    bl      read
    mov     x1, x0          // read error: end of file or other error
    mov     x0, #1
    cmp     x1, #0
    ble     exit

    ldrb    w0, [x20]
    cmp     w0, #0xA
    bgt     line_end_loop

    subs    x26, x26, #1
    bne     positive_loop   // branch if z=1 | previous operation (x26) resulted in zero

    b       jump_end
offset_zero:
    mov     x1, #2
    mul     x1, x25, x1
    ldrh    w24, [x23, x1]
    sub     x25, x25, #1

    b       jump_end
jump_end:
    mov     x0, x19
    mov     x1, x24
    bl      lseek

    ldp     fp, lr, [sp], #0x10
    ldp     x26, x27, [sp], #0x10
    ret


jmp:
    stp     fp, lr, [sp, #-0x10]!
    mov     fp, sp

    bl      get_offset
    bl      jump_to_offset

    ldp     fp, lr, [sp], #0x10
    ret


jio:
    stp     fp, lr, [sp, #-0x20]!
    stp     x26, x27, [sp, #0x10]
    mov     fp, sp

    bl      get_register
    mov     x26, x0

    mov     x0, x19
    mov     x1, x20
    mov     x2, #1
    bl      read            // extra space between register and offset

    bl      get_offset
    
    cmp     x26, #0
    bne     jio_b
    cmp     x21, #1
    b       jio_condition
jio_b:
    cmp     x22, #1
jio_condition:
    bne     jio_end
    bl      jump_to_offset
jio_end:
    ldp     fp, lr, [sp], #0x10
    ldp     x26, x27, [sp], #0x10
    ret


jie:
    stp     fp, lr, [sp, #-0x20]!
    stp     x26, x27, [sp, #0x10]
    mov     fp, sp

    bl      get_register
    mov     x26, x0

    mov     x0, x19
    mov     x1, x20
    mov     x2, #1
    bl      read            // extra space between register and offset

    bl      get_offset

    cmp     x26, #0
    bne     jie_b
    ands    xzr, x21, #1
    b       jie_condition
jie_b:
    ands    xzr, x22, #1
jie_condition:
    bne     jie_end
    bl      jump_to_offset
jie_end:
    ldp     fp, lr, [sp], #0x10
    ldp     x26, x27, [sp], #0x10
    ret


// ascii_to_u64(void *buf)
ascii_to_u64:
    mov     x3, #10
    mov     x1, x0
    mov     x0, xzr
ascii_to_u64_loop:
    ldrb    w2, [x1], #1

    cmp     x2, #0xA        
    ble     ascii_to_u64_end // line feed | null byte: end of input

    sub     x2, x2, #'0'
    madd    x0, x0, x3, x2

    b       ascii_to_u64_loop
ascii_to_u64_end:
    ret


// u64_to_ascii(u64 num, char* buffer)
u64_to_ascii:
    stp     fp, lr, [sp, #-0x30]!
    mov     fp, sp

    mov     x6, x1
    mov     x5, #10
    add     x4, sp, #0x10   // buffer
    add     x4, x4, #21     // max u64 digits
    mov     x3, xzr         // extracted num
    mov     x2, #0xA        // Line feed
    strb    w2, [x4], #-1
    mov     x1, #1          // char count
    cbz     x0, add_digit
get_next_digit:
    udiv    x2, x0, x5
    msub    x3, x2, x5, x0
    mov     x0, x2
add_digit:
    add     x3, x3, #'0'
    strb    w3, [x4], #-1
    add     x1, x1, #1

    cbnz    x0, get_next_digit

    mov     x0, x1
move_to_buff_loop:
    ldrb    w2, [x4, #1]!
    strb    w2, [x6], #1

    subs    x1, x1, #1
    bne     move_to_buff_loop

    ldp     fp, lr, [sp], #0x30
    ret


// open_relative(char* filename, int flags)
open_relative: 
    mov     x2, x1
    mov     x1, x0
    mov     x0, #-100
    // openat(int dfd, char* filename, int flags)
    mov     w8, #56
    svc     #0

    ret


// read(int fd, void* buffer, int count)
read:
    add     x24, x24, x2    // supposed to be the output of the syscall, but i assume the syscall reads exactly as many bytes as requested, making the logic simpler

    mov     x8, #63
    svc     #0
    ret


// lseek(int fd, int offset)
lseek:
    mov     x2, xzr

    mov     x8, #62
    svc     #0
    ret


// close(int fd)
close: 
    mov     x8, #57
    svc     #0
    ret


// write(void *buf, size_t count)
write:
    mov     x2, x1
    mov     x1, x0
    mov     x0, #1
    mov     x8, #64
    svc     #0
    mov     x0, x1          // undo
    mov     x1, x2
    ret


# exit(int status)
exit:
    mov     w8, #93
    svc     #0


.data
file:   .asciz  "input"
