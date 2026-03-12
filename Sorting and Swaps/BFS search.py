from collections import deque

start = "BDADDDBCCC"
goal  = "ABBCCCDDDD"

def neighbors(s):
    i = 0
    while i < len(s) and s[i] == goal[i]:
        i += 1
    if i == len(s):
        return
    
    for j in range(i+1, len(s)):
        if s[j] == goal[i] and s[j] != goal[j]:
            t = list(s)
            t[i], t[j] = t[j], t[i]
            yield ''.join(t), (i, j)

def min_swaps(start, goal):
    q = deque([(start, [])])
    seen = {start}

    while q:
        s, path = q.popleft()

        if s == goal:
            return path

        for t, swap in neighbors(s):
            if t not in seen:
                seen.add(t)
                q.append((t, path + [swap]))

path = min_swaps(start, goal)

print("Minimum # of swaps:", len(path))


s = start
for step,(i,j) in enumerate(path,1):
    t = list(s)
    t[i],t[j] = t[j],t[i]
    prev = s
    s = ''.join(t)
    print(f"{step}. {prev} -> {s}")
