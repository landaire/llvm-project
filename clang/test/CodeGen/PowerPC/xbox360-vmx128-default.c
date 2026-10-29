// RUN: %clang_cc1 -triple powerpc64-unknown-xbox360 -emit-llvm -o - %s \
// RUN:   | FileCheck %s --check-prefix=DEFAULT
// RUN: %clang_cc1 -triple powerpc64-unknown-xbox360 -target-cpu pwr7 \
// RUN:   -emit-llvm -o - %s | FileCheck %s --check-prefix=VSX

// DEFAULT: "target-features"="{{[^"]*}}+altivec
// DEFAULT-SAME: +vmx128
// VSX: "target-features"="{{[^"]*}}+vsx
// VSX-SAME: -vmx128
void f(void) {}
