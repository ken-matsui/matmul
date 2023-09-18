#pragma once

#include <stdint.h>  // for uint8_t

#define M 2048
#define N 2048
#define K 2048

void Naive(uint8_t *restrict A, uint8_t *restrict B, uint8_t *restrict C);
