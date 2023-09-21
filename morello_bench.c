#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#ifdef BYTE_ORDER
#if BYTE_ORDER == BIG_ENDIAN
#define LE_TO_CPU32(val)                                      \
  (((val & 0x000000FFU) << 24) | ((val & 0x0000FF00U) << 8) | \
   ((val & 0x00FF0000U) >> 8) | ((val & 0xFF000000U) >> 24))
#else
#define LE_TO_CPU32(val) (val)
#endif
#else
#error "BYTE_ORDER is not defined"
#endif

struct timespec ts_diff(struct timespec start, struct timespec end) {
  struct timespec temp;
  if ((end.tv_nsec - start.tv_nsec) < 0) {
    temp.tv_sec = end.tv_sec - start.tv_sec - 1;
    temp.tv_nsec = 1000000000 + end.tv_nsec - start.tv_nsec;
  } else {
    temp.tv_sec = end.tv_sec - start.tv_sec;
    temp.tv_nsec = end.tv_nsec - start.tv_nsec;
  }
  return temp;
}

__attribute__((noinline)) void kernel(uint8_t *restrict aa,
                                      uint8_t *restrict ab,
                                      uint8_t *restrict ac) {
  for (int ad = 0; ad < 256; ad++) {
    for (int ae = 0; ae < 128; ae++) {
      for (int af = 0; af < 256; af++) {
        for (int ag = 0; ag < 2; ag++) {
          for (int ah = 0; ah < 2; ah++) {
            for (int ai = 0; ai < 8; ai++) {
              uint8_t aj[8] __attribute__((aligned(128)));
              for (int ak = 0; ak < 8; ak++) {
                aj[(ak)] =
                    aa[(2048 * ak + 16384 * ag + 32768 * ae + ai + 8 * ad)];
              }
              uint8_t al[4] __attribute__((aligned(128)));
              for (int am = 0; am < 4; am++) {
                al[(am)] = ab[(2048 * ai + 16384 * ad + am + 4 * ah + 8 * af)];
              }
              for (int an = 0; an < 8; an++) {
                for (int ao = 0; ao < 4; ao++) {
                  uint8_t ap;
                  ap = ac[(2048 * an + 16384 * ag + 32768 * ae + ao + 4 * ah +
                           8 * af)];
                  ap += aj[(an)] * al[(ao)]; /* Mult */
                  ac[(2048 * an + 16384 * ag + 32768 * ae + ao + 4 * ah +
                      8 * af)] = ap;
                }
              }
            }
          }
        }
      }
    }
  }
}

int load_inputs(char *paths[], void *restrict dest0, void *restrict dest1) {
  int fd;
  void *mapped;

  if ((fd = open(paths[0], O_RDONLY)) == -1) return 1;
  if ((mapped = mmap(NULL, 4194304, PROT_READ, MAP_SHARED, fd, 0)) ==
      MAP_FAILED)
    return 2;
  close(fd);
  for (int i = 0; i < 4194304; i++)
    ((uint8_t *)dest0)[i] = (((uint8_t *)mapped)[i]);
  if (munmap(mapped, 4194304) != 0) return 3;

  if ((fd = open(paths[1], O_RDONLY)) == -1) return 1;
  if ((mapped = mmap(NULL, 4194304, PROT_READ, MAP_SHARED, fd, 0)) ==
      MAP_FAILED)
    return 2;
  close(fd);
  for (int i = 0; i < 4194304; i++)
    ((uint8_t *)dest1)[i] = (((uint8_t *)mapped)[i]);
  if (munmap(mapped, 4194304) != 0) return 3;
  return 0;
}

int main(int argc, char *argv[]) {
  uint8_t *restrict aq;
  posix_memalign((void **)&aq, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    aq[idx] = (uint8_t)rand();
  }

  uint8_t *restrict ar;
  posix_memalign((void **)&ar, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    ar[idx] = (uint8_t)rand();
  }

  uint8_t *restrict as;
  posix_memalign((void **)&as, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    as[idx] = (uint8_t)rand();
  }

  if (argc == 3) {
    int load_result = load_inputs(&argv[1], aq + (0), ar + (0));
    if (load_result != 0) {
      fprintf(stderr, "Error loading input tensors.");
      return 2;
    }
  } else if (argc != 1) {
    fprintf(stderr, "Unexpected number of arguments.");
    return 1;
  }

  // Inlined kernel follows. This is for warm-up.
  kernel(aq + (0), ar + (0), as + (0));

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
#pragma clang loop unroll(disable)
  for (unsigned long bench_itr = 0; bench_itr < 4UL; ++bench_itr) {
    kernel(aq + (0), ar + (0), as + (0));
  }
  clock_gettime(CLOCK_MONOTONIC, &end);
  struct timespec delta = ts_diff(start, end);
  printf("cpu: %llds %lldns\n", (long long)delta.tv_sec,
         (long long)delta.tv_nsec);

  free(aq);
  free(ar);
  free(as);

  return 0;
}
