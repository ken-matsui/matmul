#pragma once

#include <time.h>

struct timespec TsDiff(struct timespec start, struct timespec end);

struct timespec ToTs(unsigned long long nsecs);

unsigned long long ToNs(struct timespec ts);
