; RUN: llc -mtriple=powerpc-unknown-none -mattr=+xbox360 \
; RUN:   -verify-machineinstrs < %s | FileCheck %s --check-prefix=BE
; RUN: llc -mtriple=powerpc-unknown-none -mattr=+xbox360 -frame-pointer=all \
; RUN:   -verify-machineinstrs < %s | FileCheck %s --check-prefix=FP
; RUN: llc -mtriple=powerpc-unknown-none -mattr=+xbox360 -stackrealign \
; RUN:   -verify-machineinstrs < %s | FileCheck %s --check-prefix=BP
; RUN: llc -mtriple=powerpc-unknown-none -mattr=+xbox360 -relocation-model=pic \
; RUN:   -verify-machineinstrs < %s | FileCheck %s --check-prefix=PIC
; RUN: llc -mtriple=powerpc-unknown-none -mattr=+xbox360 \
; RUN:   -filetype=obj < %s | llvm-readobj --file-headers - | FileCheck %s --check-prefix=ELF

; The Xbox 360 uses an ILP32 ABI on a 64-bit PowerPC processor. Pointers and
; ELF container fields are 32-bit, while i64 values use 64-bit GPRs.

target datalayout = "E-m:e-p:32:32-Fn32-i64:64-n32"
target triple = "powerpc-unknown-none"

; BE-LABEL: add_i64:
; BE:       add 3, 3, 4
; BE-NOT:   addc
; BE-NOT:   adde

define i64 @add_i64(i64 %a, i64 %b) {
  %sum = add i64 %a, %b
  ret i64 %sum
}

; BE-LABEL: load_i64:
; BE:       ld 3, 0(3)

define i64 @load_i64(ptr %address) {
  %value = load i64, ptr %address, align 8
  ret i64 %value
}

; Pointer stack objects remain 4 bytes.
; BE-LABEL: spill_pointer:
; BE:       stw 3,
; BE:       lwz 3,

define ptr @spill_pointer(ptr %pointer) {
  %slot = alloca ptr, align 4
  store volatile ptr %pointer, ptr %slot, align 4
  %result = load volatile ptr, ptr %slot, align 4
  ret ptr %result
}

; BE-LABEL: call_loaded_i64:
; BE:       stwu 1, -80(1)
; BE:       ld 3, 0(3)
; BE:       bl callee

declare i64 @callee(i64)

define i64 @call_loaded_i64(ptr %address) {
  %value = load i64, ptr %address, align 8
  %result = call i64 @callee(i64 %value)
  ret i64 %result
}

; The i64 uses one 64-bit argument register after the preceding i32.
; BE-LABEL: aligned_i64:
; BE:       mr 3, 4

define i64 @aligned_i64(i32 %prefix, i64 %value) {
  ret i64 %value
}

; The ninth integer argument is passed on the stack.
; BE-LABEL: stacked_i64:
; BE:       ld 3, 80(1)

define i64 @stacked_i64(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i64 %value) {
  ret i64 %value
}

; Nonvolatile GPRs preserve all 64 bits.
; BE-LABEL: clobber_r31:
; BE:       .cfi_offset r31, -8
; BE:       std 31,
; BE:       ld 31,

define void @clobber_r31() {
  call void asm sideeffect "", "~{r31}"()
  ret void
}

; BE-LABEL: clobber_r14:
; BE:       .cfi_offset r14, -144
; BE:       std 14, 16(1)
; BE:       ld 14, 16(1)

define void @clobber_r14() {
  call void asm sideeffect "", "~{r14}"()
  ret void
}

; The CR save uses the fixed -4 slot relative to the incoming stack pointer.
; BE-LABEL: clobber_cr2:
; BE:       .cfi_offset cr2, -4
; BE:       stw {{[0-9]+}}, 44(1)
; BE:       lwz {{[0-9]+}}, 44(1)

define void @clobber_cr2() {
  call void asm sideeffect "", "~{cr2}"()
  ret void
}

; Dedicated frame-pointer saves also preserve all 64 bits.
; FP-LABEL: frame_pointer:
; FP:       std 31, -8(1)
; FP:       .cfi_offset r31, -8
; FP:       ld 31, -8(1)

define i64 @frame_pointer(i64 %value) {
  %slot = alloca i64, align 8
  store volatile i64 %value, ptr %slot, align 8
  %result = load volatile i64, ptr %slot, align 8
  ret i64 %result
}

declare void @use(ptr)

; Realigned frames preserve the full frame and base pointer registers.
; BP-LABEL: base_pointer:
; BP:       std 31, -8(1)
; BP:       std 30, -16(1)
; BP:       .cfi_offset r31, -8
; BP:       .cfi_offset r30, -16
; BP:       ld 31, -8(1)
; BP:       ld 30, -16(1)

define i64 @base_pointer(i64 %value, i32 %count) {
  %slot = alloca i64, i32 %count, align 32
  store volatile i64 %value, ptr %slot, align 32
  call void @use(ptr %slot)
  %result = load volatile i64, ptr %slot, align 32
  ret i64 %result
}

@global = external global i64

; PIC functions preserve the full PIC base register.
; PIC-LABEL: pic_base:
; PIC:       std 30, -16(1)
; PIC:       .cfi_offset r30, -16
; PIC:       ld 30, -16(1)

define i64 @pic_base() {
  %result = load volatile i64, ptr @global, align 8
  ret i64 %result
}

; A 32-bit atomic value uses the 32-bit control-fence pseudo even though the
; processor supports 64-bit instructions.
; BE-LABEL: load_i32_acquire:
; BE:       lwz 3, 0(3)
; BE-NEXT:  cmpw 7, 3, 3
; BE-NEXT:  bne- 7, .+4
; BE-NEXT:  isync

define i32 @load_i32_acquire(ptr %address) {
  %value = load atomic i32, ptr %address acquire, align 4
  ret i32 %value
}

; ELF: Format: elf32-powerpc
; ELF: Arch: powerpc
; ELF: AddressSize: 32bit
; ELF: Class: 32-bit
; ELF: DataEncoding: BigEndian
; ELF: Machine: EM_PPC
