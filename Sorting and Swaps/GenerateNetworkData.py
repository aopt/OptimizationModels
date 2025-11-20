# generate network data (GAMS format)
# -----------------------------------
# we populate:
#  set nodes
#  set arcs(nodes,nodes)
# Output: file networkdata.inc 
#  

from sympy.utilities.iterables import multiset_permutations


# input string
input = "BDADDDBCCC"

# output file name
includefile = "networkdata.inc"


# convert list of chars to a string
def list2str(L):
    return ''.join(L)

# create nodes 
nodes=list(multiset_permutations(input))
# convert lists to strings
nodes = [list2str(lst) for lst in nodes]
nnodes = len(nodes)
print(f"number of nodes: {nnodes=}")

# write nodes to include file
with open(includefile,"w") as f:
    f.write(f"* number of nodes: {len(nodes)}\n")
    f.write("set nodes 'all possible unique orderings' /\n")
    k = 0
    for n in nodes:
        if k==0: 
            f.write(f" {n}")
            k += 1
        elif k==12: 
            f.write(f"\n {n}")
            k = 1
        else:
            f.write(f", {n}")
            k += 1
    f.write("\n/;\n")

# create arcs
arcs={}
narcs = 0
for n in nodes:
    s = set()
    lst = list(n)
    nlen = len(lst)
    for i in range(nlen-1):
        for j in range(i+1,nlen):
            if lst[i] != lst[j]:
                lst2 = lst.copy()
                lst2[i] = lst[j]
                lst2[j] = lst[i]
                str2 = list2str(lst2)
                s.add(str2)
    narcs += len(s)
    arcs[n]=s.copy()
print(f"number of arcs: {narcs=}")

# append to include file
with open("networkdata.inc","a") as f:
    f.write(f"* number of arcs: {narcs}\n")
    f.write("set arcs(nodes,nodes) 'formed by a swap' /\n")
    k = 0
    for n in nodes:
        for nn in arcs[n]:
            if k==0:
                f.write(f"  {n}.{nn}")
                k += 1
            elif k==6:
                f.write(f"\n  {n}.{nn}")
                k = 1
            else:
                f.write(f", {n}.{nn}")
                k += 1
    f.write("\n/;\n") 
