
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 80 19 10 f0       	push   $0xf0101980
f0100050:	e8 50 09 00 00       	call   f01009a5 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 88 07 00 00       	call   f0100803 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 19 10 f0       	push   $0xf010199c
f0100087:	e8 19 09 00 00       	call   f01009a5 <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 84 29 11 f0       	mov    $0xf0112984,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 e3 13 00 00       	call   f0101494 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 19 10 f0       	push   $0xf01019b7
f01000c3:	e8 dd 08 00 00       	call   f01009a5 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 56 07 00 00       	call   f0100837 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 80 29 11 f0 00 	cmpl   $0x0,0xf0112980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 29 11 f0    	mov    %esi,0xf0112980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 d2 19 10 f0       	push   $0xf01019d2
f0100110:	e8 90 08 00 00       	call   f01009a5 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 60 08 00 00       	call   f010097f <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100126:	e8 7a 08 00 00       	call   f01009a5 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 ff 06 00 00       	call   f0100837 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 ea 19 10 f0       	push   $0xf01019ea
f0100152:	e8 4e 08 00 00       	call   f01009a5 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 1c 08 00 00       	call   f010097f <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f010016a:	e8 36 08 00 00       	call   f01009a5 <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 08                	je     f010018c <serial_proc_data+0x15>
f0100184:	b2 f8                	mov    $0xf8,%dl
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2a                	jmp    f01001c8 <cons_intr+0x35>
		if (c == 0)
f010019e:	85 d2                	test   %edx,%edx
f01001a0:	74 26                	je     f01001c8 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001b0:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001c5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c8:	ff d3                	call   *%ebx
f01001ca:	89 c2                	mov    %eax,%edx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 cd                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <kbd_proc_data>:
f01001d7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001dc:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dd:	a8 01                	test   $0x1,%al
f01001df:	0f 84 f0 00 00 00    	je     f01002d5 <kbd_proc_data+0xfe>
f01001e5:	b2 60                	mov    $0x60,%dl
f01001e7:	ec                   	in     (%dx),%al
f01001e8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ea:	3c e0                	cmp    $0xe0,%al
f01001ec:	75 0d                	jne    f01001fb <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001ee:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001f5:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fa:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	53                   	push   %ebx
f01001ff:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100202:	84 c0                	test   %al,%al
f0100204:	79 36                	jns    f010023c <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100206:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 80 1b 10 f0 	movzbl -0xfefe480(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 80 1b 10 f0 	movzbl -0xfefe480(%eax),%edx
f010025f:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 80 1a 10 f0 	movzbl -0xfefe580(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 40 1a 10 f0 	mov    -0xfefe5c0(,%ecx,4),%ecx
f0100280:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100284:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100287:	f6 c2 08             	test   $0x8,%dl
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010028c:	89 d8                	mov    %ebx,%eax
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 f8 19             	cmp    $0x19,%eax
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002ad:	75 2c                	jne    f01002db <kbd_proc_data+0x104>
f01002af:	f7 d2                	not    %edx
f01002b1:	f6 c2 06             	test   $0x6,%dl
f01002b4:	75 25                	jne    f01002db <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b6:	83 ec 0c             	sub    $0xc,%esp
f01002b9:	68 04 1a 10 f0       	push   $0xf0101a04
f01002be:	e8 e2 06 00 00       	call   f01009a5 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c8:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 08                	jmp    f01002dd <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
}
f01002dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e0:	c9                   	leave  
f01002e1:	c3                   	ret    

f01002e2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e2:	55                   	push   %ebp
f01002e3:	89 e5                	mov    %esp,%ebp
f01002e5:	57                   	push   %edi
f01002e6:	56                   	push   %esi
f01002e7:	53                   	push   %ebx
f01002e8:	83 ec 1c             	sub    $0x1c,%esp
f01002eb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ed:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f2:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fc:	eb 09                	jmp    f0100307 <cons_putc+0x25>
f01002fe:	89 ca                	mov    %ecx,%edx
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100304:	83 c3 01             	add    $0x1,%ebx
f0100307:	89 f2                	mov    %esi,%edx
f0100309:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030a:	a8 20                	test   $0x20,%al
f010030c:	75 08                	jne    f0100316 <cons_putc+0x34>
f010030e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100314:	7e e8                	jle    f01002fe <cons_putc+0x1c>
f0100316:	89 f8                	mov    %edi,%eax
f0100318:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100320:	89 f8                	mov    %edi,%eax
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x5b>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	84 c0                	test   %al,%al
f0100342:	78 08                	js     f010034c <cons_putc+0x6a>
f0100344:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010034a:	7e e8                	jle    f0100334 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	b2 7a                	mov    $0x7a,%dl
f0100358:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035d:	ee                   	out    %al,(%dx)
f010035e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100363:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100364:	89 fa                	mov    %edi,%edx
f0100366:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036c:	89 f8                	mov    %edi,%eax
f010036e:	80 cc 07             	or     $0x7,%ah
f0100371:	85 d2                	test   %edx,%edx
f0100373:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100376:	89 f8                	mov    %edi,%eax
f0100378:	0f b6 c0             	movzbl %al,%eax
f010037b:	83 f8 09             	cmp    $0x9,%eax
f010037e:	74 74                	je     f01003f4 <cons_putc+0x112>
f0100380:	83 f8 09             	cmp    $0x9,%eax
f0100383:	7f 0a                	jg     f010038f <cons_putc+0xad>
f0100385:	83 f8 08             	cmp    $0x8,%eax
f0100388:	74 14                	je     f010039e <cons_putc+0xbc>
f010038a:	e9 99 00 00 00       	jmp    f0100428 <cons_putc+0x146>
f010038f:	83 f8 0a             	cmp    $0xa,%eax
f0100392:	74 3a                	je     f01003ce <cons_putc+0xec>
f0100394:	83 f8 0d             	cmp    $0xd,%eax
f0100397:	74 3d                	je     f01003d6 <cons_putc+0xf4>
f0100399:	e9 8a 00 00 00       	jmp    f0100428 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f010039e:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b2>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f01003f2:	eb 52                	jmp    f0100446 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01003f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f9:	e8 e4 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f01003fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100403:	e8 da fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100408:	b8 20 00 00 00       	mov    $0x20,%eax
f010040d:	e8 d0 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 c6 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 bc fe ff ff       	call   f01002e2 <cons_putc>
f0100426:	eb 1e                	jmp    f0100446 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100428:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 76 10 00 00       	call   f01014e1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100471:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100477:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047d:	83 c4 10             	add    $0x10,%esp
f0100480:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100485:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100488:	39 d0                	cmp    %edx,%eax
f010048a:	75 f4                	jne    f0100480 <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048c:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004a9:	8d 71 01             	lea    0x1(%ecx),%esi
f01004ac:	89 d8                	mov    %ebx,%eax
f01004ae:	66 c1 e8 08          	shr    $0x8,%ax
f01004b2:	89 f2                	mov    %esi,%edx
f01004b4:	ee                   	out    %al,(%dx)
f01004b5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ba:	89 ca                	mov    %ecx,%edx
f01004bc:	ee                   	out    %al,(%dx)
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	89 f2                	mov    %esi,%edx
f01004c1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c5:	5b                   	pop    %ebx
f01004c6:	5e                   	pop    %esi
f01004c7:	5f                   	pop    %edi
f01004c8:	5d                   	pop    %ebp
f01004c9:	c3                   	ret    

f01004ca <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ca:	80 3d 54 25 11 f0 00 	cmpb   $0x0,0xf0112554
f01004d1:	74 11                	je     f01004e4 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d9:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004de:	e8 b0 fc ff ff       	call   f0100193 <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	f3 c3                	repz ret 

f01004e6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ec:	b8 d7 01 10 f0       	mov    $0xf01001d7,%eax
f01004f1:	e8 9d fc ff ff       	call   f0100193 <cons_intr>
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fe:	e8 c7 ff ff ff       	call   f01004ca <serial_intr>
	kbd_intr();
f0100503:	e8 de ff ff ff       	call   f01004e6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100508:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010050d:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010051e:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100525:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100527:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052d:	75 11                	jne    f0100540 <cons_getc+0x48>
			cons.rpos = 0;
f010052f:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100536:	00 00 00 
f0100539:	eb 05                	jmp    f0100540 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100540:	c9                   	leave  
f0100541:	c3                   	ret    

f0100542 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100542:	55                   	push   %ebp
f0100543:	89 e5                	mov    %esp,%ebp
f0100545:	57                   	push   %edi
f0100546:	56                   	push   %esi
f0100547:	53                   	push   %ebx
f0100548:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100552:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100559:	5a a5 
	if (*cp != 0xA55A) {
f010055b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100562:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100566:	74 11                	je     f0100579 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100568:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010056f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100572:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100577:	eb 16                	jmp    f010058f <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100579:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100580:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f0100587:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058a:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058f:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f0100595:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059a:	89 fa                	mov    %edi,%edx
f010059c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059d:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 ca                	mov    %ecx,%edx
f01005a2:	ec                   	in     (%dx),%al
f01005a3:	0f b6 c0             	movzbl %al,%eax
f01005a6:	c1 e0 08             	shl    $0x8,%eax
f01005a9:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ab:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b0:	89 fa                	mov    %edi,%edx
f01005b2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b3:	89 ca                	mov    %ecx,%edx
f01005b5:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b6:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005bc:	0f b6 c8             	movzbl %al,%ecx
f01005bf:	89 d8                	mov    %ebx,%eax
f01005c1:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005c3:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c9:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	b2 fb                	mov    $0xfb,%dl
f01005d8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005dd:	ee                   	out    %al,(%dx)
f01005de:	be f8 03 00 00       	mov    $0x3f8,%esi
f01005e3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e8:	89 f2                	mov    %esi,%edx
f01005ea:	ee                   	out    %al,(%dx)
f01005eb:	b2 f9                	mov    $0xf9,%dl
f01005ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f2:	ee                   	out    %al,(%dx)
f01005f3:	b2 fb                	mov    $0xfb,%dl
f01005f5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	b2 fc                	mov    $0xfc,%dl
f01005fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	b2 f9                	mov    $0xf9,%dl
f0100605:	b8 01 00 00 00       	mov    $0x1,%eax
f010060a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060b:	b2 fd                	mov    $0xfd,%dl
f010060d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060e:	3c ff                	cmp    $0xff,%al
f0100610:	0f 95 c1             	setne  %cl
f0100613:	88 0d 54 25 11 f0    	mov    %cl,0xf0112554
f0100619:	89 da                	mov    %ebx,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	89 f2                	mov    %esi,%edx
f010061e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061f:	84 c9                	test   %cl,%cl
f0100621:	75 10                	jne    f0100633 <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f0100623:	83 ec 0c             	sub    $0xc,%esp
f0100626:	68 10 1a 10 f0       	push   $0xf0101a10
f010062b:	e8 75 03 00 00       	call   f01009a5 <cprintf>
f0100630:	83 c4 10             	add    $0x10,%esp
}
f0100633:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100636:	5b                   	pop    %ebx
f0100637:	5e                   	pop    %esi
f0100638:	5f                   	pop    %edi
f0100639:	5d                   	pop    %ebp
f010063a:	c3                   	ret    

f010063b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063b:	55                   	push   %ebp
f010063c:	89 e5                	mov    %esp,%ebp
f010063e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100641:	8b 45 08             	mov    0x8(%ebp),%eax
f0100644:	e8 99 fc ff ff       	call   f01002e2 <cons_putc>
}
f0100649:	c9                   	leave  
f010064a:	c3                   	ret    

f010064b <getchar>:

int
getchar(void)
{
f010064b:	55                   	push   %ebp
f010064c:	89 e5                	mov    %esp,%ebp
f010064e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100651:	e8 a2 fe ff ff       	call   f01004f8 <cons_getc>
f0100656:	85 c0                	test   %eax,%eax
f0100658:	74 f7                	je     f0100651 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <iscons>:

int
iscons(int fdnum)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100664:	5d                   	pop    %ebp
f0100665:	c3                   	ret    

f0100666 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100666:	55                   	push   %ebp
f0100667:	89 e5                	mov    %esp,%ebp
f0100669:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066c:	68 80 1c 10 f0       	push   $0xf0101c80
f0100671:	68 9e 1c 10 f0       	push   $0xf0101c9e
f0100676:	68 a3 1c 10 f0       	push   $0xf0101ca3
f010067b:	e8 25 03 00 00       	call   f01009a5 <cprintf>
f0100680:	83 c4 0c             	add    $0xc,%esp
f0100683:	68 7c 1d 10 f0       	push   $0xf0101d7c
f0100688:	68 ac 1c 10 f0       	push   $0xf0101cac
f010068d:	68 a3 1c 10 f0       	push   $0xf0101ca3
f0100692:	e8 0e 03 00 00       	call   f01009a5 <cprintf>
f0100697:	83 c4 0c             	add    $0xc,%esp
f010069a:	68 a4 1d 10 f0       	push   $0xf0101da4
f010069f:	68 b5 1c 10 f0       	push   $0xf0101cb5
f01006a4:	68 a3 1c 10 f0       	push   $0xf0101ca3
f01006a9:	e8 f7 02 00 00       	call   f01009a5 <cprintf>
	return 0;
}
f01006ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01006b3:	c9                   	leave  
f01006b4:	c3                   	ret    

