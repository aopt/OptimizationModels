# measure number of swaps in Quicksort
# ------------------------------------
# simple quicksort from https://www.w3schools.com/dsa/dsa_algo_quicksort.php
# I added a swap counter.
#
# result:
#  BDADDDBCCC -> ABBCCCDDDD #swaps:28
#  ABBCCCDDDD -> ABBCCCDDDD #swaps:54


def partition(array, low, high):
    swaps = 0
    pivot = array[high]
    i = low - 1

    for j in range(low, high):
        if array[j] <= pivot:
            i += 1
            array[i], array[j] = array[j], array[i]
            swaps += 1

    array[i+1], array[high] = array[high], array[i+1]
    swaps += 1
    return swaps,i+1

def quicksort(array, low=0, high=None): 
    if high is None:
        high = len(array) - 1

    if low < high:
        n1,pivot_index = partition(array, low, high)
        n2 = quicksort(array, low, pivot_index-1)
        n3 = quicksort(array, pivot_index+1, high)
        return n1+n2+n3
    else:
        return 0

def list2str(L):
    return ''.join(L)

# sort characters in string
def strsort(s):
    L = list(s)
    n = quicksort(L)
    s2 = list2str(L)
    return s2,n

# sort input 
s = "BDADDDBCCC"  
t,n=strsort(s)
print(f"{s} -> {t} #swaps:{n}")

# sort again (already sorted)
t2,n=strsort(t)
print(f"{t} -> {t2} #swaps:{n}")