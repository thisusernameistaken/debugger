#include <sys/mman.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

typedef uint64_t (*sc_fn)();

sc_fn gen_sc_fn(unsigned char *nops, uint64_t nop_len, uint64_t total_nop_bytes) {
	unsigned char *sc = malloc(total_nop_bytes + 0x100);
	uint64_t size = 0;

	// mfence
	sc[size++] = 0x0f;
	sc[size++] = 0xae;
	sc[size++] = 0xf0;

	// lfence
	sc[size++] = 0x0f;
	sc[size++] = 0xae;
	sc[size++] = 0xe8;
		
	// rdtsc
	sc[size++] = 0x0f;
	sc[size++] = 0x31;

	// push rax
	sc[size++] = 0x50;
	// push rdx
	sc[size++] = 0x52;

	while (size < total_nop_bytes) {
		for (int i = 0; i < nop_len; i ++) {
			sc[size++] = nops[i];
		}
	}
	
	// rdtsc
	sc[size++] = 0x0f;
	sc[size++] = 0x31;

	// shl rdx, 0x20
	sc[size++] = 0x48;
	sc[size++] = 0xc1;
	sc[size++] = 0xe2;
	sc[size++] = 0x20;

	// xor rdx, rax
	sc[size++] = 0x48;
	sc[size++] = 0x31;
	sc[size++] = 0xc2;

	// pop rcx
	sc[size++] = 0x59;
	// pop rax
	sc[size++] = 0x58;

	// shl rcx, 0x20
	sc[size++] = 0x48;
	sc[size++] = 0xc1;
	sc[size++] = 0xe1;
	sc[size++] = 0x20;

	// xor rcx, rax
	sc[size++] = 0x48;
	sc[size++] = 0x31;
	sc[size++] = 0xc1;

	// sub rdx, rcx
	sc[size++] = 0x48;
	sc[size++] = 0x29;
	sc[size++] = 0xca;
	
	// mov rax, rcx
	sc[size++] = 0x48;
	sc[size++] = 0x89;
	sc[size++] = 0xd0;

	// ret
	sc[size++] = 0xc3;	

	void *ptr = mmap(0, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_ANON | MAP_PRIVATE, 0, 0);
	
	if (ptr == MAP_FAILED) {
		perror("mmap");
		exit(1);
	}
	
	memcpy(ptr, sc, size);		

	free(sc);

	return ptr;
}

int main() {
	unsigned char nops[16][15] = {
		  {0x90}
		, {0x66,0x90}
		, {0x0f,0x1f,0x00}
		, {0x0f,0x1f,0x40,0x00}
		, {0x0f,0x1f,0x44,0x00,0x00}
		, {0x66,0x0f,0x1f,0x44,0x00,0x00}
		, {0x0f,0x1f,0x80,0x00,0x00,0x00,0x00}
		, {0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x66,0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x66,0x66,0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x66,0x66,0x66,0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
		, {0x66,0x66,0x66,0x66,0x66,0x66,0x2e,0x0f,0x1f,0x84,0x00,0x00,0x00,0x00,0x00}
	};

	int total_nop_bytes = 0x800000;	

	for (int i = 0; i < 15; i++) {
		sc_fn ptr = gen_sc_fn(nops[i], i + 1, total_nop_bytes);
	
		uint64_t sum = 0;
		uint64_t runs = 0;
	
		for (int j = 0; j < 1000; j ++) {
			uint64_t time = ptr();
			sum += time;
			runs ++;
		}
		double avg = (double)sum / (double)runs;
		printf("0x%x bytes of nops of length %d took %f cycles on avg\n", total_nop_bytes, i + 1, avg);
	}
}