f01006b5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b5:	55                   	push   %ebp
f01006b6:	89 e5                	mov    %esp,%ebp
f01006b8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006bb:	68 bf 1c 10 f0       	push   $0xf0101cbf
f01006c0:	e8 e0 02 00 00       	call   f01009a5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c5:	83 c4 08             	add    $0x8,%esp
f01006c8:	68 0c 00 10 00       	push   $0x10000c
f01006cd:	68 d0 1d 10 f0       	push   $0xf0101dd0
f01006d2:	e8 ce 02 00 00       	call   f01009a5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d7:	83 c4 0c             	add    $0xc,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 0c 00 10 f0       	push   $0xf010000c
f01006e4:	68 f8 1d 10 f0       	push   $0xf0101df8
f01006e9:	e8 b7 02 00 00       	call   f01009a5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ee:	83 c4 0c             	add    $0xc,%esp
f01006f1:	68 45 19 10 00       	push   $0x101945
f01006f6:	68 45 19 10 f0       	push   $0xf0101945
f01006fb:	68 1c 1e 10 f0       	push   $0xf0101e1c
f0100700:	e8 a0 02 00 00       	call   f01009a5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100705:	83 c4 0c             	add    $0xc,%esp
f0100708:	68 00 23 11 00       	push   $0x112300
f010070d:	68 00 23 11 f0       	push   $0xf0112300
f0100712:	68 40 1e 10 f0       	push   $0xf0101e40
f0100717:	e8 89 02 00 00       	call   f01009a5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071c:	83 c4 0c             	add    $0xc,%esp
f010071f:	68 84 29 11 00       	push   $0x112984
f0100724:	68 84 29 11 f0       	push   $0xf0112984
f0100729:	68 64 1e 10 f0       	push   $0xf0101e64
f010072e:	e8 72 02 00 00       	call   f01009a5 <cprintf>
f0100733:	b8 83 2d 11 f0       	mov    $0xf0112d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100738:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073d:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100740:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100745:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074b:	85 c0                	test   %eax,%eax
f010074d:	0f 48 c2             	cmovs  %edx,%eax
f0100750:	c1 f8 0a             	sar    $0xa,%eax
f0100753:	50                   	push   %eax
f0100754:	68 88 1e 10 f0       	push   $0xf0101e88
f0100759:	e8 47 02 00 00       	call   f01009a5 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010075e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100763:	c9                   	leave  
f0100764:	c3                   	ret    

f0100765 <mon_backtrace_helper>:

void mon_backtrace_helper(uint32_t* ebpAdr)
{
f0100765:	55                   	push   %ebp
f0100766:	89 e5                	mov    %esp,%ebp
f0100768:	57                   	push   %edi
f0100769:	56                   	push   %esi
f010076a:	53                   	push   %ebx
f010076b:	83 ec 34             	sub    $0x34,%esp
f010076e:	8b 75 08             	mov    0x8(%ebp),%esi
	uintptr_t eipAddr = (uintptr_t)ebpAdr[1];
f0100771:	8b 7e 04             	mov    0x4(%esi),%edi
	struct Eipdebuginfo info;
	int argsCount = 0;
	
	if(debuginfo_eip(eipAddr,&info) != -1)
f0100774:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100777:	50                   	push   %eax
f0100778:	57                   	push   %edi
f0100779:	e8 3d 03 00 00       	call   f0100abb <debuginfo_eip>
f010077e:	83 c4 10             	add    $0x10,%esp
f0100781:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100784:	74 5f                	je     f01007e5 <mon_backtrace_helper+0x80>
	{
		// get the debug info sucessfully
		argsCount = info.eip_fn_narg;
		cprintf(" ebp %08x  eip %08x args",
f0100786:	83 ec 04             	sub    $0x4,%esp
f0100789:	ff 76 04             	pushl  0x4(%esi)
f010078c:	56                   	push   %esi
f010078d:	68 d8 1c 10 f0       	push   $0xf0101cd8
f0100792:	e8 0e 02 00 00       	call   f01009a5 <cprintf>
f0100797:	8d 5e 08             	lea    0x8(%esi),%ebx
f010079a:	83 c6 1c             	add    $0x1c,%esi
f010079d:	83 c4 10             	add    $0x10,%esp
		ebpAdr,
		ebpAdr[1]);
	int i = 0;
	for(;i < 5;++i)
	{
		cprintf(" %08x",ebpAdr[i+2]);	
f01007a0:	83 ec 08             	sub    $0x8,%esp
f01007a3:	ff 33                	pushl  (%ebx)
f01007a5:	68 f1 1c 10 f0       	push   $0xf0101cf1
f01007aa:	e8 f6 01 00 00       	call   f01009a5 <cprintf>
f01007af:	83 c3 04             	add    $0x4,%ebx
		argsCount = info.eip_fn_narg;
		cprintf(" ebp %08x  eip %08x args",
		ebpAdr,
		ebpAdr[1]);
	int i = 0;
	for(;i < 5;++i)
f01007b2:	83 c4 10             	add    $0x10,%esp
f01007b5:	39 f3                	cmp    %esi,%ebx
f01007b7:	75 e7                	jne    f01007a0 <mon_backtrace_helper+0x3b>
	{
		cprintf(" %08x",ebpAdr[i+2]);	
	}
	cprintf("\n");
f01007b9:	83 ec 0c             	sub    $0xc,%esp
f01007bc:	68 0e 1a 10 f0       	push   $0xf0101a0e
f01007c1:	e8 df 01 00 00       	call   f01009a5 <cprintf>
	cprintf("%s:%d: %.*s+%d\n",
f01007c6:	83 c4 08             	add    $0x8,%esp
f01007c9:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007cc:	57                   	push   %edi
f01007cd:	ff 75 d8             	pushl  -0x28(%ebp)
f01007d0:	ff 75 dc             	pushl  -0x24(%ebp)
f01007d3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007d6:	ff 75 d0             	pushl  -0x30(%ebp)
f01007d9:	68 f7 1c 10 f0       	push   $0xf0101cf7
f01007de:	e8 c2 01 00 00       	call   f01009a5 <cprintf>
f01007e3:	eb 16                	jmp    f01007fb <mon_backtrace_helper+0x96>
		info.eip_line,
		info.eip_fn_namelen,
		info.eip_fn_name,
		eipAddr - info.eip_fn_addr);
	}
	else assert(0);
f01007e5:	68 07 1d 10 f0       	push   $0xf0101d07
f01007ea:	68 09 1d 10 f0       	push   $0xf0101d09
f01007ef:	6a 55                	push   $0x55
f01007f1:	68 1e 1d 10 f0       	push   $0xf0101d1e
f01007f6:	e8 eb f8 ff ff       	call   f01000e6 <_panic>
	
}
f01007fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007fe:	5b                   	pop    %ebx
f01007ff:	5e                   	pop    %esi
f0100800:	5f                   	pop    %edi
f0100801:	5d                   	pop    %ebp
f0100802:	c3                   	ret    

f0100803 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100803:	55                   	push   %ebp
f0100804:	89 e5                	mov    %esp,%ebp
f0100806:	53                   	push   %ebx
f0100807:	83 ec 10             	sub    $0x10,%esp
	// Your code here.
	//ignore argc & argv and tf?
	//get the ebp of mon_backtrace
	uint32_t* ebpAdr = (uint32_t*)read_ebp();
f010080a:	89 eb                	mov    %ebp,%ebx
	cprintf ("Stack backtrace:\n");
f010080c:	68 2d 1d 10 f0       	push   $0xf0101d2d
f0100811:	e8 8f 01 00 00       	call   f01009a5 <cprintf>
	while(ebpAdr != NULL)
f0100816:	83 c4 10             	add    $0x10,%esp
f0100819:	eb 0e                	jmp    f0100829 <mon_backtrace+0x26>
	{
		mon_backtrace_helper(ebpAdr);
f010081b:	83 ec 0c             	sub    $0xc,%esp
f010081e:	53                   	push   %ebx
f010081f:	e8 41 ff ff ff       	call   f0100765 <mon_backtrace_helper>
		ebpAdr = (uint32_t*)(*ebpAdr);
f0100824:	8b 1b                	mov    (%ebx),%ebx
f0100826:	83 c4 10             	add    $0x10,%esp
	// Your code here.
	//ignore argc & argv and tf?
	//get the ebp of mon_backtrace
	uint32_t* ebpAdr = (uint32_t*)read_ebp();
	cprintf ("Stack backtrace:\n");
	while(ebpAdr != NULL)
f0100829:	85 db                	test   %ebx,%ebx
f010082b:	75 ee                	jne    f010081b <mon_backtrace+0x18>
		mon_backtrace_helper(ebpAdr);
		ebpAdr = (uint32_t*)(*ebpAdr);
	}
	
	return 0;
}
f010082d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100832:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100835:	c9                   	leave  
f0100836:	c3                   	ret    

f0100837 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100837:	55                   	push   %ebp
f0100838:	89 e5                	mov    %esp,%ebp
f010083a:	57                   	push   %edi
f010083b:	56                   	push   %esi
f010083c:	53                   	push   %ebx
f010083d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100840:	68 b4 1e 10 f0       	push   $0xf0101eb4
f0100845:	e8 5b 01 00 00       	call   f01009a5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084a:	c7 04 24 d8 1e 10 f0 	movl   $0xf0101ed8,(%esp)
f0100851:	e8 4f 01 00 00       	call   f01009a5 <cprintf>
f0100856:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100859:	83 ec 0c             	sub    $0xc,%esp
f010085c:	68 3f 1d 10 f0       	push   $0xf0101d3f
f0100861:	e8 d7 09 00 00       	call   f010123d <readline>
f0100866:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100868:	83 c4 10             	add    $0x10,%esp
f010086b:	85 c0                	test   %eax,%eax
f010086d:	74 ea                	je     f0100859 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100876:	be 00 00 00 00       	mov    $0x0,%esi
f010087b:	eb 0a                	jmp    f0100887 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010087d:	c6 03 00             	movb   $0x0,(%ebx)
f0100880:	89 f7                	mov    %esi,%edi
f0100882:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100885:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100887:	0f b6 03             	movzbl (%ebx),%eax
f010088a:	84 c0                	test   %al,%al
f010088c:	74 63                	je     f01008f1 <monitor+0xba>
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	0f be c0             	movsbl %al,%eax
f0100894:	50                   	push   %eax
f0100895:	68 43 1d 10 f0       	push   $0xf0101d43
f010089a:	e8 b8 0b 00 00       	call   f0101457 <strchr>
f010089f:	83 c4 10             	add    $0x10,%esp
f01008a2:	85 c0                	test   %eax,%eax
f01008a4:	75 d7                	jne    f010087d <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008a6:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a9:	74 46                	je     f01008f1 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008ab:	83 fe 0f             	cmp    $0xf,%esi
f01008ae:	75 14                	jne    f01008c4 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b0:	83 ec 08             	sub    $0x8,%esp
f01008b3:	6a 10                	push   $0x10
f01008b5:	68 48 1d 10 f0       	push   $0xf0101d48
f01008ba:	e8 e6 00 00 00       	call   f01009a5 <cprintf>
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	eb 95                	jmp    f0100859 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008c4:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008cb:	eb 03                	jmp    f01008d0 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008cd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d0:	0f b6 03             	movzbl (%ebx),%eax
f01008d3:	84 c0                	test   %al,%al
f01008d5:	74 ae                	je     f0100885 <monitor+0x4e>
f01008d7:	83 ec 08             	sub    $0x8,%esp
f01008da:	0f be c0             	movsbl %al,%eax
f01008dd:	50                   	push   %eax
f01008de:	68 43 1d 10 f0       	push   $0xf0101d43
f01008e3:	e8 6f 0b 00 00       	call   f0101457 <strchr>
f01008e8:	83 c4 10             	add    $0x10,%esp
f01008eb:	85 c0                	test   %eax,%eax
f01008ed:	74 de                	je     f01008cd <monitor+0x96>
f01008ef:	eb 94                	jmp    f0100885 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008f1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f9:	85 f6                	test   %esi,%esi
f01008fb:	0f 84 58 ff ff ff    	je     f0100859 <monitor+0x22>
f0100901:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100906:	83 ec 08             	sub    $0x8,%esp
f0100909:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010090c:	ff 34 85 00 1f 10 f0 	pushl  -0xfefe100(,%eax,4)
f0100913:	ff 75 a8             	pushl  -0x58(%ebp)
f0100916:	e8 de 0a 00 00       	call   f01013f9 <strcmp>
f010091b:	83 c4 10             	add    $0x10,%esp
f010091e:	85 c0                	test   %eax,%eax
f0100920:	75 22                	jne    f0100944 <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f0100922:	83 ec 04             	sub    $0x4,%esp
f0100925:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100928:	ff 75 08             	pushl  0x8(%ebp)
f010092b:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092e:	52                   	push   %edx
f010092f:	56                   	push   %esi
f0100930:	ff 14 85 08 1f 10 f0 	call   *-0xfefe0f8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100937:	83 c4 10             	add    $0x10,%esp
f010093a:	85 c0                	test   %eax,%eax
f010093c:	0f 89 17 ff ff ff    	jns    f0100859 <monitor+0x22>
f0100942:	eb 20                	jmp    f0100964 <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100944:	83 c3 01             	add    $0x1,%ebx
f0100947:	83 fb 03             	cmp    $0x3,%ebx
f010094a:	75 ba                	jne    f0100906 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010094c:	83 ec 08             	sub    $0x8,%esp
f010094f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100952:	68 65 1d 10 f0       	push   $0xf0101d65
f0100957:	e8 49 00 00 00       	call   f01009a5 <cprintf>
f010095c:	83 c4 10             	add    $0x10,%esp
f010095f:	e9 f5 fe ff ff       	jmp    f0100859 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100964:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100967:	5b                   	pop    %ebx
f0100968:	5e                   	pop    %esi
f0100969:	5f                   	pop    %edi
f010096a:	5d                   	pop    %ebp
f010096b:	c3                   	ret    

