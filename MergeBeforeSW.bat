@echo off
setlocal enableDelayedExpansion

::Get LocalDateTime
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%_%ldt:~8,2%-%ldt:~10,2%-%ldt:~12,2%
set date=%ldt:~0,4%-%ldt:~5,2%-%ldt:~8,2%
set time=%ldt:~11,2%-%ldt:~14,2%-%ldt:~17,2%

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::Change directory to the desired folder
cd ./"DDoS-SW-B"

::Filter command
set FilterCommand="ip.addr == 8.8.8.8"

::Change filename format (appends "Format" at the end of the filename)
::"ldt" for date + time, "date" for date, "time" for time
set Format="%ldt%"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::Create a "Merged" folder if it does not already exist
if not exist Merged mkdir Merged

::Get and store the filenames of all .pcap files in the folder
set FileCount=0
for /F %%F in ('dir *.pcap /b') do (
    set /a FileCount+=1
    set "File!FileCount!=%%F"
)

::Put all filtered files in a folder named "Filtered" 
if exist Filtered rd /s /q Filtered
mkdir Filtered

::filter and save all .pcap files in the folder "Filtered"
for /L %%N in (1 1 %FileCount%) do (
    set file="./Filtered/Filtered_!file%%N!"
    tshark -n -r !file%%N! -w !file! %FilterCommand%
)

::Merge all filtered files in the "Filtered" folder
cd ./Filtered
mergecap *.pcap -w ..\Merged\Merged_%Format%.pcap

::delete temporary filtered files
cd ..\
rd /s /q Filtered