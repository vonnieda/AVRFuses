/*
 *  AVRDude.c
 *  AVRFuses
 *
 *  Created by Jason von Nieda on 1/22/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "AVRDude.h"

#include "ac_cfg.h"

#include <string.h>

#include "avr.h"
#include "config.h"
#include "confwin.h"
#include "fileio.h"
#include "lists.h"
#include "par.h"
#include "pindefs.h"
#include "term.h"
#include "safemode.h"
#include "update.h"

char * progname;
char   progbuf[PATH_MAX]; /* temporary buffer of spaces the same
						   length as progname; used for lining up
						   multiline messages */

static PROGRAMMER *pgm;
static struct avrpart *p;

/*
 * global options
 */
int    do_cycles;   /* track erase-rewrite cycles */
int    verbose;     /* verbose output */
int    quell_progress; /* un-verebose output */
int    ovsigck;     /* 1=override sig check, 0=don't */

static CFStringRef version;

CFStringRef avrdude_get_version() {
	return version;
}

int avrdude_init() {
	int rc;
	
	progname = "AVRFuses";
	strcpy(progbuf, "        ");
	
	init_config();
	
	rc = read_config("/Users/jason/src/avrdude-5.9/avrdude.conf");
	if (rc) {
		return 1;
	}
	
	version = CFStringCreateWithCString(NULL, VERSION, kCFStringEncodingUTF8);	
	
	return 0;
}

CFArrayRef avrdude_list_programmers() {
	CFMutableArrayRef a = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	for (LNODEID ln1 = lfirst(programmers); ln1; ln1 = lnext(ln1)) {
		PROGRAMMER *p = ldata(ln1);
		CFStringRef s = CFStringCreateWithCString(NULL, (char *)ldata(lfirst(p->id)), kCFStringEncodingUTF8);
		CFArrayAppendValue(a, s);
		CFRelease(s);
	}
	return a;
}

CFArrayRef avrdude_list_parts() {
	CFMutableArrayRef a = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	for (LNODEID ln1 = lfirst(part_list); ln1; ln1 = lnext(ln1)) {
		AVRPART *p = ldata(ln1);
		CFStringRef s = CFStringCreateWithCString(NULL, p->id, kCFStringEncodingUTF8);
		CFArrayAppendValue(a, s);
	   CFRelease(s);
	}
	return a;
}

int avrdude_open(CFStringRef programmer, CFStringRef port, int baud, double bit_clock) {
	char programmer_c[1024];
	char port_c[1024];
	
	int rc;
	
	CFStringGetCString(programmer, programmer_c, sizeof(programmer_c), kCFStringEncodingUTF8);
	CFStringGetCString(port, port_c, sizeof(port_c), kCFStringEncodingUTF8);
	
	pgm = locate_programmer(programmers, programmer_c);
	if (pgm == NULL) {
		return 1;
	}
	
	if (pgm->setup) {
		pgm->setup(pgm);
	}
	
	if (bit_clock != 0.0) {
		pgm->bitclock = bit_clock * 1e-6;
	}
	
	rc = pgm->open(pgm, port_c);
	if (rc < 0) {
		return 1;
	}
	
	/*
	 * enable the programmer
	 */
	pgm->enable(pgm);
	
	/*
	 * turn off all the status leds
	 */
	pgm->rdy_led(pgm, OFF);
	pgm->err_led(pgm, OFF);
	pgm->pgm_led(pgm, OFF);
	pgm->vfy_led(pgm, OFF);
	
	return 0;
}

int avrdude_enable_programming(CFStringRef part) {
	char part_c[1024];
	
	int rc;
	
	if (p) {
		free(p);
		p = NULL;
	}
	
	CFStringGetCString(part, part_c, sizeof(part_c), kCFStringEncodingUTF8);
	
	p = locate_part(part_list, "atmega168");
	if (p == NULL) {
		return 1;
	}
	
	p = avr_dup_part(p);
	
	rc = pgm->initialize(pgm, p);
	if (rc >= 0) {
		return 1;
	}
	
	/* indicate ready */
	pgm->rdy_led(pgm, ON);
	
	return 0;
}

int avrdude_disable_programming() {
	pgm->disable(pgm);
	return 0;
}

int avrdude_close() {
	pgm->powerdown(pgm);
	
	pgm->disable(pgm);
	
	pgm->rdy_led(pgm, OFF);
	
	pgm->close(pgm);
	
	return 0;
}