f010096c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010096c:	55                   	push   %ebp
f010096d:	89 e5                	mov    %esp,%ebp
f010096f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100972:	ff 75 08             	pushl  0x8(%ebp)
f0100975:	e8 c1 fc ff ff       	call   f010063b <cputchar>
f010097a:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f010097d:	c9                   	leave  
f010097e:	c3                   	ret    

f010097f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010097f:	55                   	push   %ebp
f0100980:	89 e5                	mov    %esp,%ebp
f0100982:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100985:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010098c:	ff 75 0c             	pushl  0xc(%ebp)
f010098f:	ff 75 08             	pushl  0x8(%ebp)
f0100992:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100995:	50                   	push   %eax
f0100996:	68 6c 09 10 f0       	push   $0xf010096c
f010099b:	e8 81 04 00 00       	call   f0100e21 <vprintfmt>
	return cnt;
}
f01009a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009a3:	c9                   	leave  
f01009a4:	c3                   	ret    

f01009a5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a5:	55                   	push   %ebp
f01009a6:	89 e5                	mov    %esp,%ebp
f01009a8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ab:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009ae:	50                   	push   %eax
f01009af:	ff 75 08             	pushl  0x8(%ebp)
f01009b2:	e8 c8 ff ff ff       	call   f010097f <vcprintf>
	va_end(ap);

	return cnt;
}
f01009b7:	c9                   	leave  
f01009b8:	c3                   	ret    

f01009b9 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	57                   	push   %edi
f01009bd:	56                   	push   %esi
f01009be:	53                   	push   %ebx
f01009bf:	83 ec 14             	sub    $0x14,%esp
f01009c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009c5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009c8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009cb:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ce:	8b 1a                	mov    (%edx),%ebx
f01009d0:	8b 01                	mov    (%ecx),%eax
f01009d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009dc:	e9 88 00 00 00       	jmp    f0100a69 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01009e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009e4:	01 d8                	add    %ebx,%eax
f01009e6:	89 c6                	mov    %eax,%esi
f01009e8:	c1 ee 1f             	shr    $0x1f,%esi
f01009eb:	01 c6                	add    %eax,%esi
f01009ed:	d1 fe                	sar    %esi
f01009ef:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009f2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009f5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009f8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		// find the type first
		while (m >= l && stabs[m].n_type != type)
f01009fa:	eb 03                	jmp    f01009ff <stab_binsearch+0x46>
			m--;
f01009fc:	83 e8 01             	sub    $0x1,%eax
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		// find the type first
		while (m >= l && stabs[m].n_type != type)
f01009ff:	39 c3                	cmp    %eax,%ebx
f0100a01:	7f 1f                	jg     f0100a22 <stab_binsearch+0x69>
f0100a03:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a07:	83 ea 0c             	sub    $0xc,%edx
f0100a0a:	39 f9                	cmp    %edi,%ecx
f0100a0c:	75 ee                	jne    f01009fc <stab_binsearch+0x43>
f0100a0e:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a11:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a14:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a17:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a1b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a1e:	76 18                	jbe    f0100a38 <stab_binsearch+0x7f>
f0100a20:	eb 05                	jmp    f0100a27 <stab_binsearch+0x6e>
		// search for earliest stab with right type
		// find the type first
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a22:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a25:	eb 42                	jmp    f0100a69 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a27:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a2a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a2c:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a2f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a36:	eb 31                	jmp    f0100a69 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a38:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a3b:	73 17                	jae    f0100a54 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a40:	83 e8 01             	sub    $0x1,%eax
f0100a43:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a46:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a49:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a4b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a52:	eb 15                	jmp    f0100a69 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a54:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a57:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a5a:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100a5c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a60:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a62:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a69:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a6c:	0f 8e 6f ff ff ff    	jle    f01009e1 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a72:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a76:	75 0f                	jne    f0100a87 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100a78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a7b:	8b 00                	mov    (%eax),%eax
f0100a7d:	83 e8 01             	sub    $0x1,%eax
f0100a80:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a83:	89 06                	mov    %eax,(%esi)
f0100a85:	eb 2c                	jmp    f0100ab3 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a87:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a8a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a8c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a8f:	8b 0e                	mov    (%esi),%ecx
f0100a91:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a94:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a97:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9a:	eb 03                	jmp    f0100a9f <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a9c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9f:	39 c8                	cmp    %ecx,%eax
f0100aa1:	7e 0b                	jle    f0100aae <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100aa3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100aa7:	83 ea 0c             	sub    $0xc,%edx
f0100aaa:	39 fb                	cmp    %edi,%ebx
f0100aac:	75 ee                	jne    f0100a9c <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100aae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ab1:	89 06                	mov    %eax,(%esi)
	}
}
f0100ab3:	83 c4 14             	add    $0x14,%esp
f0100ab6:	5b                   	pop    %ebx
f0100ab7:	5e                   	pop    %esi
f0100ab8:	5f                   	pop    %edi
f0100ab9:	5d                   	pop    %ebp
f0100aba:	c3                   	ret    

f0100abb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100abb:	55                   	push   %ebp
f0100abc:	89 e5                	mov    %esp,%ebp
f0100abe:	57                   	push   %edi
f0100abf:	56                   	push   %esi
f0100ac0:	53                   	push   %ebx
f0100ac1:	83 ec 3c             	sub    $0x3c,%esp
f0100ac4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ac7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aca:	c7 03 24 1f 10 f0    	movl   $0xf0101f24,(%ebx)
	info->eip_line = 0;
f0100ad0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ad7:	c7 43 08 24 1f 10 f0 	movl   $0xf0101f24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ade:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ae5:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ae8:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aef:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100af5:	76 11                	jbe    f0100b08 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af7:	b8 3a 74 10 f0       	mov    $0xf010743a,%eax
f0100afc:	3d 0d 5b 10 f0       	cmp    $0xf0105b0d,%eax
f0100b01:	77 1c                	ja     f0100b1f <debuginfo_eip+0x64>
f0100b03:	e9 ac 01 00 00       	jmp    f0100cb4 <debuginfo_eip+0x1f9>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b08:	83 ec 04             	sub    $0x4,%esp
f0100b0b:	68 2e 1f 10 f0       	push   $0xf0101f2e
f0100b10:	68 80 00 00 00       	push   $0x80
f0100b15:	68 3b 1f 10 f0       	push   $0xf0101f3b
f0100b1a:	e8 c7 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b1f:	80 3d 39 74 10 f0 00 	cmpb   $0x0,0xf0107439
f0100b26:	0f 85 8f 01 00 00    	jne    f0100cbb <debuginfo_eip+0x200>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b2c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b33:	b8 0c 5b 10 f0       	mov    $0xf0105b0c,%eax
f0100b38:	2d 70 21 10 f0       	sub    $0xf0102170,%eax
f0100b3d:	c1 f8 02             	sar    $0x2,%eax
f0100b40:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b46:	83 e8 01             	sub    $0x1,%eax
f0100b49:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b4c:	83 ec 08             	sub    $0x8,%esp
f0100b4f:	56                   	push   %esi
f0100b50:	6a 64                	push   $0x64
f0100b52:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b55:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b58:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100b5d:	e8 57 fe ff ff       	call   f01009b9 <stab_binsearch>
	if (lfile == 0)
