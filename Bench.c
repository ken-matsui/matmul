#include "./Bench.h"

#include <time.h>

#define BILLION 1000000000ULL

struct timespec TsDiff(struct timespec start, struct timespec end) {
  struct timespec temp;
  if ((end.tv_nsec - start.tv_nsec) < 0) {
    temp.tv_sec = end.tv_sec - start.tv_sec - 1;
    temp.tv_nsec = BILLION + end.tv_nsec - start.tv_nsec;
  } else {
    temp.tv_sec = end.tv_sec - start.tv_sec;
    temp.tv_nsec = end.tv_nsec - start.tv_nsec;
  }
  return temp;
}

struct timespec ToTs(unsigned long long nsecs) {
  struct timespec result;
  result.tv_sec = nsecs / BILLION;   // get seconds
  result.tv_nsec = nsecs % BILLION;  // get the remaining nanoseconds
  return result;
}

unsigned long long ToNs(struct timespec ts) {
  return (unsigned long long)ts.tv_sec * BILLION + ts.tv_nsec;
}
