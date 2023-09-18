#pragma once

#include <stdint.h>  // for uint8_t

#define M 2048
#define N 2048
#define K 2048

void Naive(uint8_t *restrict A, uint8_t *restrict B, uint8_t *restrict C);

void Blis(uint8_t *A, uint8_t *B, uint8_t *restrict C, const int nc,
          const int kc, const int mc);

void Gemm(uint8_t *A, uint8_t *B, uint8_t *restrict C, const int nc,
          const int kc, const int mc);
