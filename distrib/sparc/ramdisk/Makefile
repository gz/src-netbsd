#	$NetBSD: Makefile,v 1.43 2017/02/09 18:15:07 joerg Exp $
#
# ramdisk.fs is the microroot filesystem intended for use with
# the INSTALL kernel. It provides just enough tools to extract the
# miniroot-based `instfs' filesystem into an MFS mount point
# and start the installation scripts from there (see dot.profile).
#

.include <bsd.own.mk>
.include "${NETBSDSRCDIR}/distrib/common/Makefile.distrib"

IMAGE=		ramdisk.fs
IMAGESIZE=	2000b

WARNS=		1
DBG=		${${ACTIVE_CC} == "clang":? -Oz -fomit-frame-pointer -fno-unwind-tables : -Os }

CRUNCHBIN=	ramdiskbin
LISTS=		${.CURDIR}/list
MTREECONF=	${DISTRIBDIR}/common/mtree.common
IMAGEENDIAN=	be
MAKEDEVTARGETS=	floppy
IMAGEDEPENDS+=	${CRUNCHBIN} dot.profile

# Use stubs to eliminate some large stuff from libc
HACKSRC=	${DISTRIBDIR}/utils/libhack
HACKOBJS=	gethost.o
.include	"${HACKSRC}/Makefile.inc"
${CRUNCHBIN}:	libhack.o

.include "${DISTRIBDIR}/common/Makefile.crunch"
.include "${DISTRIBDIR}/common/Makefile.makedev"
.include "${DISTRIBDIR}/common/Makefile.image"

release:

.include <bsd.prog.mk>
