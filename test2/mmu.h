
/*
 * Macros to build GDT entries in assembly.
 */
#define SEG_NULL						\
	.word 0, 0;						\
	.byte 0, 0, 0, 0
#define SEG(type,base,lim)					\
	.word (((lim) >> 12) & 0xffff), ((base) & 0xffff);	\
	.byte (((base) >> 16) & 0xff),  (type), 		\
		(0xC0 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)

/* G =1 D/B =1 ; P= 1, DPL = 00, S=1*/



// Application segment type bits
#define STA_X		0x98	    // Executable segment
#define STA_E		0x94	    // Expand down (non-executable segments)
#define STA_C		0x94	    // Conforming code segment (executable only)
#define STA_W		0x92	    // Writeable (non-executable segments)
#define STA_R		0x92	    // Readable (executable segments)
#define STA_A		0x91	    // Accessed

//System segment type bits
#define STS_T16A	0x81	    // Available 16-bit TSS
#define STS_LDT		0x82	    // Local Descriptor Table
#define STS_T16B	0x83	    // Busy 16-bit TSS
#define STS_CG16	0x84	    // 16-bit Call Gate
#define STS_TG		0x85	    // Task Gate / Coum Transmitions
#define STS_IG16	0x86	    // 16-bit Interrupt Gate
#define STS_TG16	0x87	    // 16-bit Trap Gate
#define STS_T32A	0x89	    // Available 32-bit TSS
#define STS_T32B	0x8B	    // Busy 32-bit TSS
#define STS_CG32	0x8C	    // 32-bit Call Gate
#define STS_IG32	0x8E	    // 32-bit Interrupt Gate
#define STS_TG32	0x8F	    // 32-bit Trap Gate