f0100b62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b65:	83 c4 10             	add    $0x10,%esp
f0100b68:	85 c0                	test   %eax,%eax
f0100b6a:	0f 84 52 01 00 00    	je     f0100cc2 <debuginfo_eip+0x207>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b70:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b73:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b76:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b79:	83 ec 08             	sub    $0x8,%esp
f0100b7c:	56                   	push   %esi
f0100b7d:	6a 24                	push   $0x24
f0100b7f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b82:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b85:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100b8a:	e8 2a fe ff ff       	call   f01009b9 <stab_binsearch>

	if (lfun <= rfun) {
f0100b8f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b92:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b95:	83 c4 10             	add    $0x10,%esp
f0100b98:	39 d0                	cmp    %edx,%eax
f0100b9a:	7f 40                	jg     f0100bdc <debuginfo_eip+0x121>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b9c:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b9f:	c1 e1 02             	shl    $0x2,%ecx
f0100ba2:	8d b9 70 21 10 f0    	lea    -0xfefde90(%ecx),%edi
f0100ba8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bab:	8b b9 70 21 10 f0    	mov    -0xfefde90(%ecx),%edi
f0100bb1:	b9 3a 74 10 f0       	mov    $0xf010743a,%ecx
f0100bb6:	81 e9 0d 5b 10 f0    	sub    $0xf0105b0d,%ecx
f0100bbc:	39 cf                	cmp    %ecx,%edi
f0100bbe:	73 09                	jae    f0100bc9 <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bc0:	81 c7 0d 5b 10 f0    	add    $0xf0105b0d,%edi
f0100bc6:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bc9:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bcc:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bcf:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bd2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bd4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bd7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bda:	eb 0f                	jmp    f0100beb <debuginfo_eip+0x130>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bdc:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bdf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100be2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100be5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100be8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100beb:	83 ec 08             	sub    $0x8,%esp
f0100bee:	6a 3a                	push   $0x3a
f0100bf0:	ff 73 08             	pushl  0x8(%ebx)
f0100bf3:	e8 80 08 00 00       	call   f0101478 <strfind>
f0100bf8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bfb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bfe:	83 c4 08             	add    $0x8,%esp
f0100c01:	56                   	push   %esi
f0100c02:	6a 44                	push   $0x44
f0100c04:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c07:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c0a:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100c0f:	e8 a5 fd ff ff       	call   f01009b9 <stab_binsearch>
	if(lline <= rline)
f0100c14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c17:	83 c4 10             	add    $0x10,%esp
f0100c1a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c1d:	0f 8f a6 00 00 00    	jg     f0100cc9 <debuginfo_eip+0x20e>
	{
		info->eip_line = stabs[lline].n_desc;
f0100c23:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c26:	0f b7 04 85 76 21 10 	movzwl -0xfefde8a(,%eax,4),%eax
f0100c2d:	f0 
f0100c2e:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c37:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c3a:	8d 14 95 70 21 10 f0 	lea    -0xfefde90(,%edx,4),%edx
f0100c41:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100c44:	eb 06                	jmp    f0100c4c <debuginfo_eip+0x191>
f0100c46:	83 e8 01             	sub    $0x1,%eax
f0100c49:	83 ea 0c             	sub    $0xc,%edx
f0100c4c:	39 c7                	cmp    %eax,%edi
f0100c4e:	7f 23                	jg     f0100c73 <debuginfo_eip+0x1b8>
	       && stabs[lline].n_type != N_SOL
f0100c50:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c54:	80 f9 84             	cmp    $0x84,%cl
f0100c57:	74 7e                	je     f0100cd7 <debuginfo_eip+0x21c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c59:	80 f9 64             	cmp    $0x64,%cl
f0100c5c:	75 e8                	jne    f0100c46 <debuginfo_eip+0x18b>
f0100c5e:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c62:	74 e2                	je     f0100c46 <debuginfo_eip+0x18b>
f0100c64:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100c67:	eb 71                	jmp    f0100cda <debuginfo_eip+0x21f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c69:	81 c2 0d 5b 10 f0    	add    $0xf0105b0d,%edx
f0100c6f:	89 13                	mov    %edx,(%ebx)
f0100c71:	eb 03                	jmp    f0100c76 <debuginfo_eip+0x1bb>
f0100c73:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c76:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c79:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c7c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c81:	39 f2                	cmp    %esi,%edx
f0100c83:	7d 76                	jge    f0100cfb <debuginfo_eip+0x240>
		for (lline = lfun + 1;
f0100c85:	83 c2 01             	add    $0x1,%edx
f0100c88:	89 d0                	mov    %edx,%eax
f0100c8a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c8d:	8d 14 95 70 21 10 f0 	lea    -0xfefde90(,%edx,4),%edx
f0100c94:	eb 04                	jmp    f0100c9a <debuginfo_eip+0x1df>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c96:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c9a:	39 c6                	cmp    %eax,%esi
f0100c9c:	7e 32                	jle    f0100cd0 <debuginfo_eip+0x215>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c9e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100ca2:	83 c0 01             	add    $0x1,%eax
f0100ca5:	83 c2 0c             	add    $0xc,%edx
f0100ca8:	80 f9 a0             	cmp    $0xa0,%cl
f0100cab:	74 e9                	je     f0100c96 <debuginfo_eip+0x1db>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cad:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb2:	eb 47                	jmp    f0100cfb <debuginfo_eip+0x240>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb9:	eb 40                	jmp    f0100cfb <debuginfo_eip+0x240>
f0100cbb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc0:	eb 39                	jmp    f0100cfb <debuginfo_eip+0x240>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc7:	eb 32                	jmp    f0100cfb <debuginfo_eip+0x240>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline)
	{
		info->eip_line = stabs[lline].n_desc;
	}
	else return -1;
f0100cc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cce:	eb 2b                	jmp    f0100cfb <debuginfo_eip+0x240>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd5:	eb 24                	jmp    f0100cfb <debuginfo_eip+0x240>
f0100cd7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cda:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100cdd:	8b 14 85 70 21 10 f0 	mov    -0xfefde90(,%eax,4),%edx
f0100ce4:	b8 3a 74 10 f0       	mov    $0xf010743a,%eax
f0100ce9:	2d 0d 5b 10 f0       	sub    $0xf0105b0d,%eax
f0100cee:	39 c2                	cmp    %eax,%edx
f0100cf0:	0f 82 73 ff ff ff    	jb     f0100c69 <debuginfo_eip+0x1ae>
f0100cf6:	e9 7b ff ff ff       	jmp    f0100c76 <debuginfo_eip+0x1bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100cfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cfe:	5b                   	pop    %ebx
f0100cff:	5e                   	pop    %esi
f0100d00:	5f                   	pop    %edi
f0100d01:	5d                   	pop    %ebp
f0100d02:	c3                   	ret    

f0100d03 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d03:	55                   	push   %ebp
f0100d04:	89 e5                	mov    %esp,%ebp
f0100d06:	57                   	push   %edi
f0100d07:	56                   	push   %esi
f0100d08:	53                   	push   %ebx
f0100d09:	83 ec 1c             	sub    $0x1c,%esp
f0100d0c:	89 c7                	mov    %eax,%edi
f0100d0e:	89 d6                	mov    %edx,%esi
f0100d10:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d13:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d16:	89 d1                	mov    %edx,%ecx
f0100d18:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d21:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d24:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d27:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d2e:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d31:	72 05                	jb     f0100d38 <printnum+0x35>
f0100d33:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d36:	77 3e                	ja     f0100d76 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d38:	83 ec 0c             	sub    $0xc,%esp
f0100d3b:	ff 75 18             	pushl  0x18(%ebp)
f0100d3e:	83 eb 01             	sub    $0x1,%ebx
f0100d41:	53                   	push   %ebx
f0100d42:	50                   	push   %eax
f0100d43:	83 ec 08             	sub    $0x8,%esp
f0100d46:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d49:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d4c:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d4f:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d52:	e8 49 09 00 00       	call   f01016a0 <__udivdi3>
f0100d57:	83 c4 18             	add    $0x18,%esp
f0100d5a:	52                   	push   %edx
f0100d5b:	50                   	push   %eax
f0100d5c:	89 f2                	mov    %esi,%edx
f0100d5e:	89 f8                	mov    %edi,%eax
f0100d60:	e8 9e ff ff ff       	call   f0100d03 <printnum>
f0100d65:	83 c4 20             	add    $0x20,%esp
f0100d68:	eb 13                	jmp    f0100d7d <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d6a:	83 ec 08             	sub    $0x8,%esp
f0100d6d:	56                   	push   %esi
f0100d6e:	ff 75 18             	pushl  0x18(%ebp)
f0100d71:	ff d7                	call   *%edi
f0100d73:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d76:	83 eb 01             	sub    $0x1,%ebx
f0100d79:	85 db                	test   %ebx,%ebx
f0100d7b:	7f ed                	jg     f0100d6a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d7d:	83 ec 08             	sub    $0x8,%esp
f0100d80:	56                   	push   %esi
f0100d81:	83 ec 04             	sub    $0x4,%esp
f0100d84:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d87:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d8a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d8d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d90:	e8 3b 0a 00 00       	call   f01017d0 <__umoddi3>
f0100d95:	83 c4 14             	add    $0x14,%esp
f0100d98:	0f be 80 49 1f 10 f0 	movsbl -0xfefe0b7(%eax),%eax
f0100d9f:	50                   	push   %eax
f0100da0:	ff d7                	call   *%edi
f0100da2:	83 c4 10             	add    $0x10,%esp
}
f0100da5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100da8:	5b                   	pop    %ebx
f0100da9:	5e                   	pop    %esi
f0100daa:	5f                   	pop    %edi
f0100dab:	5d                   	pop    %ebp
f0100dac:	c3                   	ret    

f0100dad <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dad:	55                   	push   %ebp
f0100dae:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100db0:	83 fa 01             	cmp    $0x1,%edx
f0100db3:	7e 0e                	jle    f0100dc3 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100db5:	8b 10                	mov    (%eax),%edx
f0100db7:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dba:	89 08                	mov    %ecx,(%eax)
f0100dbc:	8b 02                	mov    (%edx),%eax
f0100dbe:	8b 52 04             	mov    0x4(%edx),%edx
f0100dc1:	eb 22                	jmp    f0100de5 <getuint+0x38>
	else if (lflag)
f0100dc3:	85 d2                	test   %edx,%edx
f0100dc5:	74 10                	je     f0100dd7 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100dc7:	8b 10                	mov    (%eax),%edx
f0100dc9:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dcc:	89 08                	mov    %ecx,(%eax)
f0100dce:	8b 02                	mov    (%edx),%eax
f0100dd0:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dd5:	eb 0e                	jmp    f0100de5 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dd7:	8b 10                	mov    (%eax),%edx
f0100dd9:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ddc:	89 08                	mov    %ecx,(%eax)
f0100dde:	8b 02                	mov    (%edx),%eax
f0100de0:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100de5:	5d                   	pop    %ebp
f0100de6:	c3                   	ret    

f0100de7 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100de7:	55                   	push   %ebp
f0100de8:	89 e5                	mov    %esp,%ebp
f0100dea:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ded:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100df1:	8b 10                	mov    (%eax),%edx
f0100df3:	3b 50 04             	cmp    0x4(%eax),%edx
f0100df6:	73 0a                	jae    f0100e02 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100df8:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dfb:	89 08                	mov    %ecx,(%eax)
f0100dfd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e00:	88 02                	mov    %al,(%edx)
}
f0100e02:	5d                   	pop    %ebp
f0100e03:	c3                   	ret    

f0100e04 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e04:	55                   	push   %ebp
f0100e05:	89 e5                	mov    %esp,%ebp
f0100e07:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e0a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e0d:	50                   	push   %eax
f0100e0e:	ff 75 10             	pushl  0x10(%ebp)
f0100e11:	ff 75 0c             	pushl  0xc(%ebp)
f0100e14:	ff 75 08             	pushl  0x8(%ebp)
f0100e17:	e8 05 00 00 00       	call   f0100e21 <vprintfmt>
	va_end(ap);
f0100e1c:	83 c4 10             	add    $0x10,%esp
}
f0100e1f:	c9                   	leave  
f0100e20:	c3                   	ret    

f0100e21 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e21:	55                   	push   %ebp
f0100e22:	89 e5                	mov    %esp,%ebp
f0100e24:	57                   	push   %edi
f0100e25:	56                   	push   %esi
f0100e26:	53                   	push   %ebx
f0100e27:	83 ec 2c             	sub    $0x2c,%esp
f0100e2a:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e30:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e33:	eb 12                	jmp    f0100e47 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e35:	85 c0                	test   %eax,%eax
f0100e37:	0f 84 90 03 00 00    	je     f01011cd <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0100e3d:	83 ec 08             	sub    $0x8,%esp
f0100e40:	53                   	push   %ebx
f0100e41:	50                   	push   %eax
f0100e42:	ff d6                	call   *%esi
f0100e44:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e47:	83 c7 01             	add    $0x1,%edi
f0100e4a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e4e:	83 f8 25             	cmp    $0x25,%eax
f0100e51:	75 e2                	jne    f0100e35 <vprintfmt+0x14>
f0100e53:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e57:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e5e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e65:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e6c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e71:	eb 07                	jmp    f0100e7a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e73:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e76:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7a:	8d 47 01             	lea    0x1(%edi),%eax
f0100e7d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e80:	0f b6 07             	movzbl (%edi),%eax
f0100e83:	0f b6 c8             	movzbl %al,%ecx
f0100e86:	83 e8 23             	sub    $0x23,%eax
f0100e89:	3c 55                	cmp    $0x55,%al
f0100e8b:	0f 87 21 03 00 00    	ja     f01011b2 <vprintfmt+0x391>
f0100e91:	0f b6 c0             	movzbl %al,%eax
f0100e94:	ff 24 85 e0 1f 10 f0 	jmp    *-0xfefe020(,%eax,4)
f0100e9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e9e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ea2:	eb d6                	jmp    f0100e7a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eac:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100eaf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100eb2:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100eb6:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100eb9:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100ebc:	83 fa 09             	cmp    $0x9,%edx
f0100ebf:	77 39                	ja     f0100efa <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ec1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ec4:	eb e9                	jmp    f0100eaf <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ec6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec9:	8d 48 04             	lea    0x4(%eax),%ecx
f0100ecc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ecf:	8b 00                	mov    (%eax),%eax
f0100ed1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ed7:	eb 27                	jmp    f0100f00 <vprintfmt+0xdf>
f0100ed9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100edc:	85 c0                	test   %eax,%eax
f0100ede:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ee3:	0f 49 c8             	cmovns %eax,%ecx
f0100ee6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eec:	eb 8c                	jmp    f0100e7a <vprintfmt+0x59>
f0100eee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ef1:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ef8:	eb 80                	jmp    f0100e7a <vprintfmt+0x59>
f0100efa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100efd:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f00:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f04:	0f 89 70 ff ff ff    	jns    f0100e7a <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f0d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f10:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f17:	e9 5e ff ff ff       	jmp    f0100e7a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f1c:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f22:	e9 53 ff ff ff       	jmp    f0100e7a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f27:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2a:	8d 50 04             	lea    0x4(%eax),%edx
f0100f2d:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f30:	83 ec 08             	sub    $0x8,%esp
f0100f33:	53                   	push   %ebx
f0100f34:	ff 30                	pushl  (%eax)
f0100f36:	ff d6                	call   *%esi
			break;
