/*	$NetBSD: cpu.h,v 1.60.40.1 2018/03/17 11:23:18 martin Exp $	*/

/*-
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * William Jolitz.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)cpu.h	5.4 (Berkeley) 5/9/91
 */

#ifndef _AMD64_CPU_H_
#define _AMD64_CPU_H_

#ifdef __x86_64__

#include <x86/cpu.h>

#ifdef _KERNEL

#if defined(__GNUC__) && !defined(_MODULE)
static struct cpu_info *x86_curcpu(void);
static lwp_t *x86_curlwp(void);

__inline static struct cpu_info * __unused
x86_curcpu(void)
{
	struct cpu_info *ci;

	__asm volatile("movq %%gs:%1, %0" :
	    "=r" (ci) :
	    "m"
	    (*(struct cpu_info * const *)offsetof(struct cpu_info, ci_self)));
	return ci;
}

__inline static lwp_t * __unused __attribute__ ((const))
x86_curlwp(void)
{
	lwp_t *l;

	__asm volatile("movq %%gs:%1, %0" :
	    "=r" (l) :
	    "m"
	    (*(struct cpu_info * const *)offsetof(struct cpu_info, ci_curlwp)));
	return l;
}

__inline static void __unused
cpu_set_curpri(int pri)
{

	__asm volatile(
	    "movl %1, %%gs:%0" :
	    "=m" (*(struct cpu_info *)offsetof(struct cpu_info, ci_schedstate.spc_curpriority)) :
	    "r" (pri)
	);
}
#endif	/* __GNUC__ && !_MODULE */

#define	CLKF_USERMODE(frame)	USERMODE((frame)->cf_if.if_tf.tf_cs, \
				    (frame)->cf_if.if_tf.tf_rflags)
#define CLKF_PC(frame)		((frame)->cf_if.if_tf.tf_rip)
#define CLKF_INTR(frame)	(curcpu()->ci_idepth > 0)
#define LWP_PC(l)		((l)->l_md.md_regs->tf_rip)

#endif	/* _KERNEL */

#else	/*	__x86_64__	*/

#include <i386/cpu.h>

#endif	/*	__x86_64__	*/

#endif /* !_AMD64_CPU_H_ */
