#!/bin/bash

# 	Matej Slivka 	# 
#	2021 	     	#
# 	1. projekt IOS  #

export POSIXLY_CORRECT=yes

# ........................... function help ..................................
# function prints help
# ............................................................................
function help ()
{
	echo ""
	echo "tradelog [-h|--help]"
	echo "tradelog [FILTER] [ORDER] [LOG] [LOG2] [LOG...]]"
	echo "Function expects  transactions written as "
	echo "DATE TIME;TICKER;TRANSACTION-TYPE;PRICE;CURRENCY;VALUE;ID"
	echo "FILTER:"
	echo "[-a DATETIME]  - YYYY-MM-DD HH:MM:SS - function works only with transactions that are executed after DATETIME"
	echo "[-b DATETIME]  - YYYY-MM-DD HH:MM:SS - function works only with transactions that are executed before DATETIME"
	echo "[-t TICKER]    - function works only with transactions that include TICKER "
	echo "[-w WIDTH]     - sets width for creating graphs "
	echo "ORDER:"
	echo "[list-tick]    - function prints all tickers"
        echo "[profit]       - function prints profit. Profit is calculated as (sell transactions) - (buy transactions)"
	echo "[pos]          - function prints pos of given tickers. Pos is calculated as (price from last transaction)*((buy transaction values) - (sell transaction values))"
	echo "[last-price]   - function prints last price of given tickers"
	echo "[hist-ord]     - function creates histogram of number of transactions for each ticker "
	echo "[graph-pos]    - function creates histogram of pos function "
	echo ""
	exit 0
}

# ........................... function graphpos ................................
# function works with $LINES and gets all tickers and prices
# then function compares these tickers with tickers in $LINES and calculates SUM of all transactions
# function then calculates pos of given tickers and saves pos with tickers
# tickers are then sorted
# for each ticker 1000 pos function prints # or ! for values grater or lower than 0 
# .............................................................................
function graphpos ()
{
        TOKEN_PRICE=""
        NUM=0
        for item in $LINES
        do
                if [ $NUM = "0" ]; then
                        NUM=1
                else
                        if [[ $(grep -c -w $(cut -d';' -f2 <<<$item) <<<$TOKEN_PRICE) = 0 ]];then
                                TOKEN_PRICE="$(cut -d';' -f4 <<<$item) $(cut -d';' -f2 <<<$item) $TOKEN_PRICE"
                        fi
                        NUM=0
                fi
        done
        NUM=1
        PRICE=""
        SUM=0
        LEN=0
        declare -a TOKENS
        for item in $TOKEN_PRICE
        do
                if [ $NUM = "0" ];then
                        for line in $LINES
                        do
                                if [[ $item = $(cut -d';' -f2 <<<$line) ]];then
                                        case $(cut -d';' -f3 <<<$line) in
                                                "sell")
                                                        SUM=$(expr $SUM-$(cut -d';' -f6 <<<$line) | bc)
                                                        ;;
                                                "buy")
                                                        SUM=$(expr $SUM+$(cut -d';' -f6 <<<$line) | bc)
                                                        ;;
                                        esac
                                fi
                        done
                        TOKENS+=("$(cut -d';' -f2 <<<$item) $(expr $SUM*$PRICE | bc)")
                        NUM=1
                        SUM=0
                else
                        NUM=0
                        PRICE=$item
                fi
        done
	echo $TOTAL
        IFS=$'\n' TOKENS=($(sort <<<"${TOKENS[*]}")) ; unset IFS
        NUM="1"
	SUM=0
        for item in ${TOKENS[*]}
        do
                if [ $NUM = "1" ];then
                        SUM=$item
                        NUM="0"
                else
                        printf '%-10s: ' $SUM
			for i in `seq 1 $(expr $item/1000 | bc)`
			do
                        	printf '#'
			done
                        for i in `seq 1 $(expr $item/-1000 | bc)`
                        do
                                printf '!'
                        done
			echo ""
                        NUM="1"
                fi
        done
}

