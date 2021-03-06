// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
    void* addr = (void*)utf->utf_fault_va;
    uint32_t err = utf->utf_err;
    int r;

    // Check that the faulting access was (1) a write, and (2) to a
    // copy-on-write page.  If not, panic.
    // Hint:
    //   Use the read-only page table mappings at uvpt
    //   (see <inc/memlayout.h>).

    // LAB 4: Your code here.
    if ((err & FEC_WR) == 0 || (uvpd[PDX(addr)] & PTE_P) == 0 ||
        (uvpt[PGNUM(addr)] & PTE_P) == 0 || (uvpt[PGNUM(addr)] & PTE_COW) == 0)
        panic("Not a write or write to a copy-on-write page.");
    // Allocate a new page, map it at a temporary location (PFTEMP),
    // copy the data from the old page to the new page, then move the new
    // page to the old page's address.
    // Hint:
    //   You should make three system calls.

    // LAB 4: Your code here.
    if ((r = sys_page_alloc(0, (void*)PFTEMP, PTE_U | PTE_P | PTE_W)) < 0)
        panic("Page allocation failed.");

    addr = ROUNDDOWN(addr, PGSIZE);
    memmove(PFTEMP, addr, PGSIZE);
    if ((r = sys_page_map(0, PFTEMP, 0, addr, PTE_U | PTE_W | PTE_P)) < 0)
        panic("Page mapping failed.");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
    int r;
    void* addr = (void*)(pn * PGSIZE);
    pte_t pte = uvpt[PGNUM(addr)];
    if ((pte & PTE_W) != 0 || (pte & PTE_COW) != 0)
    {
        //duppage sets both PTEs so that the page is not writeable,
        //and to contain PTE_COW in the "avail" field to distinguish copy-on-write pages from genuine read-only pages.
        if ((r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P | PTE_COW)) < 0)
            panic("%e", r);
        if ((r = sys_page_map(0, addr, 0, addr, PTE_U | PTE_P | PTE_COW)) < 0)
            panic("%e", r);
    }
    else
    {
        if ((r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P)) < 0)
            panic("%e", r);
    }
    // LAB 4: Your code here.
    return 0;
}

//Implement a shared - memory fork() called sfork().
//This version should have the parent and child share all their memory pages(so writes in one environment appear in the other) except 
//for pages in the stack area, which should be treated in the usual copy - on - write manner.
//Modify user / forktree.c to use sfork() instead of regular fork().Also, once you have finished implementing 
//IPC in part C, use your sfork() to run user / pingpongs.You will have to find a new way to 
//provide the functionality of the global thisenv pointer.
static int
sduppage(envid_t envid, unsigned pn)
{
    int r;
    void* addr = (void*)(pn * PGSIZE);
    pte_t pte = uvpt[PGNUM(addr)];
    if ((pte & PTE_W) != 0 || (pte & PTE_COW) != 0)
    {
        //duppage sets both PTEs so that the page is not writeable,
        //and to contain PTE_COW in the "avail" field to distinguish copy-on-write pages from genuine read-only pages.
        if ((r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P | PTE_COW)) < 0)
            panic("%e", r);
        if ((r = sys_page_map(0, addr, 0, addr, PTE_U | PTE_P | PTE_COW)) < 0)
            panic("%e", r);
    }
    else
    {
        if ((r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P)) < 0)
            panic("%e", r);
    }
    // LAB 4: Your code here.
    return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
    // LAB 4: Your code here.
    set_pgfault_handler(pgfault);
    envid_t envid;
    int r;

    envid = sys_exofork();
    if (envid == 0)
    {
        //child envrionment
        thisenv = &envs[ENVX(sys_getenvid())];
        return 0;
    }
    //parent
    uintptr_t addr;
    //The exception stack is not remapped this way, however.
    //Instead you need to allocate a fresh page in the child for the exception stack.
    //Since the page fault handler will be doing the actual copying and the page fault handler runs on the exception stack,
    //the exception stack cannot be made copy-on-write: who would copy it?
    for (addr = UTEXT; addr < UTOP - PGSIZE; addr += PGSIZE)
    {
        if ((uvpd[PDX(addr)] & PTE_P) != 0 && (uvpt[PGNUM(addr)] & PTE_P) != 0 &&
            (uvpt[PGNUM(addr)] & PTE_U) != 0)
        {
            duppage(envid, PGNUM(addr));
        }
    }

    if ((r = sys_page_alloc(envid, (void*)(UTOP - PGSIZE), PTE_U | PTE_W | PTE_P)) < 0)
        panic("Exception stack page allocation failed. %e", r);

    extern void _pgfault_upcall(void);

    sys_env_set_pgfault_upcall(envid, _pgfault_upcall);

    if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
        panic("Failed to set child status %e", r);
    return envid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
