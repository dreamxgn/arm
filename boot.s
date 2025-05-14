.section .text
.global _start,el1_entry_point,primary_core,secondary_core,core_ready_flags
_start:
mrs x0,scr_el3
mov x1,#0xd01
orr x0,x0,x1 //设置NS和RW(AArch64) FIQ、IRQ、SError都屏蔽
MSR SCR_EL3, x0

//配置 HCR_EL2 设置 RW=1 NS=1
mrs x0,hcr_el2
ORR   x0, x0, #(1 << 31)
MSR   HCR_EL2, x0

//配置 SPSR_EL3 设置 M[3:0] = 0b0101 (EL1，使用 SP_EL1),屏蔽 FIQ、IRQ、SError
mrs x0,spsr_el3
mov x1,#0x3c5
orr X0,x0,x1
MSR SPSR_EL3, X0

LDR X1, =el1_entry_point
MSR ELR_EL3, X1
ERET

// EL1 的入口点代码
el1_entry_point:
mrs x0,mpidr_el1
and x0,x0,#0xff
cbz x0,primary_core // 如果是主核，跳转到 primary_core
b secondary_core // 如果是辅核，跳转到 secondary_core

primary_core:
// 设置中断向量表
bl setup_vector_table
// 设置 MMU
bl setup_mmu

// 设置 core_ready_flags
//ldr x0,=core_ready_flags
//mov x1,#1
//str x1,[x0]
//通知其它核心
//sev
b main

secondary_core:
wfe
ldr x0,=core_ready_flags
ldr x0,[x0]
cbz x0,secondary_core
// 设置中断向量表
bl setup_vector_table
// 设置 MMU
bl setup_mmu
b main

// 主函数
main:
ldr x0,=var1
ldr x0,[x0]
ldr x1,=addr1
ldr x1,[x1]
str x0,[x1]
b .

// 设置中断向量表
setup_vector_table:
ldr x0,=vector_table 
msr vbar_el1,x0
ret

// 设置 MMU
setup_mmu:
mov x0,0x3FFFFFF8
ldr x1,=var1
ldr x1,[x1]
str x1,[x0]

ldr x0,=0x40000008
str x1,[x0]

// 设置页表地址
ldr x0,=tt_base_el1
msr ttbr0_el1,x0

// 设置 MAIR 内存属性 
mov x0,#0x44
msr mair_el1,x0

ldr x0,=tcr_el1_mem_attr
ldr x0,[x0]
msr tcr_el1,x0

tlbi vmalle1
dsb sy
isb

MOV      x0, #(1 << 0)                    
ORR      x0, x0, #(1 << 2) 
ORR      x0, x0, #(1 << 12)
MSR      SCTLR_EL1, x0
ISB
ret


.align 0x4
vector_table:
// 中断 SP_EL0
.balign 0x10
sync_exception_handler_spel0:
    b .
.balign 0x10
irq_exception_handler_spel0:
    b .
.balign 0x10
fiq_exception_handler_spel0:
    b .
.balign 0x10
err_exception_handler_spel0:
    b .

// 中断 SP_ELX
.balign 0x10
sync_exception_handler_spelx:
    b .
.balign 0x10
irq_exception_handler_spelx:
    b .
.balign 0x10
fiq_exception_handler_spelx:
    b .
.balign 0x10
err_exception_handler_spelx:
    b .
//低Exception level AArch64
.balign 0x10
sync_lower_el_aarch64:
b .              
.balign 0x10
irq_lower_el_aarch64:
b .
.balign 0x10
fiq_lower_el_aarch64:
b .
.balign 0x10
serror_lower_el_aarch64:
b .

//低Exception level AArch32
.balign 0x10
sync_lower_el_aarch32:
b .              
.balign 0x10
irq_lower_el_aarch32:
b .
.balign 0x10
fiq_lower_el_aarch32:
b .
.balign 0x10
serror_lower_el_aarch32:
b .

.section .data
.balign 8
core_ready_flags:
    .quad 0 // 0: 主核未启动，1: 主核已启动

scr_el3_flag:
    .quad 0xd10

tcr_el1_mem_attr:
    .quad 0x803519

var1:
    .quad 0x12345678
addr1:
    .quad 0x3FFFFFEC

.balign 0x1000
tt_base_el1:
    .quad 0x600000000000401
    .quad 0x600000000000401
    .quad 0x0
    .quad 0x0
    .fill 0x1000-0x20, 1, 0

