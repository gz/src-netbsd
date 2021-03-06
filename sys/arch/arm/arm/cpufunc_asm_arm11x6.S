/*	$NetBSD: cpufunc_asm_arm11x6.S,v 1.7.20.2 2018/01/22 12:32:38 martin Exp $	*/

/*
 * Copyright (c) 2007 Microsoft
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by Microsoft
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTERS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*-
 * Copyright (c) 2012 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Eben Upton
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


#include "assym.h"
#include <machine/asm.h>
#include <arm/locore.h>

RCSID("$NetBSD: cpufunc_asm_arm11x6.S,v 1.7.20.2 2018/01/22 12:32:38 martin Exp $")

#if 0
#define Invalidate_I_cache(Rtmp1, Rtmp2) \
	mcr	p15, 0, Rtmp1, c7, c5, 0	/* Invalidate Entire I cache */
#else
/*
 * Workaround for
 *
 *    Erratum 411920 in ARM1136 (fixed in r1p4)
 *    Erratum 415045 in ARM1176 (fixed in r0p5?)
 *
 *	- value of arg 'reg' Should Be Zero
 */
#define Invalidate_I_cache(Rtmp1, Rtmp2) \
	mov	Rtmp1, #0;		/* SBZ */			\
	mrs	Rtmp2, cpsr;						\
	cpsid	ifa;							\
	mcr	p15, 0, Rtmp1, c7, c5, 0;	/* Nuke Whole Icache */	\
	mcr	p15, 0, Rtmp1, c7, c5, 0;	/* Nuke Whole Icache */	\
	mcr	p15, 0, Rtmp1, c7, c5, 0;	/* Nuke Whole Icache */	\
	mcr	p15, 0, Rtmp1, c7, c5, 0;	/* Nuke Whole Icache */	\
	msr	cpsr_cx, Rtmp2;						\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;								\
	nop;
#endif

#if 1
#define Flush_D_cache(reg) \
	mov	reg, #0;		/* SBZ */					\
	mcr	p15, 0, reg, c7, c14, 0;/* Clean and Invalidate Entire Data Cache */	\
	mcr	p15, 0, reg, c7, c10, 4;/* Data Synchronization Barrier */
#else
#define Flush_D_cache(reg) \
1:	mov	reg, #0;		/* SBZ */					\
	mcr	p15, 0, reg, c7, c14, 0;/* Clean and Invalidate Entire Data Cache */	\
	mrc	p15, 0, reg, c7, c10, 6;/* Read Cache Dirty Status Register */		\
	ands	reg, reg, #01;		/* Check if it is clean */			\
	bne	1b;			/* loop if not */				\
	mcr	p15, 0, reg, c7, c10, 4;/* Data Synchronization Barrier */
#endif

ENTRY_NP(arm11x6_idcache_wbinv_all)
	Flush_D_cache(r0)
	Invalidate_I_cache(r0, r1)
	RET
END(arm11x6_idcache_wbinv_all)

ENTRY_NP(arm11x6_dcache_wbinv_all)
	Flush_D_cache(r0)
	RET
END(arm11x6_dcache_wbinv_all)

ENTRY_NP(arm11x6_icache_sync_all)
	Flush_D_cache(r0)
	Invalidate_I_cache(r0, r1)
	RET
END(arm11x6_icache_sync_all)

ENTRY_NP(arm11x6_flush_prefetchbuf)
	mcr	p15, 0, r0, c7, c5, 4	/* Flush Prefetch Buffer */
	RET
END(arm11x6_flush_prefetchbuf)

ENTRY_NP(arm11x6_icache_sync_range)
	ldr	r2, .Larm_pcache
	ldr	r2, [r2, #DCACHE_SIZE]
	cmp	r1, r2
	bge	arm11x6_icache_sync_all

	add	r1, r1, r0
	sub	r1, r1, #1
	/* Erratum ARM1136 371025, workaround #2 */
	/* Erratum ARM1176 371367, workaround #2 */
	mrs	r2, cpsr		/* save the CPSR */
	cpsid	ifa			/* disable interrupts (irq,fiq,abort) */
	mov	r3, #0
	mcr	p15, 0, r3, c13, c0, 0	/* write FCSE (uTLB invalidate) */
	mcr	p15, 0, r3, c7, c5, 4	/* flush prefetch buffer */
	add	r3, pc, #0x24
	mcr	p15, 0, r3, c7, c13, 1	/* prefetch I-cache line */
	mcrr	p15, 0, r1, r0, c5	/* invalidate I-cache range */
	msr	cpsr_cx, r2		/* local_irq_restore */
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	mcrr	p15, 0, r1, r0, c12	/* clean D cache range */
	mcr	p15, 0, r0, c7, c10, 4	/* drain the write buffer */
	RET
END(arm11x6_icache_sync_range)

ENTRY_NP(arm11x6_idcache_wbinv_range)
	ldr	r2, .Larm_pcache
	ldr	r2, [r2, #DCACHE_SIZE]
	cmp	r1, r2
	bge	arm11x6_idcache_wbinv_all

	add	r1, r1, r0
	sub	r1, r1, #1
	/* Erratum ARM1136 371025, workaround #2 */
	/* Erratum ARM1176 371367, workaround #2 */
	mrs	r2, cpsr		/* save the CPSR */
	cpsid	ifa			/* disable interrupts (irq,fiq,abort) */
	mov	r3, #0
	mcr	p15, 0, r3, c13, c0, 0	/* write FCSE (uTLB invalidate) */
	mcr	p15, 0, r3, c7, c5, 4	/* flush prefetch buffer */
	add	r3, pc, #0x24
	mcr	p15, 0, r3, c7, c13, 1	/* prefetch I-cache line */
	mcrr	p15, 0, r1, r0, c5	/* invalidate I-cache range */
	msr	cpsr_cx, r2		/* local_irq_restore */
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	mcrr	p15, 0, r1, r0, c14	/* clean and invalidate D cache range */
	mcr	p15, 0, r0, c7, c10, 4	/* drain the write buffer */
	RET
END(arm11x6_idcache_wbinv_range)

/*
 * Preload the cache before issuing the WFI by conditionally disabling the
 * mcr intstructions the first time around the loop. Ensure the function is
 * cacheline aligned.
 */
	.arch	armv6
	.p2align 5

ENTRY_NP(arm11x6_sleep)
	mov	r0, #0
	mov	r1, #2
1:
	subs	r1, #1
	nop
	mcreq	p15, 0, r0, c7, c10, 4		/* data sync barrier */
	mcreq	p15, 0, r0, c7, c0, 4		/* wait for interrupt */
	nop
	nop
	nop
	bne	1b
	RET
END(arm11x6_sleep)

.Larm_pcache:
	.word arm_pcache
