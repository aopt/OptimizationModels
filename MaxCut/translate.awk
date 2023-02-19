{
  if (NR==1) {
     print "* Source data: g05_60.0"
     print "set i /node1*node" $1 "/;"
     print "parameter w(i,i) /"
     next
  }

  print "node" $1 ".node" $2 " " $3

}

END { print "/;"}
