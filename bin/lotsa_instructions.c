#include <stdio.h> 
#include <string.h>

int main()
{
    int i, j, k, l;
    int *mem;

beginning:
    const int ZERO = 0; // MOV R0
    const int ONE = 1;  // MOV R1


    int result; // R2
    
    result = ONE & ONE; // AND = 1
    if ((result & result)==0) { // result zero
        return;
    }

    result = ZERO ^ ONE; // XOR = 1
    if ((result ^ ONE) != 0) { // 1 ^ X = ~X
        return;
    }

    result = ZERO | ZERO; // OR = 0
    if ((result + result)!= 0) { // != 0
        return;
    }

    result = ZERO - ONE; // SUB = -1
    if (result - ONE >= 0) { // = -2 negative
        return;
    }


}   
//     int i = 0; // MOV
//     int j = 7; // MOV

//     int mem[j]; 
// here:
//     // Swap memory between i and j
//     while (i < j) { // CMN, B
//         // LDR mem[i], mem[j]
//         // BL
//         swap(mem[i], mem[j]);

//         // STR mem[i], mem[j]

//         i = i + 1;  // ADD
//         j = j - 1;  // SUB
//     }
//     read_mem(i, j);
//     goto here;

//     return 0;
// }

void read_mem(int i, int j){
    while (i <= j) {
        i = i & i;
        i += 1;
    }
    i = 0;
    return;
}

void swap(int A, int B) {
    // XOR mem[i], mem[j]
    A = A ^ B;
    B = B ^ A;
    A = A ^ B;
    return;
    // BX R14
}