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
  for (int ad = 0; ad < 1024; ad++) {
    for (int ae = 0; ae < 512; ae++) {
      for (int af = 0; af < 1024; af++) {
        for (int ag = 0; ag < 2; ag++) {
          for (int ah = 0; ah < 2; ah++) {
            uint8_t ai[2] __attribute__((aligned(128)));
            for (int aj = 0; aj < 2; aj++) {
              ai[(aj)] = aa[(2048 * aj + 4096 * ag + 8192 * ae + ah + 2 * ad)];
            }
            uint8_t ak[2] __attribute__((aligned(128)));
            for (int al = 0; al < 2; al++) {
              ak[(al)] = ab[(2048 * ah + 4096 * ad + al + 2 * af)];
            }
            for (int am = 0; am < 2; am++) {
              for (int an = 0; an < 2; an++) {
                uint8_t ao;
                ao = ac[(2048 * am + 4096 * ag + 8192 * ae + an + 2 * af)];
                ao += ai[(am)] * ak[(an)]; /* Mult */
                ac[(2048 * am + 4096 * ag + 8192 * ae + an + 2 * af)] = ao;
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
  uint8_t *restrict ap;
  posix_memalign((void **)&ap, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    ap[idx] = idx % 5;  // original: (uint8_t)rand()
  }

  uint8_t *restrict aq;
  posix_memalign((void **)&aq, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    aq[idx] = idx % 5;  // original: (uint8_t)rand()
  }

  uint8_t *restrict ar;
  posix_memalign((void **)&ar, 128, 4194304 * sizeof(uint8_t));
  for (size_t idx = 0; idx < 4194304; idx++) {
    ar[idx] = 0;  // original: (uint8_t)rand()
  }

  if (argc == 3) {
    int load_result = load_inputs(&argv[1], ap + (0), aq + (0));
    if (load_result != 0) {
      fprintf(stderr, "Error loading input tensors.");
      return 2;
    }
  } else if (argc != 1) {
    fprintf(stderr, "Unexpected number of arguments.");
    return 1;
  }

  kernel(ap + (0), aq + (0), ar + (0));

  // Write the result to morello.txt
  FILE *fp = fopen("morello.txt", "w");
  for (int i = 0; i < 2048; ++i) {
    for (int j = 0; j < 2048; ++j) {
      fprintf(fp, "%d ", ar[i * 2048 + j]);
    }
    fprintf(fp, "\n");
  }
  fclose(fp);

  free(ap);
  free(aq);
  free(ar);

  return 0;
}
