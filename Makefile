# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -std=gnu99 -flto
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
EXECS = naive_run naive_bench block_run block_bench block_autotune pack_run pack_bench pack_autotune

all: $(EXECS)

clean:
	rm -f *.o $(EXECS) blis_old_bench morello_run morello_bench Naive.h Block.c block_autotune.c Block.h Pack.c Pack.h pack_autotune.c

check: run_naive check_block check_pack check_morello

run_naive: naive_run
	./naive_run
check_block: block_run run_naive
	./block_run
	diff -s --brief naive.txt block.txt
check_pack: pack_run run_naive
	./pack_run
	diff -s --brief naive.txt pack.txt
check_morello: morello_run run_naive
	./morello_run
	diff -s --brief naive.txt morello.txt

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


block_run: block_run.o Block.o
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Block.o

block_bench: block_bench.o Block.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Block.o $(OBJS)

block_autotune: block_autotune.o Block.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Block.o $(OBJS)

block_%.o: block_%.c Block.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

block_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Block > $@

Block.h: gen_header.py
	python3 $< $(SIZE) Block > $@

Block.c: gen_source.py
	python3 $< $(SIZE) Block > $@

Block.o: Block.c Block.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


pack_run: pack_run.o Pack.o
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Pack.o

pack_bench: pack_bench.o Pack.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Pack.o $(OBJS)

pack_autotune: pack_autotune.o Pack.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< Pack.o $(OBJS)

pack_%.o: pack_%.c Pack.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

pack_autotune.c: gen_autotune.py
	python3 $< $(SIZE) Pack > $@

Pack.h: gen_header.py
	python3 $< $(SIZE) Pack > $@

Pack.c: gen_source.py
	python3 $< $(SIZE) Pack > $@

Pack.o: Pack.c Pack.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


morello_run: morello_run.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_bench: morello_bench.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $<

morello_%.o: morello_%.c
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@


blis_old_bench: blis_old_bench.o BlisOld.o $(OBJS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< BlisOld.o $(OBJS)

blis_old_bench.o: blis_old_bench.c BlisOld.h $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

BlisOld.o: BlisOld.c BlisOld.h
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@
