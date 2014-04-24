#!/bin/bash -e

if test ! "$#" = 2; then
  echo "Usage: $0 history_dir libname"
  echo "Example: $0 /var/www/libraries/history MSL_3.2.1"
  exit 1
fi

HISTORY="$1"
LIB="$2"
test -d "$HISTORY"

FIRST_DATE=`grep -H "Simulation Results:" "$HISTORY/${LIB}"-*.html | head -n1 | cut -d: -f1 | grep -o "20[0-9-]*"`
LAST_DATE=`grep -H "Simulation Results:" "$HISTORY/${LIB}"-*.html | tail -n1 | cut -d: -f1 | grep -o "20[0-9-]*"`
if test "$FIRST_DATE" = "$LAST_DATE"; then
  FIRST_DATE="1970-01-01"
fi
GOAL=`grep -H "Simulation Results:" "$HISTORY/${LIB}"-*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,.*/,,`
CURS=`grep -H "Simulation Results:" "$HISTORY/${LIB}"-*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,/.*,,`
CURC=`grep -H "BuildModel Results:" "$HISTORY/${LIB}"-*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,/.*,,`
cat > "$HISTORY/${LIB}-trend.gnuplot" <<EOF
set term png
set datafile separator ","
set xlabel "Date $FIRST_DATE - $LAST_DATE"
set ylabel "Models"
set xdata time
set timefmt "%Y-%m-%d"
#set xrange ["2012-10-17":"2012-11-22"]
set format x "%m-%d"
set xrange ["$FIRST_DATE":"$LAST_DATE"]
# set yrange [0:$(( (($GOAL+9)/10)*10 ))]
set yrange [0:]
# set ytics 10
# set xtics rotate by -13 font "Helvetica,8"
set title '$LIB Coverage'
set output "${LIB}-trend.png"
goal(x) = $GOAL
currentC(x) = $CURC
currentS(x) = $CURS
set key right bottom Left title 'Legend'
set style line 1 linecolor rgb "red"   pt 1 ps 1
set style line 2 linecolor rgb "green" pt 1 ps 1
set style line 3 linecolor rgb "blue"  pt 1 ps 1
plot "${LIB}-trend.csv" using 1:2 title 'Target: $GOAL'   with lines ls 1, \
     "${LIB}-trend.csv" using 1:3 title 'Compile: $CURC'  with lines ls 2, \
     "${LIB}-trend.csv" using 1:4 title 'Simulate: $CURS' with lines ls 3
EOF
rm -f "$HISTORY/${LIB}"-trend.csv
for f in `grep -H "Simulation Results:" "$HISTORY/${LIB}"-*.html | cut -d: -f1` ; do
  DATE=`echo "$f" | grep -o "20[0-9-]*"`
  BUILD=`grep "BuildModel Results:" "$f" | cut -d: -f2 | cut -d/ -f1 | tr -d \ `
  SIM=`grep "Simulation Results:" "$f" | cut -d: -f2`
  SIMSUC=`echo "$SIM" | cut -d/ -f1`
  TOT=`echo "$SIM" | cut -d/ -f2 | cut -d" " -f1`
  REV=`grep -o "[(]r[0-9]*" "$f" | tr -d "("`
  echo "$DATE,$TOT,$BUILD,$SIMSUC" >> "$HISTORY/${LIB}-trend.csv"
done
(cd "$HISTORY"; gnuplot "${LIB}-trend.gnuplot")
sed -i s/png/svg/ "$HISTORY/${LIB}-trend.gnuplot"
(cd "$HISTORY"; gnuplot "${LIB}-trend.gnuplot")
