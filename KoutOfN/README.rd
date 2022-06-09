## Choose K out of N

Reference:
http://yetanothermathprogrammingconsultant.blogspot.com/2022/06/a-subset-selection-problem.html

The GAMS model demonstrates:
  1. Select exactly k points out of n such that the average is as close to a target point. 
  2. Specialized model in case we have just a few unique values.
  3. Select up to k points, using a loop.
  4. Select up to k points, using an extended model. This is a bit more complex.