library(tidyverse)

df <- read.table(text="
cell value prime
solution1.i1.j1          41           p
solution1.i1.j2          40          np
solution1.i1.j3          39          np
solution1.i1.j4          30          np
solution1.i1.j5          29           p
solution1.i1.j6          28          np
solution1.i1.j7          21          np
solution1.i1.j8          20          np
solution1.i2.j1          42          np
solution1.i2.j2          37           p
solution1.i2.j3          38          np
solution1.i2.j4          31           p
solution1.i2.j5          32          np
solution1.i2.j6          27          np
solution1.i2.j7          22          np
solution1.i2.j8          19           p
solution1.i3.j1          43           p
solution1.i3.j2          36          np
solution1.i3.j3          35          np
solution1.i3.j4          34          np
solution1.i3.j5          33          np
solution1.i3.j6          26          np
solution1.i3.j7          23           p
solution1.i3.j8          18          np
solution1.i4.j1          44          np
solution1.i4.j2          45          np
solution1.i4.j3          46          np
solution1.i4.j4           3           p
solution1.i4.j5           4          np
solution1.i4.j6          25          np
solution1.i4.j7          24          np
solution1.i4.j8          17           p
solution1.i5.j1          51          np
solution1.i5.j2          50          np
solution1.i5.j3          47           p
solution1.i5.j4           2           p
solution1.i5.j5           5           p
solution1.i5.j6           8          np
solution1.i5.j7           9          np
solution1.i5.j8          16          np
solution1.i6.j1          52          np
solution1.i6.j2          49          np
solution1.i6.j3          48          np
solution1.i6.j4           1          np
solution1.i6.j5           6          np
solution1.i6.j6           7           p
solution1.i6.j7          10          np
solution1.i6.j8          15          np
solution1.i7.j1          53           p
solution1.i7.j2          56          np
solution1.i7.j3          57          np
solution1.i7.j4          58          np
solution1.i7.j5          59           p
solution1.i7.j6          60          np
solution1.i7.j7          11           p
solution1.i7.j8          14          np
solution1.i8.j1          54          np
solution1.i8.j2          55          np
solution1.i8.j3          64          np
solution1.i8.j4          63          np
solution1.i8.j5          62          np
solution1.i8.j6          61           p
solution1.i8.j7          12          np
solution1.i8.j8          13           p
solution2.i1.j1          41           p
solution2.i1.j2          40          np
solution2.i1.j3          39          np
solution2.i1.j4          30          np
solution2.i1.j5          29           p
solution2.i1.j6          28          np
solution2.i1.j7          21          np
solution2.i1.j8          20          np
solution2.i2.j1          42          np
solution2.i2.j2          37           p
solution2.i2.j3          38          np
solution2.i2.j4          31           p
solution2.i2.j5          32          np
solution2.i2.j6          27          np
solution2.i2.j7          22          np
solution2.i2.j8          19           p
solution2.i3.j1          43           p
solution2.i3.j2          36          np
solution2.i3.j3          35          np
solution2.i3.j4          34          np
solution2.i3.j5          33          np
solution2.i3.j6          26          np
solution2.i3.j7          23           p
solution2.i3.j8          18          np
solution2.i4.j1          44          np
solution2.i4.j2          45          np
solution2.i4.j3          46          np
solution2.i4.j4           3           p
solution2.i4.j5           4          np
solution2.i4.j6          25          np
solution2.i4.j7          24          np
solution2.i4.j8          17           p
solution2.i5.j1          51          np
solution2.i5.j2          50          np
solution2.i5.j3          47           p
solution2.i5.j4           2           p
solution2.i5.j5           5           p
solution2.i5.j6           8          np
solution2.i5.j7           9          np
solution2.i5.j8          16          np
solution2.i6.j1          52          np
solution2.i6.j2          49          np
solution2.i6.j3          48          np
solution2.i6.j4           1          np
solution2.i6.j5           6          np
solution2.i6.j6           7           p
solution2.i6.j7          10          np
solution2.i6.j8          15          np
solution2.i7.j1          53           p
solution2.i7.j2          64          np
solution2.i7.j3          63          np
solution2.i7.j4          62          np
solution2.i7.j5          61           p
solution2.i7.j6          60          np
solution2.i7.j7          11           p
solution2.i7.j8          14          np
solution2.i8.j1          54          np
solution2.i8.j2          55          np
solution2.i8.j3          56          np
solution2.i8.j4          57          np
solution2.i8.j5          58          np
solution2.i8.j6          59           p
solution2.i8.j7          12          np
solution2.i8.j8          13           p
solution3.i1.j1          41           p
solution3.i1.j2          40          np
solution3.i1.j3          39          np
solution3.i1.j4          30          np
solution3.i1.j5          29           p
solution3.i1.j6          28          np
solution3.i1.j7          21          np
solution3.i1.j8          20          np
solution3.i2.j1          42          np
solution3.i2.j2          37           p
solution3.i2.j3          38          np
solution3.i2.j4          31           p
solution3.i2.j5          32          np
solution3.i2.j6          27          np
solution3.i2.j7          22          np
solution3.i2.j8          19           p
solution3.i3.j1          43           p
solution3.i3.j2          36          np
solution3.i3.j3          35          np
solution3.i3.j4          34          np
solution3.i3.j5          33          np
solution3.i3.j6          26          np
solution3.i3.j7          23           p
solution3.i3.j8          18          np
solution3.i4.j1          44          np
solution3.i4.j2          45          np
solution3.i4.j3          46          np
solution3.i4.j4           3           p
solution3.i4.j5           4          np
solution3.i4.j6          25          np
solution3.i4.j7          24          np
solution3.i4.j8          17           p
solution3.i5.j1          49          np
solution3.i5.j2          48          np
solution3.i5.j3          47           p
solution3.i5.j4           2           p
solution3.i5.j5           5           p
solution3.i5.j6           8          np
solution3.i5.j7           9          np
solution3.i5.j8          16          np
solution3.i6.j1          50          np
solution3.i6.j2          51          np
solution3.i6.j3          64          np
solution3.i6.j4           1          np
solution3.i6.j5           6          np
solution3.i6.j6           7           p
solution3.i6.j7          10          np
solution3.i6.j8          15          np
solution3.i7.j1          53           p
solution3.i7.j2          52          np
solution3.i7.j3          63          np
solution3.i7.j4          62          np
solution3.i7.j5          61           p
solution3.i7.j6          60          np
solution3.i7.j7          11           p
solution3.i7.j8          14          np
solution3.i8.j1          54          np
solution3.i8.j2          55          np
solution3.i8.j3          56          np
solution3.i8.j4          57          np
solution3.i8.j5          58          np
solution3.i8.j6          59           p
solution3.i8.j7          12          np
solution3.i8.j8          13           p
solution4.i1.j1          43           p
solution4.i1.j2          44          np
solution4.i1.j3          45          np
solution4.i1.j4           6          np
solution4.i1.j5           7           p
solution4.i1.j6           8          np
solution4.i1.j7           9          np
solution4.i1.j8          10          np
solution4.i2.j1          42          np
solution4.i2.j2          47           p
solution4.i2.j3          46          np
solution4.i2.j4           5           p
solution4.i2.j5          64          np
solution4.i2.j6          25          np
solution4.i2.j7          24          np
solution4.i2.j8          11           p
solution4.i3.j1          41           p
solution4.i3.j2          48          np
solution4.i3.j3          49          np
solution4.i3.j4           4          np
solution4.i3.j5          63          np
solution4.i3.j6          26          np
solution4.i3.j7          23           p
solution4.i3.j8          12          np
solution4.i4.j1          40          np
solution4.i4.j2          51          np
solution4.i4.j3          50          np
solution4.i4.j4           3           p
solution4.i4.j5          62          np
solution4.i4.j6          27          np
solution4.i4.j7          22          np
solution4.i4.j8          13           p
solution4.i5.j1          39          np
solution4.i5.j2          52          np
solution4.i5.j3          53           p
solution4.i5.j4           2           p
solution4.i5.j5          61           p
solution4.i5.j6          28          np
solution4.i5.j7          21          np
solution4.i5.j8          14          np
solution4.i6.j1          38          np
solution4.i6.j2          55          np
solution4.i6.j3          54          np
solution4.i6.j4           1          np
solution4.i6.j5          60          np
solution4.i6.j6          29           p
solution4.i6.j7          20          np
solution4.i6.j8          15          np
solution4.i7.j1          37           p
solution4.i7.j2          56          np
solution4.i7.j3          57          np
solution4.i7.j4          58          np
solution4.i7.j5          59           p
solution4.i7.j6          30          np
solution4.i7.j7          19           p
solution4.i7.j8          16          np
solution4.i8.j1          36          np
solution4.i8.j2          35          np
solution4.i8.j3          34          np
solution4.i8.j4          33          np
solution4.i8.j5          32          np
solution4.i8.j6          31           p
solution4.i8.j7          18          np
solution4.i8.j8          17           p
",header=T)


df2 <- separate(df,cell,into=c('solution','row','col'))
df2$solution <- as.numeric(sub("solution","",df2$solution))
df2$row <- as.numeric(sub("i","",df2$row))
df2$col <- as.numeric(sub("j","",df2$col))

df2$x <- (df2$solution-1)*9 + df2$col
df2$y <- 9 - df2$row

df2$color <- ifelse(df2$prime=="p","grey20",ifelse(df2$value %in% c(1,64),"yellow","white"))


p <- ggplot() + 
  theme_void() +
  geom_rect(data=df2, 
            mapping=aes(xmin=x-0.5, xmax=x+0.5, ymin=y-0.5, ymax=y+0.5), 
            color="black", 
            fill=df2$color,
            alpha=0.5)+
  geom_text(data=df2,aes(x=x,y=y,label=value))

for (s in 1:4)
  for (k in 1:63) {
    x1 <- df2$x[df2$value==k & df2$solution==s]
    y1 <- df2$y[df2$value==k & df2$solution==s]
    x2 <- df2$x[df2$value==k+1 & df2$solution==s]
    y2 <- df2$y[df2$value==k+1 & df2$solution==s]
    p <- p + annotate("segment",x=x1,xend=x2,y=y1,yend=y2,color="red",size=2,alpha=0.3)
}
p



