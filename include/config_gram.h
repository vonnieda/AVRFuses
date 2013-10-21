/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     K_READ = 258,
     K_WRITE = 259,
     K_READ_LO = 260,
     K_READ_HI = 261,
     K_WRITE_LO = 262,
     K_WRITE_HI = 263,
     K_LOADPAGE_LO = 264,
     K_LOADPAGE_HI = 265,
     K_LOAD_EXT_ADDR = 266,
     K_WRITEPAGE = 267,
     K_CHIP_ERASE = 268,
     K_PGM_ENABLE = 269,
     K_MEMORY = 270,
     K_PAGE_SIZE = 271,
     K_PAGED = 272,
     K_ARDUINO = 273,
     K_BAUDRATE = 274,
     K_BS2 = 275,
     K_BUFF = 276,
     K_BUSPIRATE = 277,
     K_CHIP_ERASE_DELAY = 278,
     K_DEDICATED = 279,
     K_DEFAULT_PARALLEL = 280,
     K_DEFAULT_PROGRAMMER = 281,
     K_DEFAULT_SERIAL = 282,
     K_DESC = 283,
     K_DEVICECODE = 284,
     K_DRAGON_DW = 285,
     K_DRAGON_HVSP = 286,
     K_DRAGON_ISP = 287,
     K_DRAGON_JTAG = 288,
     K_DRAGON_PDI = 289,
     K_DRAGON_PP = 290,
     K_STK500_DEVCODE = 291,
     K_AVR910_DEVCODE = 292,
     K_EEPROM = 293,
     K_ERRLED = 294,
     K_FLASH = 295,
     K_ID = 296,
     K_IO = 297,
     K_JTAG_MKI = 298,
     K_JTAG_MKII = 299,
     K_JTAG_MKII_AVR32 = 300,
     K_JTAG_MKII_DW = 301,
     K_JTAG_MKII_ISP = 302,
     K_JTAG_MKII_PDI = 303,
     K_LOADPAGE = 304,
     K_MAX_WRITE_DELAY = 305,
     K_MIN_WRITE_DELAY = 306,
     K_MISO = 307,
     K_MOSI = 308,
     K_NUM_PAGES = 309,
     K_NVM_BASE = 310,
     K_OFFSET = 311,
     K_PAGEL = 312,
     K_PAR = 313,
     K_PARALLEL = 314,
     K_PART = 315,
     K_PGMLED = 316,
     K_PROGRAMMER = 317,
     K_PSEUDO = 318,
     K_PWROFF_AFTER_WRITE = 319,
     K_RDYLED = 320,
     K_READBACK_P1 = 321,
     K_READBACK_P2 = 322,
     K_READMEM = 323,
     K_RESET = 324,
     K_RETRY_PULSE = 325,
     K_SERBB = 326,
     K_SERIAL = 327,
     K_SCK = 328,
     K_SIGNATURE = 329,
     K_SIZE = 330,
     K_STK500 = 331,
     K_STK500HVSP = 332,
     K_STK500PP = 333,
     K_STK500V2 = 334,
     K_STK500GENERIC = 335,
     K_STK600 = 336,
     K_STK600HVSP = 337,
     K_STK600PP = 338,
     K_AVR910 = 339,
     K_USBASP = 340,
     K_USBTINY = 341,
     K_BUTTERFLY = 342,
     K_TYPE = 343,
     K_VCC = 344,
     K_VFYLED = 345,
     K_NO = 346,
     K_YES = 347,
     K_TIMEOUT = 348,
     K_STABDELAY = 349,
     K_CMDEXEDELAY = 350,
     K_HVSPCMDEXEDELAY = 351,
     K_SYNCHLOOPS = 352,
     K_BYTEDELAY = 353,
     K_POLLVALUE = 354,
     K_POLLINDEX = 355,
     K_PREDELAY = 356,
     K_POSTDELAY = 357,
     K_POLLMETHOD = 358,
     K_MODE = 359,
     K_DELAY = 360,
     K_BLOCKSIZE = 361,
     K_READSIZE = 362,
     K_HVENTERSTABDELAY = 363,
     K_PROGMODEDELAY = 364,
     K_LATCHCYCLES = 365,
     K_TOGGLEVTG = 366,
     K_POWEROFFDELAY = 367,
     K_RESETDELAYMS = 368,
     K_RESETDELAYUS = 369,
     K_HVLEAVESTABDELAY = 370,
     K_RESETDELAY = 371,
     K_SYNCHCYCLES = 372,
     K_HVCMDEXEDELAY = 373,
     K_CHIPERASEPULSEWIDTH = 374,
     K_CHIPERASEPOLLTIMEOUT = 375,
     K_CHIPERASETIME = 376,
     K_PROGRAMFUSEPULSEWIDTH = 377,
     K_PROGRAMFUSEPOLLTIMEOUT = 378,
     K_PROGRAMLOCKPULSEWIDTH = 379,
     K_PROGRAMLOCKPOLLTIMEOUT = 380,
     K_PP_CONTROLSTACK = 381,
     K_HVSP_CONTROLSTACK = 382,
     K_ALLOWFULLPAGEBITSTREAM = 383,
     K_ENABLEPAGEPROGRAMMING = 384,
     K_HAS_JTAG = 385,
     K_HAS_DW = 386,
     K_HAS_PDI = 387,
     K_HAS_TPI = 388,
     K_IDR = 389,
     K_IS_AVR32 = 390,
     K_RAMPZ = 391,
     K_SPMCR = 392,
     K_EECR = 393,
     K_FLASH_INSTR = 394,
     K_EEPROM_INSTR = 395,
     TKN_COMMA = 396,
     TKN_EQUAL = 397,
     TKN_SEMI = 398,
     TKN_TILDE = 399,
     TKN_NUMBER = 400,
     TKN_STRING = 401,
     TKN_ID = 402
   };
