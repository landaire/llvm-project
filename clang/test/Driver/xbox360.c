// RUN: %clang -### -target powerpc64-unknown-xbox360 -c %s 2>&1 | FileCheck %s
// RUN: %clang -### -target powerpc64-unknown-xbox360 -fpic -c %s 2>&1 \
// RUN:   | FileCheck --check-prefix=PIC1 %s
// RUN: %clang -### -target powerpc64-unknown-xbox360 -fPIC -c %s 2>&1 \
// RUN:   | FileCheck --check-prefix=PIC2 %s

// CHECK: "-cc1"
// CHECK: "-triple" "powerpc64-unknown-xbox360"
// CHECK: "-mrelocation-model" "static"
// CHECK-NOT: "-target-abi"

// PIC1: "-mrelocation-model" "pic" "-pic-level" "1"
// PIC2: "-mrelocation-model" "pic" "-pic-level" "2"
