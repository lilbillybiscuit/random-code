#include <bits/stdc++.h>

using namespace std;
int arr[10]= {6,3,1,7,1,2,7,1,8,-1};
void selectionsort(int N) {
    int i, j, min_index;
    for (int i=0; i<N-1; i++) {
        min_index = i;
        for (int j=i+1; j<N; j++) {
            if (arr[j]<arr[min_index]) {
                min_index = j;
            }
        }
        int temp = arr[min_index];
        arr[min_index] = arr[i];
        arr[i]=temp;
    }
}

//replace first for loop with recursion
void recursiveselectionsort(int N, int ind) {
    if (ind==N) return;
    int min_index=ind;
    for (int j=ind+1; j<N; j++) {
        if (arr[j]<arr[min_index]) min_index = j;
    }
    swap(arr[min_index], arr[ind]); // c++ special thing
    recursiveselectionsort(N, ind+1);
}

int main() {
    recursiveselectionsort(10, 0);
    for (int i=0; i<10; i++) {
        cout << arr[i] << " ";
    }
    cout << endl;
}
