#include <math.h>    // for pow
#include <stdint.h>  // for uint8_t
#include <stdio.h>   // for printf
#include <stdlib.h>  // for arc4random, free, posix_memalign
#include <time.h>    // for clock_gettime, timespec, CLOCK_MONOTONIC

#include "./Bench.h"
#include "./Matmul.h"

static struct timespec call_kernel(const int nc, const int kc, const int mc) {
  printf("(nc: %d, kc: %d, mc: %d)\n", nc, kc, mc);

  uint8_t *A;
  posix_memalign((void **)&A, 128, M * K * sizeof(uint8_t));
  for (int i = 0; i < M * K; ++i) {
    A[i] = (uint8_t)arc4random();
  }

  uint8_t *B;
  posix_memalign((void **)&B, 128, K * N * sizeof(uint8_t));
  for (int i = 0; i < K * N; ++i) {
    B[i] = (uint8_t)arc4random();
  }

  uint8_t *restrict C;
  posix_memalign((void **)&C, 128, M * N * sizeof(uint8_t));
  for (int i = 0; i < M * N; ++i) {
    C[i] = 0;
  }

  // Inlined kernel follows. This is for warm-up.
  Gemm(A, B, C, nc, kc, mc);

  struct timespec start, end;
  struct timespec total_time = {0, 0};
  const int num_iterations = 10;
#pragma clang loop unroll(disable)
  for (int i = 0; i < num_iterations; ++i) {
    clock_gettime(CLOCK_MONOTONIC, &start);
    Gemm(A, B, C, nc, kc, mc);
    clock_gettime(CLOCK_MONOTONIC, &end);

    total_time.tv_sec += TsDiff(start, end).tv_sec;
    total_time.tv_nsec += TsDiff(start, end).tv_nsec;
    printf("INFO[%d]: %lds %ldns\n", i, TsDiff(start, end).tv_sec,
           TsDiff(start, end).tv_nsec);
  }
  struct timespec avg_time;
  avg_time.tv_sec = (total_time.tv_sec / num_iterations);
  avg_time.tv_nsec = (total_time.tv_nsec / num_iterations);
  printf("(nc: %d, kc: %d, mc: %d): %lds %ldns\n", nc, kc, mc, avg_time.tv_sec,
         avg_time.tv_nsec);

  free(A);
  free(B);
  free(C);

  return avg_time;
}

struct Param {
  int nc;
  int mc;
  int kc;
};

int main(void) {
  struct timespec min_time = {1000000000, 0};
  struct Param min_param = {0, 0, 0};

  for (int nc_exp = 0; nc_exp < 12; ++nc_exp) {
    for (int mc_exp = 0; mc_exp < 12; ++mc_exp) {
      for (int kc_exp = 0; kc_exp < 12; ++kc_exp) {
        const int nc = pow(2, nc_exp);
        const int mc = pow(2, mc_exp);
        const int kc = pow(2, kc_exp);
        struct timespec avg_time = call_kernel(nc, kc, mc);
        if (avg_time.tv_sec < min_time.tv_sec ||
            (avg_time.tv_sec == min_time.tv_sec &&
             avg_time.tv_nsec < min_time.tv_nsec)) {
          min_time = avg_time;
          struct Param new_param = {nc, mc, kc};
          min_param = new_param;
        }
      }
    }
  }

  // min_param:
  printf("min_param: (nc: %d, kc: %d, mc: %d): %lds %ldns\n", min_param.nc,
         min_param.kc, min_param.mc, min_time.tv_sec, min_time.tv_nsec);

  return 0;
}