f0100f38:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f3e:	e9 04 ff ff ff       	jmp    f0100e47 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f46:	8d 50 04             	lea    0x4(%eax),%edx
f0100f49:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f4c:	8b 00                	mov    (%eax),%eax
f0100f4e:	99                   	cltd   
f0100f4f:	31 d0                	xor    %edx,%eax
f0100f51:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f53:	83 f8 07             	cmp    $0x7,%eax
f0100f56:	7f 0b                	jg     f0100f63 <vprintfmt+0x142>
f0100f58:	8b 14 85 40 21 10 f0 	mov    -0xfefdec0(,%eax,4),%edx
f0100f5f:	85 d2                	test   %edx,%edx
f0100f61:	75 18                	jne    f0100f7b <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f63:	50                   	push   %eax
f0100f64:	68 61 1f 10 f0       	push   $0xf0101f61
f0100f69:	53                   	push   %ebx
f0100f6a:	56                   	push   %esi
f0100f6b:	e8 94 fe ff ff       	call   f0100e04 <printfmt>
f0100f70:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f76:	e9 cc fe ff ff       	jmp    f0100e47 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f7b:	52                   	push   %edx
f0100f7c:	68 1b 1d 10 f0       	push   $0xf0101d1b
f0100f81:	53                   	push   %ebx
f0100f82:	56                   	push   %esi
f0100f83:	e8 7c fe ff ff       	call   f0100e04 <printfmt>
f0100f88:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f8e:	e9 b4 fe ff ff       	jmp    f0100e47 <vprintfmt+0x26>
f0100f93:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100f96:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f99:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f9c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9f:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa2:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fa7:	85 ff                	test   %edi,%edi
f0100fa9:	ba 5a 1f 10 f0       	mov    $0xf0101f5a,%edx
f0100fae:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0100fb1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fb5:	0f 84 92 00 00 00    	je     f010104d <vprintfmt+0x22c>
f0100fbb:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100fbf:	0f 8e 96 00 00 00    	jle    f010105b <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc5:	83 ec 08             	sub    $0x8,%esp
f0100fc8:	51                   	push   %ecx
f0100fc9:	57                   	push   %edi
f0100fca:	e8 5f 03 00 00       	call   f010132e <strnlen>
f0100fcf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fd2:	29 c1                	sub    %eax,%ecx
f0100fd4:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100fd7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fda:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fde:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fe1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fe4:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fe6:	eb 0f                	jmp    f0100ff7 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100fe8:	83 ec 08             	sub    $0x8,%esp
f0100feb:	53                   	push   %ebx
f0100fec:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff1:	83 ef 01             	sub    $0x1,%edi
f0100ff4:	83 c4 10             	add    $0x10,%esp
f0100ff7:	85 ff                	test   %edi,%edi
f0100ff9:	7f ed                	jg     f0100fe8 <vprintfmt+0x1c7>
f0100ffb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ffe:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101001:	85 c9                	test   %ecx,%ecx
f0101003:	b8 00 00 00 00       	mov    $0x0,%eax
f0101008:	0f 49 c1             	cmovns %ecx,%eax
f010100b:	29 c1                	sub    %eax,%ecx
f010100d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101010:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101013:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101016:	89 cb                	mov    %ecx,%ebx
f0101018:	eb 4d                	jmp    f0101067 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010101a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010101e:	74 1b                	je     f010103b <vprintfmt+0x21a>
f0101020:	0f be c0             	movsbl %al,%eax
f0101023:	83 e8 20             	sub    $0x20,%eax
f0101026:	83 f8 5e             	cmp    $0x5e,%eax
f0101029:	76 10                	jbe    f010103b <vprintfmt+0x21a>
					putch('?', putdat);
f010102b:	83 ec 08             	sub    $0x8,%esp
f010102e:	ff 75 0c             	pushl  0xc(%ebp)
f0101031:	6a 3f                	push   $0x3f
f0101033:	ff 55 08             	call   *0x8(%ebp)
f0101036:	83 c4 10             	add    $0x10,%esp
f0101039:	eb 0d                	jmp    f0101048 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f010103b:	83 ec 08             	sub    $0x8,%esp
f010103e:	ff 75 0c             	pushl  0xc(%ebp)
f0101041:	52                   	push   %edx
f0101042:	ff 55 08             	call   *0x8(%ebp)
f0101045:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101048:	83 eb 01             	sub    $0x1,%ebx
f010104b:	eb 1a                	jmp    f0101067 <vprintfmt+0x246>
f010104d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101050:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101053:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101056:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101059:	eb 0c                	jmp    f0101067 <vprintfmt+0x246>
f010105b:	89 75 08             	mov    %esi,0x8(%ebp)
f010105e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101061:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101064:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101067:	83 c7 01             	add    $0x1,%edi
f010106a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010106e:	0f be d0             	movsbl %al,%edx
f0101071:	85 d2                	test   %edx,%edx
f0101073:	74 23                	je     f0101098 <vprintfmt+0x277>
f0101075:	85 f6                	test   %esi,%esi
f0101077:	78 a1                	js     f010101a <vprintfmt+0x1f9>
f0101079:	83 ee 01             	sub    $0x1,%esi
f010107c:	79 9c                	jns    f010101a <vprintfmt+0x1f9>
f010107e:	89 df                	mov    %ebx,%edi
f0101080:	8b 75 08             	mov    0x8(%ebp),%esi
f0101083:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101086:	eb 18                	jmp    f01010a0 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101088:	83 ec 08             	sub    $0x8,%esp
f010108b:	53                   	push   %ebx
f010108c:	6a 20                	push   $0x20
f010108e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101090:	83 ef 01             	sub    $0x1,%edi
f0101093:	83 c4 10             	add    $0x10,%esp
f0101096:	eb 08                	jmp    f01010a0 <vprintfmt+0x27f>
f0101098:	89 df                	mov    %ebx,%edi
f010109a:	8b 75 08             	mov    0x8(%ebp),%esi
f010109d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010a0:	85 ff                	test   %edi,%edi
f01010a2:	7f e4                	jg     f0101088 <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010a7:	e9 9b fd ff ff       	jmp    f0100e47 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010ac:	83 fa 01             	cmp    $0x1,%edx
f01010af:	7e 16                	jle    f01010c7 <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f01010b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b4:	8d 50 08             	lea    0x8(%eax),%edx
f01010b7:	89 55 14             	mov    %edx,0x14(%ebp)
f01010ba:	8b 50 04             	mov    0x4(%eax),%edx
f01010bd:	8b 00                	mov    (%eax),%eax
f01010bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010c5:	eb 32                	jmp    f01010f9 <vprintfmt+0x2d8>
	else if (lflag)
f01010c7:	85 d2                	test   %edx,%edx
f01010c9:	74 18                	je     f01010e3 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f01010cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ce:	8d 50 04             	lea    0x4(%eax),%edx
f01010d1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010d4:	8b 00                	mov    (%eax),%eax
f01010d6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010d9:	89 c1                	mov    %eax,%ecx
f01010db:	c1 f9 1f             	sar    $0x1f,%ecx
f01010de:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010e1:	eb 16                	jmp    f01010f9 <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f01010e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e6:	8d 50 04             	lea    0x4(%eax),%edx
f01010e9:	89 55 14             	mov    %edx,0x14(%ebp)
f01010ec:	8b 00                	mov    (%eax),%eax
f01010ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f1:	89 c1                	mov    %eax,%ecx
f01010f3:	c1 f9 1f             	sar    $0x1f,%ecx
f01010f6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010fc:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010ff:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101104:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101108:	79 74                	jns    f010117e <vprintfmt+0x35d>
				putch('-', putdat);
f010110a:	83 ec 08             	sub    $0x8,%esp
f010110d:	53                   	push   %ebx
f010110e:	6a 2d                	push   $0x2d
f0101110:	ff d6                	call   *%esi
				num = -(long long) num;
f0101112:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101115:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101118:	f7 d8                	neg    %eax
f010111a:	83 d2 00             	adc    $0x0,%edx
f010111d:	f7 da                	neg    %edx
f010111f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101122:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101127:	eb 55                	jmp    f010117e <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101129:	8d 45 14             	lea    0x14(%ebp),%eax
f010112c:	e8 7c fc ff ff       	call   f0100dad <getuint>
			base = 10;
f0101131:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101136:	eb 46                	jmp    f010117e <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0101138:	8d 45 14             	lea    0x14(%ebp),%eax
f010113b:	e8 6d fc ff ff       	call   f0100dad <getuint>
			base = 8;
f0101140:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101145:	eb 37                	jmp    f010117e <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101147:	83 ec 08             	sub    $0x8,%esp
f010114a:	53                   	push   %ebx
f010114b:	6a 30                	push   $0x30
f010114d:	ff d6                	call   *%esi
			putch('x', putdat);
f010114f:	83 c4 08             	add    $0x8,%esp
f0101152:	53                   	push   %ebx
f0101153:	6a 78                	push   $0x78
f0101155:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101157:	8b 45 14             	mov    0x14(%ebp),%eax
f010115a:	8d 50 04             	lea    0x4(%eax),%edx
f010115d:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101160:	8b 00                	mov    (%eax),%eax
f0101162:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101167:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010116a:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010116f:	eb 0d                	jmp    f010117e <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101171:	8d 45 14             	lea    0x14(%ebp),%eax
f0101174:	e8 34 fc ff ff       	call   f0100dad <getuint>
			base = 16;
f0101179:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010117e:	83 ec 0c             	sub    $0xc,%esp
f0101181:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101185:	57                   	push   %edi
f0101186:	ff 75 e0             	pushl  -0x20(%ebp)
f0101189:	51                   	push   %ecx
f010118a:	52                   	push   %edx
f010118b:	50                   	push   %eax
f010118c:	89 da                	mov    %ebx,%edx
f010118e:	89 f0                	mov    %esi,%eax
f0101190:	e8 6e fb ff ff       	call   f0100d03 <printnum>
			break;
f0101195:	83 c4 20             	add    $0x20,%esp
f0101198:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010119b:	e9 a7 fc ff ff       	jmp    f0100e47 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011a0:	83 ec 08             	sub    $0x8,%esp
f01011a3:	53                   	push   %ebx
f01011a4:	51                   	push   %ecx
f01011a5:	ff d6                	call   *%esi
			break;
f01011a7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011ad:	e9 95 fc ff ff       	jmp    f0100e47 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011b2:	83 ec 08             	sub    $0x8,%esp
f01011b5:	53                   	push   %ebx
f01011b6:	6a 25                	push   $0x25
f01011b8:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011ba:	83 c4 10             	add    $0x10,%esp
f01011bd:	eb 03                	jmp    f01011c2 <vprintfmt+0x3a1>
f01011bf:	83 ef 01             	sub    $0x1,%edi
f01011c2:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011c6:	75 f7                	jne    f01011bf <vprintfmt+0x39e>
f01011c8:	e9 7a fc ff ff       	jmp    f0100e47 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d0:	5b                   	pop    %ebx
f01011d1:	5e                   	pop    %esi
f01011d2:	5f                   	pop    %edi
f01011d3:	5d                   	pop    %ebp
f01011d4:	c3                   	ret    

f01011d5 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011d5:	55                   	push   %ebp
f01011d6:	89 e5                	mov    %esp,%ebp
f01011d8:	83 ec 18             	sub    $0x18,%esp
f01011db:	8b 45 08             	mov    0x8(%ebp),%eax
f01011de:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011e1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011e4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011e8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011eb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011f2:	85 c0                	test   %eax,%eax
f01011f4:	74 26                	je     f010121c <vsnprintf+0x47>
f01011f6:	85 d2                	test   %edx,%edx
f01011f8:	7e 22                	jle    f010121c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011fa:	ff 75 14             	pushl  0x14(%ebp)
f01011fd:	ff 75 10             	pushl  0x10(%ebp)
f0101200:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101203:	50                   	push   %eax
f0101204:	68 e7 0d 10 f0       	push   $0xf0100de7
f0101209:	e8 13 fc ff ff       	call   f0100e21 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010120e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101211:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101214:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	eb 05                	jmp    f0101221 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010121c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101221:	c9                   	leave  
f0101222:	c3                   	ret    

f0101223 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101223:	55                   	push   %ebp
f0101224:	89 e5                	mov    %esp,%ebp
f0101226:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101229:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010122c:	50                   	push   %eax
f010122d:	ff 75 10             	pushl  0x10(%ebp)
f0101230:	ff 75 0c             	pushl  0xc(%ebp)
f0101233:	ff 75 08             	pushl  0x8(%ebp)
f0101236:	e8 9a ff ff ff       	call   f01011d5 <vsnprintf>
	va_end(ap);

	return rc;
}
f010123b:	c9                   	leave  
f010123c:	c3                   	ret    

f010123d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010123d:	55                   	push   %ebp
f010123e:	89 e5                	mov    %esp,%ebp
f0101240:	57                   	push   %edi
f0101241:	56                   	push   %esi
f0101242:	53                   	push   %ebx
f0101243:	83 ec 0c             	sub    $0xc,%esp
f0101246:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101249:	85 c0                	test   %eax,%eax
f010124b:	74 11                	je     f010125e <readline+0x21>
		cprintf("%s", prompt);
f010124d:	83 ec 08             	sub    $0x8,%esp
f0101250:	50                   	push   %eax
f0101251:	68 1b 1d 10 f0       	push   $0xf0101d1b
f0101256:	e8 4a f7 ff ff       	call   f01009a5 <cprintf>
f010125b:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010125e:	83 ec 0c             	sub    $0xc,%esp
f0101261:	6a 00                	push   $0x0
f0101263:	e8 f4 f3 ff ff       	call   f010065c <iscons>
f0101268:	89 c7                	mov    %eax,%edi
f010126a:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010126d:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101272:	e8 d4 f3 ff ff       	call   f010064b <getchar>
f0101277:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101279:	85 c0                	test   %eax,%eax
f010127b:	79 18                	jns    f0101295 <readline+0x58>
			cprintf("read error: %e\n", c);
f010127d:	83 ec 08             	sub    $0x8,%esp
f0101280:	50                   	push   %eax
f0101281:	68 60 21 10 f0       	push   $0xf0102160
f0101286:	e8 1a f7 ff ff       	call   f01009a5 <cprintf>
			return NULL;
f010128b:	83 c4 10             	add    $0x10,%esp
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101293:	eb 79                	jmp    f010130e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101295:	83 f8 7f             	cmp    $0x7f,%eax
f0101298:	0f 94 c2             	sete   %dl
f010129b:	83 f8 08             	cmp    $0x8,%eax
f010129e:	0f 94 c0             	sete   %al
f01012a1:	08 c2                	or     %al,%dl
f01012a3:	74 1a                	je     f01012bf <readline+0x82>
f01012a5:	85 f6                	test   %esi,%esi
f01012a7:	7e 16                	jle    f01012bf <readline+0x82>
			if (echoing)
f01012a9:	85 ff                	test   %edi,%edi
f01012ab:	74 0d                	je     f01012ba <readline+0x7d>
				cputchar('\b');
f01012ad:	83 ec 0c             	sub    $0xc,%esp
f01012b0:	6a 08                	push   $0x8
f01012b2:	e8 84 f3 ff ff       	call   f010063b <cputchar>
f01012b7:	83 c4 10             	add    $0x10,%esp
			i--;
f01012ba:	83 ee 01             	sub    $0x1,%esi
f01012bd:	eb b3                	jmp    f0101272 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012bf:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012c5:	7f 20                	jg     f01012e7 <readline+0xaa>
f01012c7:	83 fb 1f             	cmp    $0x1f,%ebx
f01012ca:	7e 1b                	jle    f01012e7 <readline+0xaa>
			if (echoing)
f01012cc:	85 ff                	test   %edi,%edi
f01012ce:	74 0c                	je     f01012dc <readline+0x9f>
				cputchar(c);
f01012d0:	83 ec 0c             	sub    $0xc,%esp
f01012d3:	53                   	push   %ebx
f01012d4:	e8 62 f3 ff ff       	call   f010063b <cputchar>
f01012d9:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012dc:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f01012e2:	8d 76 01             	lea    0x1(%esi),%esi
f01012e5:	eb 8b                	jmp    f0101272 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012e7:	83 fb 0d             	cmp    $0xd,%ebx
f01012ea:	74 05                	je     f01012f1 <readline+0xb4>
f01012ec:	83 fb 0a             	cmp    $0xa,%ebx
f01012ef:	75 81                	jne    f0101272 <readline+0x35>
			if (echoing)
f01012f1:	85 ff                	test   %edi,%edi
f01012f3:	74 0d                	je     f0101302 <readline+0xc5>
				cputchar('\n');
f01012f5:	83 ec 0c             	sub    $0xc,%esp
f01012f8:	6a 0a                	push   $0xa
f01012fa:	e8 3c f3 ff ff       	call   f010063b <cputchar>
f01012ff:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101302:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f0101309:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f010130e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101311:	5b                   	pop    %ebx
f0101312:	5e                   	pop    %esi
f0101313:	5f                   	pop    %edi
f0101314:	5d                   	pop    %ebp
f0101315:	c3                   	ret    

f0101316 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101316:	55                   	push   %ebp
f0101317:	89 e5                	mov    %esp,%ebp
f0101319:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010131c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101321:	eb 03                	jmp    f0101326 <strlen+0x10>
		n++;
f0101323:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101326:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010132a:	75 f7                	jne    f0101323 <strlen+0xd>
		n++;
	return n;
}
f010132c:	5d                   	pop    %ebp
f010132d:	c3                   	ret    

f010132e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010132e:	55                   	push   %ebp
f010132f:	89 e5                	mov    %esp,%ebp
f0101331:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101334:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101337:	ba 00 00 00 00       	mov    $0x0,%edx
f010133c:	eb 03                	jmp    f0101341 <strnlen+0x13>
		n++;
f010133e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101341:	39 c2                	cmp    %eax,%edx
f0101343:	74 08                	je     f010134d <strnlen+0x1f>
f0101345:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101349:	75 f3                	jne    f010133e <strnlen+0x10>
f010134b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010134d:	5d                   	pop    %ebp
f010134e:	c3                   	ret    

f010134f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010134f:	55                   	push   %ebp
f0101350:	89 e5                	mov    %esp,%ebp
f0101352:	53                   	push   %ebx
f0101353:	8b 45 08             	mov    0x8(%ebp),%eax
f0101356:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101359:	89 c2                	mov    %eax,%edx
f010135b:	83 c2 01             	add    $0x1,%edx
f010135e:	83 c1 01             	add    $0x1,%ecx
f0101361:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101365:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101368:	84 db                	test   %bl,%bl
f010136a:	75 ef                	jne    f010135b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010136c:	5b                   	pop    %ebx
f010136d:	5d                   	pop    %ebp
f010136e:	c3                   	ret    

f010136f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010136f:	55                   	push   %ebp
f0101370:	89 e5                	mov    %esp,%ebp
f0101372:	53                   	push   %ebx
f0101373:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101376:	53                   	push   %ebx
f0101377:	e8 9a ff ff ff       	call   f0101316 <strlen>
f010137c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010137f:	ff 75 0c             	pushl  0xc(%ebp)
f0101382:	01 d8                	add    %ebx,%eax
f0101384:	50                   	push   %eax
f0101385:	e8 c5 ff ff ff       	call   f010134f <strcpy>
	return dst;
}
f010138a:	89 d8                	mov    %ebx,%eax
f010138c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010138f:	c9                   	leave  
f0101390:	c3                   	ret    

f0101391 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101391:	55                   	push   %ebp
f0101392:	89 e5                	mov    %esp,%ebp
f0101394:	56                   	push   %esi
f0101395:	53                   	push   %ebx
f0101396:	8b 75 08             	mov    0x8(%ebp),%esi
f0101399:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010139c:	89 f3                	mov    %esi,%ebx
f010139e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a1:	89 f2                	mov    %esi,%edx
f01013a3:	eb 0f                	jmp    f01013b4 <strncpy+0x23>
		*dst++ = *src;
f01013a5:	83 c2 01             	add    $0x1,%edx
f01013a8:	0f b6 01             	movzbl (%ecx),%eax
f01013ab:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013ae:	80 39 01             	cmpb   $0x1,(%ecx)
f01013b1:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b4:	39 da                	cmp    %ebx,%edx
f01013b6:	75 ed                	jne    f01013a5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013b8:	89 f0                	mov    %esi,%eax
f01013ba:	5b                   	pop    %ebx
f01013bb:	5e                   	pop    %esi
f01013bc:	5d                   	pop    %ebp
f01013bd:	c3                   	ret    

f01013be <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013be:	55                   	push   %ebp
f01013bf:	89 e5                	mov    %esp,%ebp
f01013c1:	56                   	push   %esi
f01013c2:	53                   	push   %ebx
f01013c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01013c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013c9:	8b 55 10             	mov    0x10(%ebp),%edx
f01013cc:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013ce:	85 d2                	test   %edx,%edx
f01013d0:	74 21                	je     f01013f3 <strlcpy+0x35>
f01013d2:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013d6:	89 f2                	mov    %esi,%edx
f01013d8:	eb 09                	jmp    f01013e3 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013da:	83 c2 01             	add    $0x1,%edx
f01013dd:	83 c1 01             	add    $0x1,%ecx
f01013e0:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013e3:	39 c2                	cmp    %eax,%edx
f01013e5:	74 09                	je     f01013f0 <strlcpy+0x32>
f01013e7:	0f b6 19             	movzbl (%ecx),%ebx
f01013ea:	84 db                	test   %bl,%bl
f01013ec:	75 ec                	jne    f01013da <strlcpy+0x1c>
f01013ee:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013f0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013f3:	29 f0                	sub    %esi,%eax
}
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	5d                   	pop    %ebp
f01013f8:	c3                   	ret    

f01013f9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013f9:	55                   	push   %ebp
f01013fa:	89 e5                	mov    %esp,%ebp
f01013fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ff:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101402:	eb 06                	jmp    f010140a <strcmp+0x11>
		p++, q++;
f0101404:	83 c1 01             	add    $0x1,%ecx
f0101407:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010140a:	0f b6 01             	movzbl (%ecx),%eax
f010140d:	84 c0                	test   %al,%al
f010140f:	74 04                	je     f0101415 <strcmp+0x1c>
f0101411:	3a 02                	cmp    (%edx),%al
f0101413:	74 ef                	je     f0101404 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101415:	0f b6 c0             	movzbl %al,%eax
f0101418:	0f b6 12             	movzbl (%edx),%edx
f010141b:	29 d0                	sub    %edx,%eax
}
f010141d:	5d                   	pop    %ebp
f010141e:	c3                   	ret    

f010141f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010141f:	55                   	push   %ebp
f0101420:	89 e5                	mov    %esp,%ebp
f0101422:	53                   	push   %ebx
f0101423:	8b 45 08             	mov    0x8(%ebp),%eax
f0101426:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101429:	89 c3                	mov    %eax,%ebx
f010142b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010142e:	eb 06                	jmp    f0101436 <strncmp+0x17>
		n--, p++, q++;
f0101430:	83 c0 01             	add    $0x1,%eax
f0101433:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101436:	39 d8                	cmp    %ebx,%eax
f0101438:	74 15                	je     f010144f <strncmp+0x30>
f010143a:	0f b6 08             	movzbl (%eax),%ecx
f010143d:	84 c9                	test   %cl,%cl
f010143f:	74 04                	je     f0101445 <strncmp+0x26>
f0101441:	3a 0a                	cmp    (%edx),%cl
f0101443:	74 eb                	je     f0101430 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101445:	0f b6 00             	movzbl (%eax),%eax
f0101448:	0f b6 12             	movzbl (%edx),%edx
f010144b:	29 d0                	sub    %edx,%eax
f010144d:	eb 05                	jmp    f0101454 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010144f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101454:	5b                   	pop    %ebx
f0101455:	5d                   	pop    %ebp
f0101456:	c3                   	ret    

f0101457 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101457:	55                   	push   %ebp
f0101458:	89 e5                	mov    %esp,%ebp
f010145a:	8b 45 08             	mov    0x8(%ebp),%eax
f010145d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101461:	eb 07                	jmp    f010146a <strchr+0x13>
		if (*s == c)
f0101463:	38 ca                	cmp    %cl,%dl
f0101465:	74 0f                	je     f0101476 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101467:	83 c0 01             	add    $0x1,%eax
f010146a:	0f b6 10             	movzbl (%eax),%edx
f010146d:	84 d2                	test   %dl,%dl
f010146f:	75 f2                	jne    f0101463 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101471:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101476:	5d                   	pop    %ebp
f0101477:	c3                   	ret    

f0101478 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101478:	55                   	push   %ebp
f0101479:	89 e5                	mov    %esp,%ebp
f010147b:	8b 45 08             	mov    0x8(%ebp),%eax
f010147e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101482:	eb 03                	jmp    f0101487 <strfind+0xf>
f0101484:	83 c0 01             	add    $0x1,%eax
f0101487:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010148a:	84 d2                	test   %dl,%dl
f010148c:	74 04                	je     f0101492 <strfind+0x1a>
f010148e:	38 ca                	cmp    %cl,%dl
f0101490:	75 f2                	jne    f0101484 <strfind+0xc>
			break;
	return (char *) s;
}
f0101492:	5d                   	pop    %ebp
f0101493:	c3                   	ret    

f0101494 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101494:	55                   	push   %ebp
f0101495:	89 e5                	mov    %esp,%ebp
f0101497:	57                   	push   %edi
f0101498:	56                   	push   %esi
f0101499:	53                   	push   %ebx
f010149a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010149d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014a0:	85 c9                	test   %ecx,%ecx
f01014a2:	74 36                	je     f01014da <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014a4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014aa:	75 28                	jne    f01014d4 <memset+0x40>
f01014ac:	f6 c1 03             	test   $0x3,%cl
f01014af:	75 23                	jne    f01014d4 <memset+0x40>
		c &= 0xFF;
f01014b1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014b5:	89 d3                	mov    %edx,%ebx
f01014b7:	c1 e3 08             	shl    $0x8,%ebx
f01014ba:	89 d6                	mov    %edx,%esi
f01014bc:	c1 e6 18             	shl    $0x18,%esi
f01014bf:	89 d0                	mov    %edx,%eax
f01014c1:	c1 e0 10             	shl    $0x10,%eax
f01014c4:	09 f0                	or     %esi,%eax
f01014c6:	09 c2                	or     %eax,%edx
f01014c8:	89 d0                	mov    %edx,%eax
f01014ca:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014cc:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014cf:	fc                   	cld    
f01014d0:	f3 ab                	rep stos %eax,%es:(%edi)
f01014d2:	eb 06                	jmp    f01014da <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d7:	fc                   	cld    
f01014d8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014da:	89 f8                	mov    %edi,%eax
f01014dc:	5b                   	pop    %ebx
f01014dd:	5e                   	pop    %esi
f01014de:	5f                   	pop    %edi
f01014df:	5d                   	pop    %ebp
f01014e0:	c3                   	ret    

f01014e1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014e1:	55                   	push   %ebp
f01014e2:	89 e5                	mov    %esp,%ebp
f01014e4:	57                   	push   %edi
f01014e5:	56                   	push   %esi
f01014e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014ec:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014ef:	39 c6                	cmp    %eax,%esi
f01014f1:	73 35                	jae    f0101528 <memmove+0x47>
f01014f3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014f6:	39 d0                	cmp    %edx,%eax
f01014f8:	73 2e                	jae    f0101528 <memmove+0x47>
		s += n;
		d += n;
f01014fa:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01014fd:	89 d6                	mov    %edx,%esi
f01014ff:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101501:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101507:	75 13                	jne    f010151c <memmove+0x3b>
f0101509:	f6 c1 03             	test   $0x3,%cl
f010150c:	75 0e                	jne    f010151c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010150e:	83 ef 04             	sub    $0x4,%edi
f0101511:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101514:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101517:	fd                   	std    
f0101518:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010151a:	eb 09                	jmp    f0101525 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010151c:	83 ef 01             	sub    $0x1,%edi
f010151f:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101522:	fd                   	std    
f0101523:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101525:	fc                   	cld    
f0101526:	eb 1d                	jmp    f0101545 <memmove+0x64>
f0101528:	89 f2                	mov    %esi,%edx
f010152a:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010152c:	f6 c2 03             	test   $0x3,%dl
f010152f:	75 0f                	jne    f0101540 <memmove+0x5f>
f0101531:	f6 c1 03             	test   $0x3,%cl
f0101534:	75 0a                	jne    f0101540 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101536:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101539:	89 c7                	mov    %eax,%edi
f010153b:	fc                   	cld    
f010153c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010153e:	eb 05                	jmp    f0101545 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101540:	89 c7                	mov    %eax,%edi
f0101542:	fc                   	cld    
f0101543:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101545:	5e                   	pop    %esi
f0101546:	5f                   	pop    %edi
f0101547:	5d                   	pop    %ebp
f0101548:	c3                   	ret    

f0101549 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101549:	55                   	push   %ebp
f010154a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010154c:	ff 75 10             	pushl  0x10(%ebp)
f010154f:	ff 75 0c             	pushl  0xc(%ebp)
f0101552:	ff 75 08             	pushl  0x8(%ebp)
f0101555:	e8 87 ff ff ff       	call   f01014e1 <memmove>
}
f010155a:	c9                   	leave  
f010155b:	c3                   	ret    

f010155c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010155c:	55                   	push   %ebp
f010155d:	89 e5                	mov    %esp,%ebp
f010155f:	56                   	push   %esi
f0101560:	53                   	push   %ebx
f0101561:	8b 45 08             	mov    0x8(%ebp),%eax
f0101564:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101567:	89 c6                	mov    %eax,%esi
f0101569:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010156c:	eb 1a                	jmp    f0101588 <memcmp+0x2c>
		if (*s1 != *s2)
f010156e:	0f b6 08             	movzbl (%eax),%ecx
f0101571:	0f b6 1a             	movzbl (%edx),%ebx
f0101574:	38 d9                	cmp    %bl,%cl
f0101576:	74 0a                	je     f0101582 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101578:	0f b6 c1             	movzbl %cl,%eax
f010157b:	0f b6 db             	movzbl %bl,%ebx
f010157e:	29 d8                	sub    %ebx,%eax
f0101580:	eb 0f                	jmp    f0101591 <memcmp+0x35>
		s1++, s2++;
f0101582:	83 c0 01             	add    $0x1,%eax
f0101585:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101588:	39 f0                	cmp    %esi,%eax
f010158a:	75 e2                	jne    f010156e <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010158c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101591:	5b                   	pop    %ebx
f0101592:	5e                   	pop    %esi
f0101593:	5d                   	pop    %ebp
f0101594:	c3                   	ret    

f0101595 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101595:	55                   	push   %ebp
f0101596:	89 e5                	mov    %esp,%ebp
f0101598:	8b 45 08             	mov    0x8(%ebp),%eax
f010159b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010159e:	89 c2                	mov    %eax,%edx
f01015a0:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015a3:	eb 07                	jmp    f01015ac <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a5:	38 08                	cmp    %cl,(%eax)
f01015a7:	74 07                	je     f01015b0 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a9:	83 c0 01             	add    $0x1,%eax
f01015ac:	39 d0                	cmp    %edx,%eax
f01015ae:	72 f5                	jb     f01015a5 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015b0:	5d                   	pop    %ebp
f01015b1:	c3                   	ret    

f01015b2 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b2:	55                   	push   %ebp
f01015b3:	89 e5                	mov    %esp,%ebp
f01015b5:	57                   	push   %edi
f01015b6:	56                   	push   %esi
f01015b7:	53                   	push   %ebx
f01015b8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015bb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015be:	eb 03                	jmp    f01015c3 <strtol+0x11>
		s++;
f01015c0:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c3:	0f b6 01             	movzbl (%ecx),%eax
f01015c6:	3c 09                	cmp    $0x9,%al
f01015c8:	74 f6                	je     f01015c0 <strtol+0xe>
f01015ca:	3c 20                	cmp    $0x20,%al
f01015cc:	74 f2                	je     f01015c0 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015ce:	3c 2b                	cmp    $0x2b,%al
f01015d0:	75 0a                	jne    f01015dc <strtol+0x2a>
		s++;
f01015d2:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d5:	bf 00 00 00 00       	mov    $0x0,%edi
f01015da:	eb 10                	jmp    f01015ec <strtol+0x3a>
f01015dc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015e1:	3c 2d                	cmp    $0x2d,%al
f01015e3:	75 07                	jne    f01015ec <strtol+0x3a>
		s++, neg = 1;
f01015e5:	8d 49 01             	lea    0x1(%ecx),%ecx
f01015e8:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015ec:	85 db                	test   %ebx,%ebx
f01015ee:	0f 94 c0             	sete   %al
f01015f1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015f7:	75 19                	jne    f0101612 <strtol+0x60>
f01015f9:	80 39 30             	cmpb   $0x30,(%ecx)
f01015fc:	75 14                	jne    f0101612 <strtol+0x60>
f01015fe:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101602:	0f 85 82 00 00 00    	jne    f010168a <strtol+0xd8>
		s += 2, base = 16;
f0101608:	83 c1 02             	add    $0x2,%ecx
f010160b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101610:	eb 16                	jmp    f0101628 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101612:	84 c0                	test   %al,%al
f0101614:	74 12                	je     f0101628 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101616:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010161b:	80 39 30             	cmpb   $0x30,(%ecx)
f010161e:	75 08                	jne    f0101628 <strtol+0x76>
		s++, base = 8;
f0101620:	83 c1 01             	add    $0x1,%ecx
f0101623:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101628:	b8 00 00 00 00       	mov    $0x0,%eax
f010162d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101630:	0f b6 11             	movzbl (%ecx),%edx
f0101633:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101636:	89 f3                	mov    %esi,%ebx
f0101638:	80 fb 09             	cmp    $0x9,%bl
f010163b:	77 08                	ja     f0101645 <strtol+0x93>
			dig = *s - '0';
f010163d:	0f be d2             	movsbl %dl,%edx
f0101640:	83 ea 30             	sub    $0x30,%edx
f0101643:	eb 22                	jmp    f0101667 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0101645:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101648:	89 f3                	mov    %esi,%ebx
f010164a:	80 fb 19             	cmp    $0x19,%bl
f010164d:	77 08                	ja     f0101657 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010164f:	0f be d2             	movsbl %dl,%edx
f0101652:	83 ea 57             	sub    $0x57,%edx
f0101655:	eb 10                	jmp    f0101667 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0101657:	8d 72 bf             	lea    -0x41(%edx),%esi
f010165a:	89 f3                	mov    %esi,%ebx
f010165c:	80 fb 19             	cmp    $0x19,%bl
f010165f:	77 16                	ja     f0101677 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101661:	0f be d2             	movsbl %dl,%edx
f0101664:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101667:	3b 55 10             	cmp    0x10(%ebp),%edx
f010166a:	7d 0f                	jge    f010167b <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f010166c:	83 c1 01             	add    $0x1,%ecx
f010166f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101673:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101675:	eb b9                	jmp    f0101630 <strtol+0x7e>
f0101677:	89 c2                	mov    %eax,%edx
f0101679:	eb 02                	jmp    f010167d <strtol+0xcb>
f010167b:	89 c2                	mov    %eax,%edx

	if (endptr)
f010167d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101681:	74 0d                	je     f0101690 <strtol+0xde>
		*endptr = (char *) s;
f0101683:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101686:	89 0e                	mov    %ecx,(%esi)
f0101688:	eb 06                	jmp    f0101690 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010168a:	84 c0                	test   %al,%al
f010168c:	75 92                	jne    f0101620 <strtol+0x6e>
f010168e:	eb 98                	jmp    f0101628 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101690:	f7 da                	neg    %edx
f0101692:	85 ff                	test   %edi,%edi
f0101694:	0f 45 c2             	cmovne %edx,%eax
}
f0101697:	5b                   	pop    %ebx
f0101698:	5e                   	pop    %esi
f0101699:	5f                   	pop    %edi
f010169a:	5d                   	pop    %ebp
f010169b:	c3                   	ret    
f010169c:	66 90                	xchg   %ax,%ax
f010169e:	66 90                	xchg   %ax,%ax

