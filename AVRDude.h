/*
 *  AVRDude.h
 *  AVRFuses
 *
 *  Created by Jason von Nieda on 1/22/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include <CoreFoundation/CoreFoundation.h>


/*
 * Functions are listed in the general order they should be called.
 */
int avrdude_init();
CFStringRef avrdude_get_version();
CFArrayRef avrdude_list_programmers();
CFArrayRef avrdude_list_parts();
int avrdude_open(CFStringRef programmer, CFStringRef port, int baud, double bit_clock);
int avrdude_enable_programming(CFStringRef part);
int avrdude_disable_programming();
int avrdude_close();