# ........................... function histord ................................
# function goes through all lines and finds tickers. Tickers are saved and sorted in $TOKEN
# function calculates number of transactions for each token and saves it in $COUNT
# this way first number in $COUNT is number of transactions of first ticker in $TOKEN
# function then prints '#' symbol for each transaction or it calculates how much of transactions does one '#' contain (based on width)
# function then prints out '#' for each ticker
# .............................................................................
function histord ()
{
	declare -a TOKEN
        NUM=0
        for line in $LINES
        do
                if [ $NUM = "0" ]; then
                        NUM=1
                else
                        if [[ $(grep -c -w $(cut -d';' -f2 <<<$line) <<<${TOKEN[*]}) = 0 ]];then
                                TOKEN+=($(cut -d';' -f2 <<<$line))
                        fi
                        NUM=0
                fi
        done
	IFS=$'\n' TOKEN=($(sort <<<"${TOKEN[*]}")) ; unset IFS
	declare -a COUNT
	SUM=0
	for token in ${TOKEN[*]}
	do
		NUM=0
		for line in $LINES	
        	do
                	if [ $NUM = "0" ]; then
                        	NUM=1
                	else
                        	if [[ $(cut -d';' -f2 <<<$line) = $token ]];then
                                	SUM=$(expr $SUM + 1)
                        	fi
                        	NUM=0
                	fi
       		done
		COUNT+=($SUM)
		SUM=0
	done
	case $WIDTH in
		"0")
			NUM=0
			for token in ${TOKEN[*]}
			do
				printf '%-10s: ' $token
				for i in `seq 1 ${COUNT[$NUM]}`
				do
					printf '#'
				done
				echo ""
				NUM=$(expr $NUM + 1)
			done
			;;
		*)
			MAX=0
			for num in ${COUNT[*]}
			do
				if [[ $num -gt $MAX ]];then
					MAX=$num
				fi
			done
			UNIT=$(bc <<< "scale=3; $MAX/$WIDTH" )
			NUM=0
                        for token in ${TOKEN[*]}
                        do
                                printf '%-10s: ' $token
                                for i in `seq 1 $(expr ${COUNT[$NUM]}/$UNIT | bc)`
                                do
                                        printf '#'
                                done
                                echo ""
                                NUM=$(expr $NUM + 1)
                        done
			;;
	esac
}