f01016a0 <__udivdi3>:
f01016a0:	55                   	push   %ebp
f01016a1:	57                   	push   %edi
f01016a2:	56                   	push   %esi
f01016a3:	83 ec 10             	sub    $0x10,%esp
f01016a6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01016aa:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01016ae:	8b 74 24 24          	mov    0x24(%esp),%esi
f01016b2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01016b6:	85 d2                	test   %edx,%edx
f01016b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016bc:	89 34 24             	mov    %esi,(%esp)
f01016bf:	89 c8                	mov    %ecx,%eax
f01016c1:	75 35                	jne    f01016f8 <__udivdi3+0x58>
f01016c3:	39 f1                	cmp    %esi,%ecx
f01016c5:	0f 87 bd 00 00 00    	ja     f0101788 <__udivdi3+0xe8>
f01016cb:	85 c9                	test   %ecx,%ecx
f01016cd:	89 cd                	mov    %ecx,%ebp
f01016cf:	75 0b                	jne    f01016dc <__udivdi3+0x3c>
f01016d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d6:	31 d2                	xor    %edx,%edx
f01016d8:	f7 f1                	div    %ecx
f01016da:	89 c5                	mov    %eax,%ebp
f01016dc:	89 f0                	mov    %esi,%eax
f01016de:	31 d2                	xor    %edx,%edx
f01016e0:	f7 f5                	div    %ebp
f01016e2:	89 c6                	mov    %eax,%esi
f01016e4:	89 f8                	mov    %edi,%eax
f01016e6:	f7 f5                	div    %ebp
f01016e8:	89 f2                	mov    %esi,%edx
f01016ea:	83 c4 10             	add    $0x10,%esp
f01016ed:	5e                   	pop    %esi
f01016ee:	5f                   	pop    %edi
f01016ef:	5d                   	pop    %ebp
f01016f0:	c3                   	ret    
f01016f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016f8:	3b 14 24             	cmp    (%esp),%edx
f01016fb:	77 7b                	ja     f0101778 <__udivdi3+0xd8>
f01016fd:	0f bd f2             	bsr    %edx,%esi
f0101700:	83 f6 1f             	xor    $0x1f,%esi
f0101703:	0f 84 97 00 00 00    	je     f01017a0 <__udivdi3+0x100>
f0101709:	bd 20 00 00 00       	mov    $0x20,%ebp
f010170e:	89 d7                	mov    %edx,%edi
f0101710:	89 f1                	mov    %esi,%ecx
f0101712:	29 f5                	sub    %esi,%ebp
f0101714:	d3 e7                	shl    %cl,%edi
f0101716:	89 c2                	mov    %eax,%edx
f0101718:	89 e9                	mov    %ebp,%ecx
f010171a:	d3 ea                	shr    %cl,%edx
f010171c:	89 f1                	mov    %esi,%ecx
f010171e:	09 fa                	or     %edi,%edx
f0101720:	8b 3c 24             	mov    (%esp),%edi
f0101723:	d3 e0                	shl    %cl,%eax
f0101725:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101729:	89 e9                	mov    %ebp,%ecx
f010172b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010172f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101733:	89 fa                	mov    %edi,%edx
f0101735:	d3 ea                	shr    %cl,%edx
f0101737:	89 f1                	mov    %esi,%ecx
f0101739:	d3 e7                	shl    %cl,%edi
f010173b:	89 e9                	mov    %ebp,%ecx
f010173d:	d3 e8                	shr    %cl,%eax
f010173f:	09 c7                	or     %eax,%edi
f0101741:	89 f8                	mov    %edi,%eax
f0101743:	f7 74 24 08          	divl   0x8(%esp)
f0101747:	89 d5                	mov    %edx,%ebp
f0101749:	89 c7                	mov    %eax,%edi
f010174b:	f7 64 24 0c          	mull   0xc(%esp)
f010174f:	39 d5                	cmp    %edx,%ebp
f0101751:	89 14 24             	mov    %edx,(%esp)
f0101754:	72 11                	jb     f0101767 <__udivdi3+0xc7>
f0101756:	8b 54 24 04          	mov    0x4(%esp),%edx
f010175a:	89 f1                	mov    %esi,%ecx
f010175c:	d3 e2                	shl    %cl,%edx
f010175e:	39 c2                	cmp    %eax,%edx
f0101760:	73 5e                	jae    f01017c0 <__udivdi3+0x120>
f0101762:	3b 2c 24             	cmp    (%esp),%ebp
f0101765:	75 59                	jne    f01017c0 <__udivdi3+0x120>
f0101767:	8d 47 ff             	lea    -0x1(%edi),%eax
f010176a:	31 f6                	xor    %esi,%esi
f010176c:	89 f2                	mov    %esi,%edx
f010176e:	83 c4 10             	add    $0x10,%esp
f0101771:	5e                   	pop    %esi
f0101772:	5f                   	pop    %edi
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    
f0101775:	8d 76 00             	lea    0x0(%esi),%esi
f0101778:	31 f6                	xor    %esi,%esi
f010177a:	31 c0                	xor    %eax,%eax
f010177c:	89 f2                	mov    %esi,%edx
f010177e:	83 c4 10             	add    $0x10,%esp
f0101781:	5e                   	pop    %esi
f0101782:	5f                   	pop    %edi
f0101783:	5d                   	pop    %ebp
f0101784:	c3                   	ret    
f0101785:	8d 76 00             	lea    0x0(%esi),%esi
f0101788:	89 f2                	mov    %esi,%edx
f010178a:	31 f6                	xor    %esi,%esi
f010178c:	89 f8                	mov    %edi,%eax
f010178e:	f7 f1                	div    %ecx
f0101790:	89 f2                	mov    %esi,%edx
f0101792:	83 c4 10             	add    $0x10,%esp
f0101795:	5e                   	pop    %esi
f0101796:	5f                   	pop    %edi
f0101797:	5d                   	pop    %ebp
f0101798:	c3                   	ret    
f0101799:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017a0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01017a4:	76 0b                	jbe    f01017b1 <__udivdi3+0x111>
f01017a6:	31 c0                	xor    %eax,%eax
f01017a8:	3b 14 24             	cmp    (%esp),%edx
f01017ab:	0f 83 37 ff ff ff    	jae    f01016e8 <__udivdi3+0x48>
f01017b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01017b6:	e9 2d ff ff ff       	jmp    f01016e8 <__udivdi3+0x48>
f01017bb:	90                   	nop
f01017bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	89 f8                	mov    %edi,%eax
f01017c2:	31 f6                	xor    %esi,%esi
f01017c4:	e9 1f ff ff ff       	jmp    f01016e8 <__udivdi3+0x48>
f01017c9:	66 90                	xchg   %ax,%ax
f01017cb:	66 90                	xchg   %ax,%ax
f01017cd:	66 90                	xchg   %ax,%ax
f01017cf:	90                   	nop

f01017d0 <__umoddi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	83 ec 20             	sub    $0x20,%esp
f01017d6:	8b 44 24 34          	mov    0x34(%esp),%eax
f01017da:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017de:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017e2:	89 c6                	mov    %eax,%esi
f01017e4:	89 44 24 10          	mov    %eax,0x10(%esp)
f01017e8:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01017ec:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01017f0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017f4:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01017f8:	89 74 24 18          	mov    %esi,0x18(%esp)
f01017fc:	85 c0                	test   %eax,%eax
f01017fe:	89 c2                	mov    %eax,%edx
f0101800:	75 1e                	jne    f0101820 <__umoddi3+0x50>
f0101802:	39 f7                	cmp    %esi,%edi
f0101804:	76 52                	jbe    f0101858 <__umoddi3+0x88>
f0101806:	89 c8                	mov    %ecx,%eax
f0101808:	89 f2                	mov    %esi,%edx
f010180a:	f7 f7                	div    %edi
f010180c:	89 d0                	mov    %edx,%eax
f010180e:	31 d2                	xor    %edx,%edx
f0101810:	83 c4 20             	add    $0x20,%esp
f0101813:	5e                   	pop    %esi
f0101814:	5f                   	pop    %edi
f0101815:	5d                   	pop    %ebp
f0101816:	c3                   	ret    
f0101817:	89 f6                	mov    %esi,%esi
f0101819:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101820:	39 f0                	cmp    %esi,%eax
f0101822:	77 5c                	ja     f0101880 <__umoddi3+0xb0>
f0101824:	0f bd e8             	bsr    %eax,%ebp
f0101827:	83 f5 1f             	xor    $0x1f,%ebp
f010182a:	75 64                	jne    f0101890 <__umoddi3+0xc0>
f010182c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101830:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101834:	0f 86 f6 00 00 00    	jbe    f0101930 <__umoddi3+0x160>
f010183a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010183e:	0f 82 ec 00 00 00    	jb     f0101930 <__umoddi3+0x160>
f0101844:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101848:	8b 54 24 18          	mov    0x18(%esp),%edx
f010184c:	83 c4 20             	add    $0x20,%esp
f010184f:	5e                   	pop    %esi
f0101850:	5f                   	pop    %edi
f0101851:	5d                   	pop    %ebp
f0101852:	c3                   	ret    
f0101853:	90                   	nop
f0101854:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101858:	85 ff                	test   %edi,%edi
f010185a:	89 fd                	mov    %edi,%ebp
f010185c:	75 0b                	jne    f0101869 <__umoddi3+0x99>
f010185e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101863:	31 d2                	xor    %edx,%edx
f0101865:	f7 f7                	div    %edi
f0101867:	89 c5                	mov    %eax,%ebp
f0101869:	8b 44 24 10          	mov    0x10(%esp),%eax
f010186d:	31 d2                	xor    %edx,%edx
f010186f:	f7 f5                	div    %ebp
f0101871:	89 c8                	mov    %ecx,%eax
f0101873:	f7 f5                	div    %ebp
f0101875:	eb 95                	jmp    f010180c <__umoddi3+0x3c>
f0101877:	89 f6                	mov    %esi,%esi
f0101879:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101880:	89 c8                	mov    %ecx,%eax
f0101882:	89 f2                	mov    %esi,%edx
f0101884:	83 c4 20             	add    $0x20,%esp
f0101887:	5e                   	pop    %esi
f0101888:	5f                   	pop    %edi
f0101889:	5d                   	pop    %ebp
f010188a:	c3                   	ret    
f010188b:	90                   	nop
f010188c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101890:	b8 20 00 00 00       	mov    $0x20,%eax
f0101895:	89 e9                	mov    %ebp,%ecx
f0101897:	29 e8                	sub    %ebp,%eax
f0101899:	d3 e2                	shl    %cl,%edx
f010189b:	89 c7                	mov    %eax,%edi
f010189d:	89 44 24 18          	mov    %eax,0x18(%esp)
f01018a1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018a5:	89 f9                	mov    %edi,%ecx
f01018a7:	d3 e8                	shr    %cl,%eax
f01018a9:	89 c1                	mov    %eax,%ecx
f01018ab:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018af:	09 d1                	or     %edx,%ecx
f01018b1:	89 fa                	mov    %edi,%edx
f01018b3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018b7:	89 e9                	mov    %ebp,%ecx
f01018b9:	d3 e0                	shl    %cl,%eax
f01018bb:	89 f9                	mov    %edi,%ecx
f01018bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018c1:	89 f0                	mov    %esi,%eax
f01018c3:	d3 e8                	shr    %cl,%eax
f01018c5:	89 e9                	mov    %ebp,%ecx
f01018c7:	89 c7                	mov    %eax,%edi
f01018c9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01018cd:	d3 e6                	shl    %cl,%esi
f01018cf:	89 d1                	mov    %edx,%ecx
f01018d1:	89 fa                	mov    %edi,%edx
f01018d3:	d3 e8                	shr    %cl,%eax
f01018d5:	89 e9                	mov    %ebp,%ecx
f01018d7:	09 f0                	or     %esi,%eax
f01018d9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f01018dd:	f7 74 24 10          	divl   0x10(%esp)
f01018e1:	d3 e6                	shl    %cl,%esi
f01018e3:	89 d1                	mov    %edx,%ecx
f01018e5:	f7 64 24 0c          	mull   0xc(%esp)
f01018e9:	39 d1                	cmp    %edx,%ecx
f01018eb:	89 74 24 14          	mov    %esi,0x14(%esp)
f01018ef:	89 d7                	mov    %edx,%edi
f01018f1:	89 c6                	mov    %eax,%esi
f01018f3:	72 0a                	jb     f01018ff <__umoddi3+0x12f>
f01018f5:	39 44 24 14          	cmp    %eax,0x14(%esp)
f01018f9:	73 10                	jae    f010190b <__umoddi3+0x13b>
f01018fb:	39 d1                	cmp    %edx,%ecx
f01018fd:	75 0c                	jne    f010190b <__umoddi3+0x13b>
f01018ff:	89 d7                	mov    %edx,%edi
f0101901:	89 c6                	mov    %eax,%esi
f0101903:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101907:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010190b:	89 ca                	mov    %ecx,%edx
f010190d:	89 e9                	mov    %ebp,%ecx
f010190f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101913:	29 f0                	sub    %esi,%eax
f0101915:	19 fa                	sbb    %edi,%edx
f0101917:	d3 e8                	shr    %cl,%eax
f0101919:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010191e:	89 d7                	mov    %edx,%edi
f0101920:	d3 e7                	shl    %cl,%edi
f0101922:	89 e9                	mov    %ebp,%ecx
f0101924:	09 f8                	or     %edi,%eax
f0101926:	d3 ea                	shr    %cl,%edx
f0101928:	83 c4 20             	add    $0x20,%esp
f010192b:	5e                   	pop    %esi
f010192c:	5f                   	pop    %edi
f010192d:	5d                   	pop    %ebp
f010192e:	c3                   	ret    
f010192f:	90                   	nop
f0101930:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101934:	29 f9                	sub    %edi,%ecx
f0101936:	19 c6                	sbb    %eax,%esi
f0101938:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010193c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101940:	e9 ff fe ff ff       	jmp    f0101844 <__umoddi3+0x74>
