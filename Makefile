# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -std=gnu99 # -fopenmp
LDFLAGS = -L.

# MORE_CFLAGS = -O1 -g -fsanitize=address
MORE_CFLAGS = -O3

# Archiver settings
AR = ar
ARFLAGS = rcs


# Matrix size (2^11 = 2048)
SIZE ?= 11

# Source files
SRCS = Bench.c
# Header files
HEADERS = Bench.h
# Object files
OBJS = $(SRCS:.c=.o)

# Executable files
EXECS = naive_run naive_bench blis_run blis_bench blis_autotune blis_old_bench gemm_run gemm_autotune

all: $(EXECS)

$(OBJS): $(SRCS) $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


naive_run: naive_run.o Naive.o
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Naive.o

naive_bench: naive_bench.o Naive.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Naive.o $(OBJS)

naive_%.o: naive_%.c Naive.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

Naive.h: gen_header.py
	python3 $< $(SIZE) Naive > $@

Naive.o: Naive.c Naive.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


blis_run: blis_run.o Blis.o
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Blis.o

blis_bench: blis_bench.o Blis.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Blis.o $(OBJS)

blis_autotune: blis_autotune.o Blis.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Blis.o $(OBJS)

blis_%.o: blis_%.c Blis.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

blis_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Blis > $@

Blis.h: gen_header.py
	python3 $< $(SIZE) Blis > $@

Blis.c: gen_source.py
	python3 $< $(SIZE) Blis > $@

Blis.o: Blis.c Blis.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


blis_old_bench: blis_old_bench.o BlisOld.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< BlisOld.o $(OBJS)

blis_old_bench.o: blis_old_bench.c BlisOld.h $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

BlisOld.o: BlisOld.c BlisOld.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


gemm_run: gemm_run.o Gemm.o
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Gemm.o

gemm_autotune: gemm_autotune.o Gemm.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Gemm.o $(OBJS)

gemm_%.o: gemm_%.c Gemm.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

gemm_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Gemm > $@

Gemm.h: gen_header.py
	python3 $< $(SIZE) Gemm > $@

Gemm.c: gen_source.py
	python3 $< $(SIZE) Gemm > $@

Gemm.o: Gemm.c Gemm.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


morello_run: morello_run.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_bench: morello_bench.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_%.o: morello_%.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


# Used for CI
test: naive_run blis_run gemm_run
	./naive_run
	./blis_run
	./gemm_run
	diff -s --brief naive.txt blis.txt
	diff -s --brief naive.txt gemm.txt
check: naive_run blis_run gemm_run morello_run
	./naive_run
	./blis_run
	./gemm_run
	./morello_run
	diff -s --brief naive.txt blis.txt
	diff -s --brief naive.txt gemm.txt
	diff -s --brief naive.txt morello.txt

clean:
	rm -f *.o $(EXECS) morello_run morello_bench Naive.h Blis.c Blis.h blis_autotune.c Gemm.c gemm_autotune.c Gemm.h
