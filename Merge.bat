@echo off
setlocal enableDelayedExpansion

::Get LocalDateTime
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%_%ldt:~8,2%-%ldt:~10,2%-%ldt:~12,2%
set date=%ldt:~0,4%-%ldt:~5,2%-%ldt:~8,2%
set time=%ldt:~11,2%-%ldt:~14,2%-%ldt:~17,2%

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::Change directory to the desired folder
set FolderName="DDoS-SW-B"

::Filter command
set FilterCommand="ip.addr == 8.8.8.8"

::Change filename format (appends "Format" at the end of the filename)
::"%ldt%" for date + time, "%date%" for date, "%time%" for time
set Format="%ldt%"

::Path to TShark and Mergecap (you can also use "tshark" and "mergecap" if the enviornment variable is already set up)
set PathToTShark="C:\Program Files\Wireshark\tshark.exe"
set PathToMergecap="C:\Program Files\Wireshark\mergecap.exe"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::Check if the path to tshark is correct
if %PathToTShark% neq "tshark" (
    if not exist %PathToTShark% (
        echo Error with the path to tshark
        goto :break
    )
)

::Check if the path to mergecap is correct
if %PathToMergecap% neq "mergecap" (
    if not exist %PathToMergecap% (
        echo Error with the path to mergecap
        goto :break
    )
)

::Check if the specified folder exist
if not exist %FolderName% (
    echo %FolderName% does not exist
    goto :break)
cd ./%FolderName%

::Create a "Merged" folder if it does not already exist
if not exist Merged mkdir Merged

::Preemptively check if the same merged file name exist
if exist Merged\Merged_%Format%.pcap (
    echo Merged_%Format:"=%.pcap already exist, please change the Format
    goto :break
)

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
    %PathToTShark% -n -r !file%%N! -w !file! %FilterCommand%
)

::Merge all filtered files in the "Filtered" folder
cd ./Filtered
%PathToMergecap% *.pcap -w ..\Merged\Merged_%Format%.pcap

::delete temporary filtered files
cd ..\
rd /s /q Filtered
goto :eof

::break label to catch different kinds of errors
:break
pause