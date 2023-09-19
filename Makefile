# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -std=gnu99 -fopenmp
LDFLAGS = -L.

# MORE_CFLAGS = -O1 -g -fsanitize=address
MORE_CFLAGS = -O3

# Archiver settings
AR = ar
ARFLAGS = rcs


# Matrix size (2^11 = 2048)
SIZE = 11

# Source files
COMMON_SRCS = Bench.c
NAIVE_SRCS = Naive.c
BLIS_SRCS = Blis.c
GEMM_SRCS = Gemm.c

# Header files
COMMON_HEADERS = Bench.h
NAIVE_HEADERS = Naive.h
BLIS_HEADERS = Blis.h
GEMM_HEADERS = Gemm.h

# Object files
COMMON_OBJS = $(COMMON_SRCS:.c=.o)
NAIVE_OBJS = $(NAIVE_SRCS:.c=.o)
BLIS_OBJS = $(BLIS_SRCS:.c=.o)
GEMM_OBJS = $(GEMM_SRCS:.c=.o)

# Executable files
EXECS = naive_run naive_bench blis_run blis_bench blis_autotune blis_old_bench gemm_run gemm_autotune morello_run morello_bench

all: $(EXECS)


naive_run: naive_run.o $(NAIVE_OBJS) libnaive.a $(NAIVE_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< libnaive.a $(LDFLAGS) -lnaive

naive_bench: naive_bench.o $(COMMON_OBJS) $(NAIVE_OBJS) libnaive.a $(COMMON_HEADERS) $(NAIVE_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(COMMON_OBJS) $(NAIVE_OBJS) libnaive.a $(LDFLAGS) -lnaive

libnaive.a: $(NAIVE_OBJS) $(NAIVE_HEADERS)
	$(AR) $(ARFLAGS) $@ $(NAIVE_OBJS)

naive_%.o: naive_%.c $(NAIVE_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

Naive.h: gen_header.py
	python3 $< $(SIZE) Naive > $@


blis_run: blis_run.o $(BLIS_OBJS) libblis.a $(BLIS_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(BLIS_OBJS) libblis.a $(LDFLAGS) -lblis

blis_bench: blis_bench.o $(COMMON_OBJS) $(BLIS_OBJS) libblis.a $(COMMON_HEADERS) $(BLIS_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(COMMON_OBJS) $(BLIS_OBJS) libblis.a $(LDFLAGS) -lblis

blis_autotune: blis_autotune.o $(COMMON_OBJS) $(BLIS_OBJS) libblis.a $(COMMON_HEADERS) $(BLIS_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(COMMON_OBJS) $(BLIS_OBJS) libblis.a $(LDFLAGS) -lblis

libblis.a: $(BLIS_OBJS) $(BLIS_HEADERS)
	$(AR) $(ARFLAGS) $@ $(BLIS_OBJS)

blis_%.o: blis_%.c $(BLIS_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

blis_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Blis > $@

Blis.h: gen_header.py
	python3 $< $(SIZE) Blis > $@

$(BLIS_SRCS): gen_source.py
	python3 $< $(SIZE) Blis > $@

Blis.o: Blis.c Blis.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


blis_old_bench: blis_old_bench.o BlisOld.o BlisOld.h $(COMMON_OBJS) $(COMMON_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< BlisOld.o $(COMMON_OBJS)

blis_old_bench.o: blis_old_bench.c BlisOld.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

BlisOld.o: BlisOld.c BlisOld.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


gemm_run: gemm_run.o $(GEMM_OBJS) libgemm.a $(GEMM_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(GEMM_OBJS) libgemm.a $(LDFLAGS) -lgemm

gemm_autotune: gemm_autotune.o $(COMMON_OBJS) $(GEMM_OBJS) libgemm.a $(COMMON_HEADERS) $(GEMM_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< $(COMMON_OBJS) $(GEMM_OBJS) libgemm.a $(LDFLAGS) -lgemm

libgemm.a: $(GEMM_OBJS) $(GEMM_HEADERS)
	$(AR) $(ARFLAGS) $@ $(GEMM_OBJS)

gemm_%.o: gemm_%.c $(GEMM_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

gemm_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Gemm > $@

Gemm.h: gen_header.py
	python3 $< $(SIZE) Gemm > $@

$(GEMM_SRCS): gen_source.py
	python3 $< $(SIZE) Gemm > $@

Gemm.o: Gemm.c Gemm.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


morello_run: morello_run.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_bench: morello_bench.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_%.o: morello_%.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


%.o: %.c $(COMMON_HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

check: naive_run blis_run gemm_run morello_run
	./naive_run
	./blis_run
	./gemm_run
	./morello_run
	diff -s --brief naive.txt blis.txt
	diff -s --brief naive.txt gemm.txt
	diff -s --brief naive.txt morello.txt

clean:
	rm -f *.o $(EXECS) libnaive.a Naive.h libblis.a $(BLIS_SRCS) Blis.h blis_autotune.c libgemm.a $(GEMM_SRCS) gemm_autotune.c Gemm.h
