/*
 * Kernel function
 * updates C[x:x+kernel_size.first][y:y+kernel_size.second/BLOCK_SIZE]
 * multiply A[x:x+kernel_size.first][l:r] with B[l:r][y:y+kernel_size.second/BLOCK_SIZE]
 * x and y determine the continuous kernel_size block that is modified in C. They do not have to be
 */

__attribute__((hot))
#if defined(__x86_64__) || defined(_M_X64)
__attribute__((target("avx512f")))
__attribute__((target("avx2")))
#else
#endif
inline __attribute__((always_inline)) void kernel(const intvec *__restrict__ A, const intvec * __restrict__ B, intvec *__restrict__ C,
                   int x, int y, // starting index of the BLOCK
                   int l, int r, // range for k (horizontal portion of row in A, vertical portion of column in B)
                   int stride) {
    intvec ke[kernel_size.first][kernel_size.second/BLOCK_SIZE] = {};

    for (int k=l; k<r; k++) { // TODO: either loop unrolling, or some other way to iterate to make it faster (eg. reduce matrix index calculations)
                              // TODO: potentially support dynamic kernel sizes at the cost of not having constant loop sizes (loop unenrolling)
        for (int i=x; i<x+kernel_size.first; ++i) {
            for (int j=y; j<y+kernel_size.second/BLOCK_SIZE; ++j) {
                intvec tmp = intvec{} + A[i*stride + k/BLOCK_SIZE][k%BLOCK_SIZE]; // broadcast A
                ke[i-x][j-y] += tmp * B[k*stride + j];
            }
        }
    }

    for (int i=x; i<x+kernel_size.first; i++) {
        for (int j=y; j<y+kernel_size.second/BLOCK_SIZE; ++j) {
            C[i*stride + j] += ke[i-x][j-y];
        }
    }
}