#endif
/* Tokens.  */
#define K_READ 258
#define K_WRITE 259
#define K_READ_LO 260
#define K_READ_HI 261
#define K_WRITE_LO 262
#define K_WRITE_HI 263
#define K_LOADPAGE_LO 264
#define K_LOADPAGE_HI 265
#define K_LOAD_EXT_ADDR 266
#define K_WRITEPAGE 267
#define K_CHIP_ERASE 268
#define K_PGM_ENABLE 269
#define K_MEMORY 270
#define K_PAGE_SIZE 271
#define K_PAGED 272
#define K_ARDUINO 273
#define K_BAUDRATE 274
#define K_BS2 275
#define K_BUFF 276
#define K_BUSPIRATE 277
#define K_CHIP_ERASE_DELAY 278
#define K_DEDICATED 279
#define K_DEFAULT_PARALLEL 280
#define K_DEFAULT_PROGRAMMER 281
#define K_DEFAULT_SERIAL 282
#define K_DESC 283
#define K_DEVICECODE 284
#define K_DRAGON_DW 285
#define K_DRAGON_HVSP 286
#define K_DRAGON_ISP 287
#define K_DRAGON_JTAG 288
#define K_DRAGON_PDI 289
#define K_DRAGON_PP 290
#define K_STK500_DEVCODE 291
#define K_AVR910_DEVCODE 292
#define K_EEPROM 293
#define K_ERRLED 294
#define K_FLASH 295
#define K_ID 296
#define K_IO 297
#define K_JTAG_MKI 298
#define K_JTAG_MKII 299
#define K_JTAG_MKII_AVR32 300
#define K_JTAG_MKII_DW 301
#define K_JTAG_MKII_ISP 302
#define K_JTAG_MKII_PDI 303
#define K_LOADPAGE 304
#define K_MAX_WRITE_DELAY 305
#define K_MIN_WRITE_DELAY 306
#define K_MISO 307
#define K_MOSI 308
#define K_NUM_PAGES 309
#define K_NVM_BASE 310
#define K_OFFSET 311
#define K_PAGEL 312
#define K_PAR 313
#define K_PARALLEL 314
#define K_PART 315
#define K_PGMLED 316
#define K_PROGRAMMER 317
#define K_PSEUDO 318
#define K_PWROFF_AFTER_WRITE 319
#define K_RDYLED 320
#define K_READBACK_P1 321
#define K_READBACK_P2 322
#define K_READMEM 323
#define K_RESET 324
#define K_RETRY_PULSE 325
#define K_SERBB 326
#define K_SERIAL 327
#define K_SCK 328
#define K_SIGNATURE 329
#define K_SIZE 330
#define K_STK500 331
#define K_STK500HVSP 332
#define K_STK500PP 333
#define K_STK500V2 334
#define K_STK500GENERIC 335
#define K_STK600 336
#define K_STK600HVSP 337
#define K_STK600PP 338
#define K_AVR910 339
#define K_USBASP 340
#define K_USBTINY 341
#define K_BUTTERFLY 342
#define K_TYPE 343
#define K_VCC 344
#define K_VFYLED 345
#define K_NO 346
#define K_YES 347
#define K_TIMEOUT 348
#define K_STABDELAY 349
#define K_CMDEXEDELAY 350
#define K_HVSPCMDEXEDELAY 351
#define K_SYNCHLOOPS 352
#define K_BYTEDELAY 353
#define K_POLLVALUE 354
#define K_POLLINDEX 355
#define K_PREDELAY 356
#define K_POSTDELAY 357
#define K_POLLMETHOD 358
#define K_MODE 359
#define K_DELAY 360
#define K_BLOCKSIZE 361
#define K_READSIZE 362
#define K_HVENTERSTABDELAY 363
#define K_PROGMODEDELAY 364
#define K_LATCHCYCLES 365
#define K_TOGGLEVTG 366
#define K_POWEROFFDELAY 367
#define K_RESETDELAYMS 368
#define K_RESETDELAYUS 369
#define K_HVLEAVESTABDELAY 370
#define K_RESETDELAY 371
#define K_SYNCHCYCLES 372
#define K_HVCMDEXEDELAY 373
#define K_CHIPERASEPULSEWIDTH 374
#define K_CHIPERASEPOLLTIMEOUT 375
#define K_CHIPERASETIME 376
#define K_PROGRAMFUSEPULSEWIDTH 377
#define K_PROGRAMFUSEPOLLTIMEOUT 378
#define K_PROGRAMLOCKPULSEWIDTH 379
#define K_PROGRAMLOCKPOLLTIMEOUT 380
#define K_PP_CONTROLSTACK 381
#define K_HVSP_CONTROLSTACK 382
#define K_ALLOWFULLPAGEBITSTREAM 383
#define K_ENABLEPAGEPROGRAMMING 384
#define K_HAS_JTAG 385
#define K_HAS_DW 386
#define K_HAS_PDI 387
#define K_HAS_TPI 388
#define K_IDR 389
#define K_IS_AVR32 390
#define K_RAMPZ 391
#define K_SPMCR 392
#define K_EECR 393
#define K_FLASH_INSTR 394
#define K_EEPROM_INSTR 395
#define TKN_COMMA 396
#define TKN_EQUAL 397
#define TKN_SEMI 398
#define TKN_TILDE 399
#define TKN_NUMBER 400
#define TKN_STRING 401
#define TKN_ID 402




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

