/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
 

 
#define CONCRETEx(str1,str2) str1##str2

#define CONCRETE(str1,str2) CONCRETEx(str1,str2)

#define GET_HANDLER(str1) \
	.long CONCRETE(str1,_handler)

#define TRAPHANDLER_WRAPPER(name,num) \
	TRAPHANDLER(CONCRETE(name,_handler),num)
 
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
 #define TRAPHANDLER_NOEC_WRAPPER(name,num) \
	TRAPHANDLER_NOEC(CONCRETE(name,_handler),num)
 
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps
 
  .global idt_entries
 
 .data

 idt_entries:
 	GET_HANDLER(divide)
	GET_HANDLER(debug)
	GET_HANDLER(nmi)
	GET_HANDLER(brkpt)
	GET_HANDLER(oflow)
	GET_HANDLER(bound)
	GET_HANDLER(illop)
	GET_HANDLER(device)
	GET_HANDLER(dblflt)
	.zero 4
	GET_HANDLER(tss)
	GET_HANDLER(segnp)
	GET_HANDLER(stack)
	GET_HANDLER(gpflt)
	GET_HANDLER(pgflt)
	.zero 4
	GET_HANDLER(fperr)
	GET_HANDLER(align)
	GET_HANDLER(mchk)
	GET_HANDLER(simderr)
	.zero (IRQ_OFFSET - T_SIMDERR - 1)*4
	GET_HANDLER(irq0)
	GET_HANDLER(irq1)
	GET_HANDLER(irq2)
	GET_HANDLER(irq3)
	GET_HANDLER(irq4)
	GET_HANDLER(irq5)
	GET_HANDLER(irq6)
	GET_HANDLER(irq7)
	GET_HANDLER(irq8)
	GET_HANDLER(irq9)
	GET_HANDLER(irq10)
	GET_HANDLER(irq11)
	GET_HANDLER(irq12)
	GET_HANDLER(irq13)
	GET_HANDLER(irq14)
	GET_HANDLER(irq15)
	GET_HANDLER(syscall)
	.zero 208*4
	
 
 
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC_WRAPPER(divide,T_DIVIDE)
TRAPHANDLER_NOEC_WRAPPER(debug,T_DEBUG)
TRAPHANDLER_NOEC_WRAPPER(nmi,T_NMI)
TRAPHANDLER_NOEC_WRAPPER(brkpt,T_BRKPT)
TRAPHANDLER_NOEC_WRAPPER(oflow,T_OFLOW)
TRAPHANDLER_NOEC_WRAPPER(bound,T_BOUND)
TRAPHANDLER_NOEC_WRAPPER(illop,T_ILLOP)
TRAPHANDLER_NOEC_WRAPPER(device,T_DEVICE)
TRAPHANDLER_WRAPPER(dblflt,T_DBLFLT)
TRAPHANDLER_WRAPPER(tss,T_TSS)
TRAPHANDLER_WRAPPER(segnp,T_SEGNP)
TRAPHANDLER_WRAPPER(stack,T_STACK)
TRAPHANDLER_WRAPPER(gpflt,T_GPFLT)
TRAPHANDLER_WRAPPER(pgflt,T_PGFLT)
TRAPHANDLER_NOEC_WRAPPER(fperr,T_FPERR)
TRAPHANDLER_WRAPPER(align,T_ALIGN)
TRAPHANDLER_NOEC_WRAPPER(mchk,T_MCHK)
TRAPHANDLER_NOEC_WRAPPER(simderr,T_SIMDERR)
TRAPHANDLER_NOEC_WRAPPER(irq0,IRQ_OFFSET+0)
TRAPHANDLER_NOEC_WRAPPER(irq1,IRQ_OFFSET+1)
TRAPHANDLER_NOEC_WRAPPER(irq2,IRQ_OFFSET+2)
TRAPHANDLER_NOEC_WRAPPER(irq3,IRQ_OFFSET+3)
TRAPHANDLER_NOEC_WRAPPER(irq4,IRQ_OFFSET+4)
TRAPHANDLER_NOEC_WRAPPER(irq5,IRQ_OFFSET+5)
TRAPHANDLER_NOEC_WRAPPER(irq6,IRQ_OFFSET+6)
TRAPHANDLER_NOEC_WRAPPER(irq7,IRQ_OFFSET+7)
TRAPHANDLER_NOEC_WRAPPER(irq8,IRQ_OFFSET+8)
TRAPHANDLER_NOEC_WRAPPER(irq9,IRQ_OFFSET+9)
TRAPHANDLER_NOEC_WRAPPER(irq10,IRQ_OFFSET+10)
TRAPHANDLER_NOEC_WRAPPER(irq11,IRQ_OFFSET+11)
TRAPHANDLER_NOEC_WRAPPER(irq12,IRQ_OFFSET+12)
TRAPHANDLER_NOEC_WRAPPER(irq13,IRQ_OFFSET+13)
TRAPHANDLER_NOEC_WRAPPER(irq14,IRQ_OFFSET+14)
TRAPHANDLER_NOEC_WRAPPER(irq15,IRQ_OFFSET+15)
TRAPHANDLER_NOEC_WRAPPER(syscall,T_SYSCALL)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	/*pushw $0x0 tf_padding2*/
	pushl %ds
	pushl %es
	#fxsave (%esp)
	pushal
	
	movl $GD_KD,%eax
	movw %ax,%ds
	movw %ax,%es
	
	pushl %esp
	movl $0, %ebp
	call trap
	#addl $4, %esp       # skip the argument we passed on stack to trap()
  	#popal
  	#popl %es
  	#popl %ds
  	#addl $8, %esp       # skip trapno and errcode
  	#iret
		
