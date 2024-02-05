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

::Put all filtered files in a folder named "Filtered(followed by Format)" 
if exist Filtered_%Format% rd /s /q Filtered_%Format%
mkdir Filtered_%Format%

::filter and save all .pcap files in the folder "Filtered(followed by Format)"
for /L %%N in (1 1 %FileCount%) do (
    set file="./Filtered_%Format%/Filtered_!file%%N!"
    tshark -n -r !file%%N! -w !file! %FilterCommand%
)

::Merge all filtered files in the "Filtered(followed by Format)" folder
cd ./Filtered_%Format%
mergecap *.pcap -w ..\Merged\Merged_%Format%.pcap

::delete temporary filtered files
cd ..\
rd /s /q Filtered_%Format%

::Debug text, safe to delete
echo Files filtered and merged!
::pause