#!/bin/bash
set -e

systems=(
90POPC_10CHOL \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30SM16 \
60POPC_10CHOL_30LBPA22RR \
)

for s in ${systems[@]}; do

  for l in leaflet_A leaflet_B average; do

    # init arrays for next row
    unset dG
    declare -A dG
    unset err
    declare -A err

    for error_method in blockavg cumsum cumsumSSE; do

      # choose file
      if [[ "$l" == "average" ]]; then
	case $error_method in
	  blockavg)
	    barint=""
	    ;;
	  cumsum)
	    barint="$s/free_energy/${l}/bar_cumsum.xvg"
	    ;;
	  cumsumSSE)
	    barint="$s/free_energy/${l}/bar_cumsum_SSE.xvg"
	    ;;
	  *)
	    echo "wtf?"
	    ;;
	esac
      else
	case $error_method in
	  blockavg)
	    barint="$s/free_energy/${l}/analys/bar_b10000/barint_1-100000.xvg"
	    ;;
	  cumsum)
	    barint="$s/free_energy/${l}/analys/bar_b100000/1-100000/bar_cumsum.xvg"
	    ;;
	  cumsumSSE)
	    barint="$s/free_energy/${l}/analys/bar_b100000/1-100000/bar_cumsum_SSE.xvg"
	    ;;
	  *)
	    echo "wtf again?"
	    ;;
	esac
      fi

      # get delta G and error estimate
      if [[ -a $barint ]]; then
	dG[$error_method]=$(tail -n 1 $barint | awk '{print $2}')
	err[$error_method]=$(tail -n 1 $barint | awk '{print $3}')
      else
	dG[$error_method]=0
	err[$error_method]=0
      fi


    done
  
    # print row
    printf "%25s%10s%14s%14s%14s%14s%14s%14s\n" "$s" "$l" "${dG[blockavg]}" "${err[blockavg]}" "${dG[cumsum]}" "${err[cumsum]}" "${dG[cumsumSSE]}" "${err[cumsumSSE]}" 

  done

done

