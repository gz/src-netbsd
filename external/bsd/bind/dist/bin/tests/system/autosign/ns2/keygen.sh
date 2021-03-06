#!/bin/sh -e
#
# Copyright (C) 2009-2012, 2014, 2016  Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

SYSTEMTESTTOP=../..
. $SYSTEMTESTTOP/conf.sh

# Have the child generate subdomain keys and pass DS sets to us.
( cd ../ns3 && $SHELL keygen.sh )

for subdomain in secure nsec3 autonsec3 optout rsasha256 rsasha512 nsec3-to-nsec oldsigs
do
	cp ../ns3/dsset-$subdomain.example$TP .
done

# Create keys and pass the DS to the parent.
zone=example
zonefile="${zone}.db"
infile="${zonefile}.in"
cat $infile dsset-*.example$TP > $zonefile

kskname=`$KEYGEN -3 -q -r $RANDFILE -fk $zone`
$KEYGEN -3 -q -r $RANDFILE $zone > /dev/null
$DSFROMKEY $kskname.key > dsset-${zone}$TP

# Create keys for a private secure zone.
zone=private.secure.example
zonefile="${zone}.db"
infile="${zonefile}.in"
cp $infile $zonefile
$KEYGEN -3 -q -r $RANDFILE -fk $zone > /dev/null
$KEYGEN -3 -q -r $RANDFILE $zone > /dev/null

# Extract saved keys for the revoke-to-duplicate-key test
zone=bar
zonefile="${zone}.db"
infile="${zonefile}.in"
cat $infile > $zonefile
for i in Xbar.+005+30676.key Xbar.+005+30804.key Xbar.+005+30676.private \
	 Xbar.+005+30804.private
do
	cp $i `echo $i | sed s/X/K/`
done
$KEYGEN -q -r $RANDFILE $zone > /dev/null
$DSFROMKEY Kbar.+005+30804.key > dsset-bar$TP
