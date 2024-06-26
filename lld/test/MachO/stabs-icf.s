# REQUIRES: x86
# RUN: llvm-mc -filetype=obj -triple=x86_64-apple-darwin %s -o %t.o

# RUN: %lld -lSystem --icf=all %t.o -o %t
# RUN: dsymutil -s %t | FileCheck %s -DDIR=%t -DSRC_PATH=%t.o

# RUN: %lld -lSystem --icf=all %t.o -o %t_icf_stabs --keep-icf-stabs
# RUN: dsymutil -s %t_icf_stabs | FileCheck %s -DDIR=%t_icf_stabs -DSRC_PATH=%t.o --check-prefixes=ICF_STABS

## This should include no N_FUN entry for _baz (which is ICF'd into _bar),
## but it does include a SECT EXT entry.
## NOTE: We do not omit the N_FUN entry for _bar even though it is of size zero.
##       Only folded symbols get omitted.
## NOTE: Unlike ld64, we also omit the N_FUN entry for _baz2.
# CHECK:      (N_SO         ) 00      0000   0000000000000000  '/tmp{{[/\\]}}test.cpp'
# CHECK-NEXT: (N_OSO        ) 03      0001   {{.*}} '[[SRC_PATH]]'
# CHECK-NEXT: (N_FUN        ) 01      0000   [[#%.16x,MAIN:]]  '_main'
# CHECK-NEXT: (N_FUN        ) 00      0000   000000000000000b{{$}}
# CHECK-NEXT: (N_FUN        ) 01      0000   [[#%.16x,BAR:]]   '_bar'
# CHECK-NEXT: (N_FUN        ) 00      0000   0000000000000000{{$}}
# CHECK-NEXT: (N_FUN        ) 01      0000   [[#BAR]]          '_bar2'
# CHECK-NEXT: (N_FUN        ) 00      0000   0000000000000001{{$}}
# CHECK-NEXT: (N_SO         ) 01      0000   0000000000000000{{$}}
# CHECK-DAG:  (     SECT EXT) 01      0000   [[#MAIN]]         '_main'
# CHECK-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_bar'
# CHECK-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_bar2'
# CHECK-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_baz'
# CHECK-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_baz2'
# CHECK-DAG:  (       {{.*}}) {{[0-9]+}}                 0010   {{[0-9a-f]+}}      '__mh_execute_header'
# CHECK-DAG:  (       {{.*}}) {{[0-9]+}}                 0100   0000000000000000   'dyld_stub_binder'
# CHECK-EMPTY:


# ICF_STABS:      (N_SO         ) 00      0000   0000000000000000  '/tmp{{[/\\]}}test.cpp'
# ICF_STABS-NEXT: (N_OSO        ) 03      0001   {{.*}} '[[SRC_PATH]]'
# ICF_STABS-NEXT: (N_FUN        ) 01      0000   [[#%.16x,MAIN:]]  '_main'
# ICF_STABS-NEXT: (N_FUN        ) 00      0000   000000000000000b{{$}}
# ICF_STABS-NEXT: (N_FUN        ) 01      0000   [[#%.16x,BAR:]]   '_bar'
# ICF_STABS-NEXT: (N_FUN        ) 00      0000   0000000000000000{{$}}
# ICF_STABS-NEXT: (N_FUN        ) 01      0000   [[#BAR]]          '_bar2'
# ICF_STABS-NEXT: (N_FUN        ) 00      0000   0000000000000001{{$}}
# ICF_STABS-NEXT: (N_FUN        ) 01      0000   [[#BAR]]          '_baz'
# ICF_STABS-NEXT: (N_FUN        ) 00      0000   0000000000000000{{$}}
# ICF_STABS-NEXT: (N_FUN        ) 01      0000   [[#BAR]]          '_baz2'
# ICF_STABS-NEXT: (N_FUN        ) 00      0000   0000000000000001{{$}}
# ICF_STABS-NEXT: (N_SO         ) 01      0000   0000000000000000{{$}}
# ICF_STABS-DAG:  (     SECT EXT) 01      0000   [[#MAIN]]         '_main'
# ICF_STABS-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_bar'
# ICF_STABS-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_bar2'
# ICF_STABS-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_baz'
# ICF_STABS-DAG:  (     SECT EXT) 01      0000   [[#BAR]]          '_baz2'
# ICF_STABS-DAG:  (       {{.*}}) {{[0-9]+}}                 0010   {{[0-9a-f]+}}      '__mh_execute_header'
# ICF_STABS-DAG:  (       {{.*}}) {{[0-9]+}}                 0100   0000000000000000   'dyld_stub_binder'
# ICF_STABS-EMPTY:


.text
.globl _bar, _bar2, _baz, _baz2, _main

.subsections_via_symbols

_bar:
_bar2:
  ret

_baz:
_baz2:
  ret

_main:
Lfunc_begin0:
  call _bar
  call _baz
  ret
Lfunc_end0:

.section  __DWARF,__debug_str,regular,debug
  .asciz  "test.cpp"             ## string offset=0
  .asciz  "/tmp"                 ## string offset=9
.section  __DWARF,__debug_abbrev,regular,debug
Lsection_abbrev:
  .byte  1                       ## Abbreviation Code
  .byte  17                      ## DW_TAG_compile_unit
  .byte  1                       ## DW_CHILDREN_yes
  .byte  3                       ## DW_AT_name
  .byte  14                      ## DW_FORM_strp
  .byte  27                      ## DW_AT_comp_dir
  .byte  14                      ## DW_FORM_strp
  .byte  17                      ## DW_AT_low_pc
  .byte  1                       ## DW_FORM_addr
  .byte  18                      ## DW_AT_high_pc
  .byte  6                       ## DW_FORM_data4
  .byte  0                       ## EOM(1)
  .byte  0                       ## EOM(2)
  .byte  0                       ## EOM(3)
.section  __DWARF,__debug_info,regular,debug
.set Lset0, Ldebug_info_end0-Ldebug_info_start0 ## Length of Unit
  .long  Lset0
Ldebug_info_start0:
  .short  4                       ## DWARF version number
.set Lset1, Lsection_abbrev-Lsection_abbrev ## Offset Into Abbrev. Section
  .long  Lset1
  .byte  8                       ## Address Size (in bytes)
  .byte  1                       ## Abbrev [1] 0xb:0x48 DW_TAG_compile_unit
  .long  0                       ## DW_AT_name
  .long  9                       ## DW_AT_comp_dir
  .quad  Lfunc_begin0            ## DW_AT_low_pc
.set Lset3, Lfunc_end0-Lfunc_begin0     ## DW_AT_high_pc
  .long  Lset3
  .byte  0                       ## End Of Children Mark
Ldebug_info_end0:
