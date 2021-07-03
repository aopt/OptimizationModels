This model tries to arrange points on a 1d line such that the minimum distance between points is maximized.

See: https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/arranging-points-on-line.html

The GAMS file tries MINLP and MIP formulations.
The R code tries a genetic algorithm.

The random data set we generated has n=50 points. It looks like:

```
----     40 PARAMETER bounds  ranges

i1 .lo 13.740,    i1 .up 23.656,    i2 .lo 67.461,    i2 .up 78.799,    i3 .lo 44.030,    i3 .up 53.442
i4 .lo 24.091,    i4 .up 28.349,    i5 .lo 23.377,    i5 .up 24.673,    i6 .lo 17.924,    i6 .up 19.462
i7 .lo 27.986,    i7 .up 37.605,    i8 .lo 68.502,    i8 .up 76.681,    i9 .lo  5.369,    i9 .up  5.842
i10.lo 40.017,    i10.up 51.902,    i11.lo 79.849,    i11.up 80.941,    i12.lo 46.299,    i12.up 48.934
i13.lo 79.291,    i13.up 87.175,    i14.lo 60.980,    i14.up 72.233,    i15.lo 10.455,    i15.up 13.127
i16.lo 51.178,    i16.up 51.690,    i17.lo 12.761,    i17.up 21.538,    i18.lo 20.006,    i18.up 29.325
i19.lo 53.514,    i19.up 59.355,    i20.lo 34.829,    i20.up 40.209,    i21.lo 28.776,    i21.up 32.422
i22.lo 28.115,    i22.up 31.812,    i23.lo 10.519,    i23.up 12.477,    i24.lo 12.008,    i24.up 26.010
i25.lo 47.129,    i25.up 52.828,    i26.lo 66.471,    i26.up 78.222,    i27.lo 18.465,    i27.up 22.966
i28.lo 53.259,    i28.up 55.141,    i29.lo 62.069,    i29.up 73.302,    i30.lo 24.293,    i30.up 25.331
i31.lo  8.839,    i31.up 11.870,    i32.lo 40.191,    i32.up 40.267,    i33.lo 12.814,    i33.up 16.858
i34.lo 69.797,    i34.up 77.295,    i35.lo 21.209,    i35.up 23.478,    i36.lo 22.865,    i36.up 25.478
i37.lo 47.516,    i37.up 52.476,    i38.lo 57.818,    i38.up 62.571,    i39.lo 50.260,    i39.up 55.091
i40.lo 37.104,    i40.up 51.563,    i41.lo 33.065,    i41.up 47.969,    i42.lo  9.416,    i42.up 14.964
i43.lo 25.137,    i43.up 30.730,    i44.lo  3.724,    i44.up 15.304,    i45.lo 27.084,    i45.up 33.034
i46.lo 14.568,    i46.up 28.264,    i47.lo 51.658,    i47.up 53.452,    i48.lo 44.860,    i48.up 55.892
i49.lo 61.597,    i49.up 62.428,    i50.lo 23.824,    i50.up 32.469
```
The final solution can be depicted as:


