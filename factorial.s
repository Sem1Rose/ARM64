.section .text
.global _start

_start:
    sub     sp, sp, #3
    mov     x0, sp
    bl      read
    bl      ascii_to_u64    // returns: x0: u64
    add     sp, sp, #3

    bl      factorial       // returns: x0: u64

    sub     sp, sp, #21
    bl      u64_to_ascii    // returns: x0: string address, x1: string length
    bl      write
    add     sp, sp, #21

    mov     x0, #0
    b       exit


// ascii_to_u64(void *buf)
ascii_to_u64:
    mov     x6, #10
    mov     x5, #2          // arbitrary limit of 2 digits
    mov     x1, x0
    mov     x0, #1          // setup exit code for error
ascii_to_u64_loop:
    ldrb    w2, [x1], #1

    cmp     x2, 0xA         // line feed: end of input
    beq     ascii_to_u64_end
    cmp     x2, '0'
    blt     exit
    cmp     x2, '9'
    bgt     exit

    sub     x2, x2, #0x30
    madd    x3, x3, x6, x2

    sub     x5, x5, #1
    cmp     x5, #0
    bne     ascii_to_u64_loop
ascii_to_u64_end:
    mov     x0, x3
    ret


// factorial(u64 num)
factorial:
    mov     x1, #1
factorial_loop:
    cmp     x0, #1
    ble     factorial_done
    mul     x1, x1, x0
    sub     x0, x0, #1
    b       factorial_loop
factorial_done:
    mov     x0, x1
    ret


// u64_to_ascii(u64 num, u64 length)
u64_to_ascii:               // x2: new num, x3: remainder, x4: string address (sb), x5: 10
    mov     x5, #10
    add     x4, sp, #21     // max u64 digits
    mov     x3, xzr
    mov     x2, 0xA         // Line feed
    strb    w2, [x4], #-1
    mov     x1, #1
    cmp     x0, xzr
    beq     add_digit
get_next_digit:
    udiv    x2, x0, x5
    msub    x3, x2, x5, x0
    mov     x0, x2
add_digit:
    // add     x3, x3, #0x30   // digits start at code 0x30 in ascii
    add     x3, x3, '0'
    strb    w3, [x4], #-1
    add     x1, x1, #1

    cmp     x0, xzr
    bne     get_next_digit
    
    add     x0, x4, #1      // return the address of the string
    ret


// read(void *buf)
read:
    mov     x2, #3          // arbitrary limit of 2 digits
    mov     x1, x0
    mov     x0, #1    
    mov     w8, #63
    svc     #0
    mov     x0, x1          // undo
    ret

// write(void *buf, size_t count)
write:
    mov     x2, x1
    mov     x1, x0
    mov     x0, #1    
    mov     w8, #64
    svc     #0
    mov     x0, x1          // undo
    mov     x1, x2
    ret


# exit(int status)
exit:
    mov     w8, #93
    svc     #0
