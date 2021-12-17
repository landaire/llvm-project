//===-- asan_malloc_linux.cpp ---------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of AddressSanitizer, an address sanity checker.
//
// Linux-specific malloc interception.
// We simply define functions like malloc, free, realloc, etc.
// They will replace the corresponding libc functions automagically.
//===----------------------------------------------------------------------===//

#include "sanitizer_common/sanitizer_platform.h"
#if SANITIZER_FREEBSD || SANITIZER_FUCHSIA || SANITIZER_LINUX || \
    SANITIZER_NETBSD || SANITIZER_SOLARIS

#  include "asan_allocator.h"
#  include "asan_interceptors.h"
#  include "asan_internal.h"
#  include "asan_stack.h"
#  include "sanitizer_common/sanitizer_allocator_checks.h"
#  include "sanitizer_common/sanitizer_errno.h"
#  include "sanitizer_common/sanitizer_tls_get_addr.h"
#include <cstdio>

// ---------------------- Replacement functions ---------------- {{{1
using namespace __asan;


namespace __asan {
void ReplaceSystemShmemFuncs() {
  // void **__libc_shmget_p =
  //     (void **)AsanDlSymNext("__libc_malloc_dispatch");
  // void **__libc_shmat_p =
  //     (void **)AsanDlSymNext("__libc_malloc_dispatch");
  // void **__libc_shmdt_p =
  //     (void **)AsanDlSymNext("__libc_malloc_dispatch");
  // if (__libc_malloc_dispatch_p) {
  //   // Decide on K vs L dispatch format by the presence of
  //   // __libc_malloc_default_dispatch export in libc.
  //   void *default_dispatch_p = AsanDlSymNext("__libc_malloc_default_dispatch");
  //   if (default_dispatch_p)
  //     *__libc_malloc_dispatch_p = (void *)&asan_malloc_dispatch_k;
  //   else
  //     *__libc_malloc_dispatch_p = (void *)&asan_malloc_dispatch_l;
  // }
}
}  // namespace __asan

#else  // SANITIZER_ANDROID

namespace __asan {
void ReplaceSystemShmemFuncs() {
}
}  // namespace __asan
#endif  // SANITIZER_ANDROID

#endif  // SANITIZER_FREEBSD || SANITIZER_FUCHSIA || SANITIZER_LINUX ||
        // SANITIZER_NETBSD || SANITIZER_SOLARIS
