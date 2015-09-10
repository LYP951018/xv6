// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/mmu.h>
#include <kern/pmap.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace","Display infomation about the stack frame",mon_backtrace},
	{ "showmappings",
		"display the physical page mappings and corresponding permission bits",
		mon_showmappings },
		{"setmappings","Set Virtual Address",mon_setmappings},
		{"dumpmem","Dump the memory.-v for virtual address,-p for physical ",mon_dumpmem}
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

void mon_backtrace_helper(uint32_t* ebpAdr)
{
	uintptr_t eipAddr = (uintptr_t)ebpAdr[1];
	struct Eipdebuginfo info;
	int argsCount = 0;
	
	if(debuginfo_eip(eipAddr,&info) != -1)
	{
		// get the debug info sucessfully
		argsCount = info.eip_fn_narg;
		cprintf(" ebp %08x  eip %08x args",
		ebpAdr,
		ebpAdr[1]);
	int i = 0;
	for(;i < 5;++i)
	{
		cprintf(" %08x",ebpAdr[i+2]);	
	}
	cprintf("\n");
	cprintf("%s:%d: %.*s+%d\n",
		info.eip_file,
		info.eip_line,
		info.eip_fn_namelen,
		info.eip_fn_name,
		eipAddr - info.eip_fn_addr);
	}
	else assert(0);
	
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	//ignore argc & argv and tf?
	//get the ebp of mon_backtrace
	uint32_t* ebpAdr = (uint32_t*)read_ebp();
	cprintf ("Stack backtrace:\n");
	while(ebpAdr != NULL)
	{
		mon_backtrace_helper(ebpAdr);
		ebpAdr = (uint32_t*)(*ebpAdr);
	}
	
	return 0;
}



int showmappings(uint32_t lAddr,uint32_t rAddr)
{
	for(;lAddr < rAddr;lAddr += PGSIZE)
	{
		pde_t* pde = pgdir_walk(kern_pgdir,(void*)lAddr,false);
		cprintf("%x - %x     ",lAddr,lAddr + PGSIZE);
		if(pde == NULL) cprintf("Not mapped.\n");//TODO
		else
		{
			uint32_t pteContent = pde[0];
			cprintf("%x ",PTE_ADDR(pteContent));
			if(pteContent & PTE_P)
			{
				if(pteContent & PTE_U)
				{
					cprintf("User ");
				}
				else
				{
					cprintf("Kernel ");
				}
				if(pteContent & PTE_W)
				{
					cprintf("Read/Write ");
				}
				else
				{
					cprintf("Read ");
				}
				cprintf(" content %x ",((uint32_t*)lAddr)[0]);
			}
			else cprintf("Not mapped.\n");//TO DO
		}
		cprintf("\n");		
	}
	return 0;
}



int mon_showmappings(int argc,char** argv,struct Trapframe *tf)
{
	int i = 1;
	for(;i+1 < argc;i+=2)
	{
		char* lhs = argv[i];
		char* rhs = argv[i+1];
		cprintf("%s %s\n",lhs,rhs);
		uint32_t lAddr = strtol(lhs,NULL,16);
		uint32_t rAddr = strtol(rhs,NULL,16);
		//make lAddr align to the neasrest page
		if(lAddr < PGSIZE) lAddr = 0;
		else lAddr = lAddr - lAddr % PGSIZE;
		rAddr = ROUNDUP(rAddr,PGSIZE);
		showmappings(lAddr,rAddr);
		
	}
	return 0;
}

int mon_setmappings(int argc,char** argv,struct Trapframe *tf)
{
	if(argc == 5)
	{
		uint32_t startVA = strtol(argv[1],NULL,16);
		uint32_t pageNum = strtol(argv[2],NULL,10);
		uint32_t phyAddr = strtol(argv[3],NULL,16);
		uint32_t totalPageSize = pageNum * PGSIZE;
		if(startVA < PGSIZE) startVA = 0;
		else startVA = ROUNDUP((startVA - PGSIZE),PGSIZE);
		uint32_t i = 0;
		
		const char* permStr = argv[4];
		uint32_t perm = 0;
		if(permStr[0] == 'u' || permStr[0] == 'U')
			perm |= PTE_U;
		if(permStr[1] == 'w' || permStr[1] == 'W')
			perm |= PTE_W;
		for(;i < totalPageSize;i+=PGSIZE)
		{
			struct PageInfo* pp = pa2page(phyAddr + i);
			//if(pp->pp_ref == 0)
				//cprintf("setmappings:physical page 0x%x ~ 0x%x is not mounted.",
			//	phyAddr+i,phyAddr+i+PGSIZE);	
			//else
			{
				page_insert(kern_pgdir,pp,(void*)(startVA + i),perm);	
			}
		}
		showmappings(startVA,startVA + totalPageSize);
	}
	return 0;
}

void dumpmemv(uint32_t* start,uint32_t* end)
{
	uint32_t i = 0;
	for(;start < end;start += 4)
	{
		cprintf("0x%x:	0x%x 0x%x 0x%x 0x%x\n",start,start[0],start[1],start[2],start[3]);	
	}
}

void dumpmemp(physaddr_t start,physaddr_t end)
{
	for(;start < end;start+=16)
	{
		uint32_t i = 0;
		cprintf("0x%x:	",KADDR(start));
		for(;i < 4;++i)
		{
			uint32_t* va = KADDR(start+i*4);
			cprintf("0x%x ",*va);	
		}
		cprintf("\n");
	}
}


int mon_dumpmem(int argc,char** argv,struct Trapframe *tf)
{
	if(argc == 4)
	{
		const char* vOrP = argv[1];
		uint32_t byteCount = strtol(argv[3],NULL,10);
		if(vOrP[0] == 'v')
		{
			uint32_t startAddr = strtol(argv[2],NULL,16);
			dumpmemv((uint32_t*)startAddr,(uint32_t*)(startAddr + byteCount * 4));
		}
		else
		{
			physaddr_t startAddr = strtol(argv[2],NULL,16);
			dumpmemp(startAddr,startAddr+byteCount*4);
		}
	}
	return 0;
}


/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
	
	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
