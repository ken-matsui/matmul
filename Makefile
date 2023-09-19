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
M_VALUE = 2048
N_VALUE = 2048
K_VALUE = 2048

# All possible tiling values for mc, nc, kc
MC_VALUES := 1 2 4 8 16 32 64 128 256 512 1024 2048
NC_VALUES := $(MC_VALUES)
KC_VALUES := $(MC_VALUES)


# Common Source files
COMMON_SRCS = Bench.c
# Naive implementation
NAIVE_SRCS = Naive.c
# Generate all possible BLIS implementations
BLIS_SRCS := $(foreach mc,$(MC_VALUES),$(foreach nc,$(NC_VALUES),$(foreach kc,$(KC_VALUES),Blis_$(mc)_$(nc)_$(kc).c)))
# Generate all possible GEMM implementations
GEMM_SRCS := $(foreach mc,$(MC_VALUES),$(foreach nc,$(NC_VALUES),$(foreach kc,$(KC_VALUES),Gemm_$(mc)_$(nc)_$(kc).c)))

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

$(BLIS_SRCS): Blis.c.in
	@echo "/* Autogenerated file. Do not edit manually. */" > $@
	@sed -e 's/@MC_VALUE@/$(word 2,$(subst _, ,$*))/' \
	     -e 's/@NC_VALUE@/$(word 3,$(subst _, ,$*))/' \
	     -e 's/@KC_VALUE@/$(word 4,$(subst _, ,$*))/' $< >> $@

Blis_%_%.o: Blis_%_%.c Blis.h
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

$(GEMM_SRCS): Gemm.c.in
	@echo "/* Autogenerated file. Do not edit manually. */" > $@
	@sed -e 's/@MC_VALUE@/$(word 2,$(subst _, ,$*))/' \
	     -e 's/@NC_VALUE@/$(word 3,$(subst _, ,$*))/' \
	     -e 's/@KC_VALUE@/$(word 4,$(subst _, ,$*))/' $< >> $@

Gemm_%_%.o: Gemm_%_%.c Gemm.h
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