# ...................... function pos ..........................................
# function goes through and saves the last price of ticker
# function goes through all transactions and calculates sum of sell and buy transactions
# function calculates pos of each ticker
# function saves ticker with its pos
# function sorts tickers based on their pos
# .............................................................................
function pos ()
{
       	TOKEN_PRICE=""
        NUM=0
        for item in $LINES
        do
                if [ $NUM = "0" ]; then
                        NUM=1
                else
			if [[ $(grep -c -w $(cut -d';' -f2 <<<$item) <<<$TOKEN_PRICE) = 0 ]];then
                        	TOKEN_PRICE="$(cut -d';' -f4 <<<$item) $(cut -d';' -f2 <<<$item) $TOKEN_PRICE"
			fi
			NUM=0
                fi
        done
	NUM=1
	PRICE=""
	SUM=0
	LEN=0
	declare -a TOKENS
        for item in $TOKEN_PRICE
        do
		if [ $NUM = "0" ];then
			for line in $LINES
			do
				if [[ $item = $(cut -d';' -f2 <<<$line) ]];then
					case $(cut -d';' -f3 <<<$line) in
                                		"sell")
                                        		SUM=$(expr $SUM-$(cut -d';' -f6 <<<$line) | bc)
                                        		;;
                                		"buy")
                                        		SUM=$(expr $SUM+$(cut -d';' -f6 <<<$line) | bc)
                                        		;;
                        		esac					
				fi
			done
			TOTAL="$(expr $SUM*$PRICE | bc)"
		        if [[ ${#TOTAL} -gt $LEN ]];then
        	                LEN=${#TOTAL}
	                fi
			TOKENS+=("$(expr $SUM*$PRICE | bc) $(cut -d';' -f2 <<<$item)")
			NUM=1
			SUM=0
		else
			NUM=0
			PRICE=$item
		fi
        done
	IFS=$'\n' TOKENS=($(sort -r -g <<<"${TOKENS[*]}")) ; unset IFS
	NUM="1"
	SUM=0
	for item in ${TOKENS[*]}
	do
		if [ $NUM = "1" ];then
			SUM=$item
			NUM="0"
		else
			printf '%-10s: ' $item
               		printf '%'$LEN's \n' $SUM
			NUM="1"
		fi
	done
}
# ....................... function last-price ...................................
# function gets last transactions by reversing lines
# from reversed lines we get last lines for each ticker
# from reversed lines we get tickers
# function saves longest price
# based on these price , function prints out sorted, aligned tickers and their price
# ...............................................................................
function lastprice ()
{
	REVERSE_LINES=""
	LAST_LINES=""
	declare -a WRITTEN
        NUM=0
	for item in $LINES
	do
		if [ $NUM = "0" ]; then
			NUM=1
		else
			REVERSE_LINES="$REVERSE_LINES $item"
			NUM=0
		fi
	done
        for item in $REVERSE_LINES
        do
                if [[ $(grep -c -w $(cut -d';' -f2 <<<$item) <<<${WRITTEN[*]}) = 0 ]]; then
			LAST_LINES="$item $LAST_LINES"
			WRITTEN+=($(cut -d';' -f2 <<<$item))
                fi
        done
	LEN=0
	for item in $LAST_LINES
        do
		string=$(cut -d';' -f4 <<<$item)
                if [[ ${#string} > $LEN ]];then
			LEN=${#string}
		fi
        done
	IFS=$'\n' WRITTEN=($(sort <<<"${WRITTEN[*]}")) ; unset IFS
	for item in ${WRITTEN[*]}
	do
		for line in ${LAST_LINES}
		do
			if [[ $(cut -d';' -f2 <<<$line) = $item ]];then
				printf '%-10s: ' $item
				printf '%'$LEN's \n' $(cut -d';' -f4 <<<$line)
			fi
		done
	done
}

# ........................ function profit .......................................
# function works through all lines given by filters
# funnction adds/subtracts price*value to/from the variable SUM (depending on sell/buy)
# function prints SUM
# ................................................................................
function profit ()
{
	NUM=0
	SUM=0
	TOKEN=""
        for item in $LINES
        do
                if [ $NUM = "0" ]; then
                        NUM="1"
                else
			TOKEN=$(cut -d';' -f3 <<<$item)
			case $TOKEN in
				"sell")
					SUM=$(expr $SUM+$(cut -d';' -f4 <<<$item)\*$(cut -d';' -f6 <<<$item) | bc)
					;;
				"buy")
					SUM=$(expr $SUM-$(cut -d';' -f4 <<<$item)\*$(cut -d';' -f6 <<<$item) | bc)
					;;
			esac
                        NUM="0"
                fi
        done
	echo $SUM
}
# .................function list-tick ............................................
# function works with $LINES where all the lines filtered by FILTERS are located
# function gets tickers printed after first ";" 
# function comapres this word with words in $TICKERS
# if this word is not in TICKERS , then functions saves it in $TICKERS
# function sorts all tickers and prints them
# ................................................................................
function listtick ()
{
	NUM=0
	declare -a TICKERS	
	for item in $LINES
	do
		if [ $NUM = "0" ]; then
			NUM="1"
		else
			NUM="0"
			if [[ $(grep -c -w $(cut -d';' -f2 <<<$item) <<<${TICKERS[*]}) = 0 ]]; then
				TICKERS+=($(cut -d';' -f2 <<<$item))
			fi
		fi
	done
	IFS=$'\n' TICKERS=($(sort <<<"${TICKERS[*]}"))
	for i in ${TICKERS[*]}
	do
		echo $i
	done
}

# .............. function selecting ...............................
# function calls arguments which were given as arguments
# ................................................................
function selecting ()
{
	for item in "$@"
	do
		if [ $item = "list-tick" ]; then
			listtick
		fi
                if [ $item = "profit" ]; then
                        profit
                fi
                if [ $item = "last-price" ]; then
                        lastprice
                fi
                if [ $item = "pos" ]; then
                        pos
                fi
                if [ $item = "hist-ord" ]; then
                        histord
                fi
                if [ $item = "graph-pos" ]; then
                        graphpos
                fi
	done
}
# ...................... function ticker ...................
# function looks for argument '-t'
# when '-t' is found, then all lines containing ticker will be saved
# lines are saved in $LINES
# In $LINES date and rest of the line is separated, therefore we have to save date and print it later with correct line
# ........................................................
function tickering ()
{
	NEXT=0
	LINES_TMP=$LINES
	LINES=""
	TICKER=""
	for a in $ARGS
	do
		if [ $NEXT = 1 ]; then
			TICKER=$a
			EVEN=0
			DATE=""
			for line in $LINES_TMP
                        do
				if [ $EVEN = 0 ]; then
					DATE="$line"
					EVEN=1
				else
                                	if [[ $(cut -d';' -f2 <<<$line) = "$TICKER" ]]; then
                                        	LINES="$LINES $DATE $line"
                                	fi
					EVEN=0
				fi
                        done
                        NEXT=0
                fi

		if [ $a = '-t' ]; then
                	NEXT=1
		fi
	done
}
# ................ funciton datetime .........................
# function passes through all arguments
# once a "-a" or "-b" is found then function saves next 2 arguments - DATE and TIME
# once we have all argumetns we start going through all lines
# function first compares DATE in every odd iteration then it compares TIME in every even iteration
# functions works with 2 tokens - "-a" and "-b"
# for "-a" token function saves lines which have time greater then argument
# for "-b" token function saves lines which have time lesser then argument  
# ...........................................................
function datetime ()
{
        NEXT=0
	NEXT_2=0
	DATE=""
	TIME=""
	TOKEN=""
        for a in $ARGS
        do
                if [ $NEXT = 1 ]; then
                        DATE=$a
			NEXT=0
			NEXT_2=1
			continue
		fi
		if [ $NEXT_2 = 1 ]; then
                        EVEN=0
			EXE=0
                        TIME=$a
			EQ=0
			LAST_DATE=""
		        LINES_TMP=$LINES
		        LINES=""
                        for line in $LINES_TMP
                        do
                                if [ $EVEN = 0 ]; then 
					if [[ $DATE = $line ]];then
						EQ=1
					fi
					LAST_DATE="$line"
                                        case $TOKEN in
						"-a")
							if [[ $DATE < $line ]]; then
								LINES="$LINES $line "
								EXE=1
							fi
							;;
						"-b")
							if [[ $DATE > $line ]]; then
								LINES="$LINES $line "
								EXE=1
							fi
							;;
					esac
                                        EVEN=1
                                else 
					if [[ $EXE = 1 ]]; then
						LINES="$LINES $line "
					else
						case $TOKEN in
                                                	"-a")
                                                        	if [[ $TIME < $(cut -d';' -f1 <<<$line) && $EQ = 1 ]]; then
                                                                	LINES="$LINES $LAST_DATE $line "
                                             			fi
                                                        	;;
                                                	"-b")
                                                        	if [[ $TIME > $(cut -d';' -f1 <<<$line) && $EQ = 1 ]]; then
                                                                	LINES="$LINES $LAST_DATE $line "
                                                        	fi
                                                        	;;
                                        	esac
					fi
                                        EVEN=0
					EXE=0
					EQ=0
                                fi
                        done
			TOKEN=""
			NEXT_2=0
                fi
                if [[ $a = '-a' || $a = '-b' ]]; then
                        NEXT=1
			TOKEN="$a"
                fi
        done
}
# ................ function filtering ......................
# function launches every filter once (if filter is called)
# .........................................................
function filtering ()
{
	TICK_EXE=0
	DTIME_EXE=0
	NEXT=0
	for item in "$@"
	do
                if [[ $item = "-h" || $item = "--help" ]]; then
                        help
                fi
		if [[ $item = "-t" ]] && [[ $TICK_EXE != "1" ]]; then
			tickering
			TICK_EXE="1"
		fi
                if [[ $item = "-b" || $item = "-a" ]] && [[ $DTIME_EXE != "1" ]]; then
                        datetime
                        DTIME_EXE="1"
                fi
                if [ $NEXT = "1" ]; then
                        NEXT=0
                        WIDTH=$item
                fi
                if [ $item = "-w" ]; then
                        NEXT=1
                fi

	done
}
ARGS=""
FILES=""
LINES=""
WIDTH=0
# $FILES contains all files which we will be working with
# $ARGS contains all other arguments
# $LINES contains all lines from $FILES which we will filter later on
for i in "$@"
do
	if [[ $i = *".log" || $i = *".log.gz" ]]; then
		FILES="$i $FILES"
	else
		ARGS="$ARGS $i"
	fi
done
for item in $FILES
do
	if [[ $item = *".log" ]];then
		while read line; do
			LINES="$line $LINES"
		done < $item
	else
                while read line; do
                        LINES="$line $LINES"
                done <<< $(gunzip -c $item)

	fi
done
filtering $ARGS
selecting $ARGS
# function prints all lines if none arguments were given
NUM=0
if [[ $ARGS = "" ]];then
	for line in $LINES
	do
		if [[ $NUM = 0 ]];then
			NUM=1
			printf '%s ' $line
		else
			echo $line
			NUM=0
		fi
	done
fi
exit 0
