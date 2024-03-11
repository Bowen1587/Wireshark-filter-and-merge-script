@echo off
setlocal enableDelayedExpansion

::Get LocalDateTime
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%%ldt:~4,2%%ldt:~6,2%_%ldt:~8,2%%ldt:~10,2%
set date=%ldt:~0,4%%ldt:~5,2%%ldt:~8,2%
set time=%ldt:~11,2%%ldt:~14,2%

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::Change directory to the desired folder
set FolderName="DDoS-SW-B"

::Filter command
set FilterCommand="ip.addr == 8.8.8.8"

::Specify where to start and end and filtering (merged filename example: Merged_20240304_1000--20240304_1020)
::Leave "Start" blank to Start from the oldest file, "End" for the latest file, leave both blank to filter all
set Start=20240304_1100
set End=

::This is the default format if "Start" and "End" is left empty
::"%ldt%" for date + time, "%date%" for date, "%time%" for time
set FilterAllFormat=%ldt%

::Set this with "yes" or "no" depending on if you want to auto-replace duplicate filenames
::default: no
set AutoReplace=no

::Set this with "yes" or "no" depending on if you want to let the script auto-correct *the naming of the merged file*
::default: yes
set AutoCorrectRange=no

::Path to TShark and Mergecap (you can also use "tshark" and "mergecap" if the enviornment variable is already set up)
set PathToTShark="C:\Program Files\Wireshark\tshark.exe"
set PathToMergecap="C:\Program Files\Wireshark\mergecap.exe"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::set Format to "FilterAllFormat" when both "Start" and "End" is left empty
if [%Start%]==[] (
    if [%End%]==[] (
        set Format=%FilterAllFormat%
        set FilterAll=1
    )
)

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
    goto :break
)
cd ./%FolderName%

::Create a "Merged" folder if it does not already exist
if not exist Merged mkdir Merged

::Put all filtered files in a folder named "Filtered" 
if exist Filtered rd /s /q Filtered
mkdir Filtered

::Skip "Start" and "End" variable checks when filtering all
if !FilterAll!==1 goto :FilterAllFiles

::Check if the specified "Start" time is valid
for /F %%i in ('dir *.pcap /b') do set LastFile=%%i
for /F %%F in ('dir *.pcap /b') do (
    set "FirstFile=%%F"
    goto :CheckFirstFile
)
:CheckFirstFile
if [%Start%]==[] (
    echo Setting "Start" as %FirstFile:~0,13%
    goto :SetFirstFile
)
if %STart% gtr %LastFile:~0,13% (
    echo The specified "Start" file is invalid (Larger than latest file^)
    goto :break
)
if %Start% geq %FirstFile:~0,13% goto :GotFirst
if %AutoCorrectRange%==no goto :GotFirst
echo Changed "Start" from %Start% to %FirstFile:~0,13%
:SetFirstFile
set Start=%FirstFile:~0,13%
:GotFirst

::Check if the specified "End" time is valid
if [%End%]==[] (
    echo Setting "End" as %LastFile:~0,13%
    goto :SetEndFile
)
if %End% lss %FirstFile:~0,13% (
    echo The specified "End" file is invalid (Lesser than oldest file^)
    goto :break
) 
if %End% leq %LastFile:~0,13% goto :GotLast
if %AutoCorrectRange%==no goto :GotLast
echo Changed "End" from %End% to %LastFile:~0,13%
:SetEndFile
set End=%LastFile:~0,13%
:GotLast

::Change filename format to "StartTime--EndTime"(appends "Format" at the end of the filename)
set Format=%Start%--%End%

::Preemptively check if the same merged file name exist
if exist Merged\Merged_%Format%.pcap (
    if %AutoReplace%==yes goto :Replace
    echo *WARNING* Merged_%Format:"=%.pcap already exist, continuing means to replace said file
    echo (control + c to terminate the script^)
    pause
:Replace
    echo Ready to replace Merged_%Format:"=%.pcap
)


::Get and store the filenames of all .pcap files in the folder
echo Filtering from %Start% to %End% :
set FileCount=0
for /F %%F in ('dir *.pcap /b') do (
    set /a FileCount+=1
    set "file!FileCount!=%%F"
)

::filter and save all .pcap files in the folder "Filtered"
for /L %%N in (1 1 %FileCount%) do (
    set HaventFiltered=1==1
    set FileDateTime=!file%%N:~0,13!
    if !FileDateTime! geq %Start% (
        if !FileDateTime! leq %End% (
            set file="./Filtered/Filtered_!file%%N!"
            echo Now filtering - !file%%N! ...
            %PathToTShark% -n -r !file%%N! -w !file! %FilterCommand%
        )
    )
)
goto :Merge

::filter and save all .pcap files in the folder "Filtered" when not specifying "Start" and "End"
:FilterAllFiles
set FileCountAll=0
for /F %%F in ('dir *.pcap /b') do (
    set /a FileCountAll+=1
    set "fileAll!FileCountAll!=%%F"
)
echo Filtering all pcap files in %FolderName%
for /L %%N in (1 1 %FileCountAll%) do (
    set fileAll="./Filtered/Filtered_!fileAll%%N!"
    echo Now filtering - !fileAll%%N! ...
    %PathToTShark% -n -r !fileAll%%N! -w !fileAll! %FilterCommand%
)

::Merge all filtered files in the "Filtered" folder
:Merge
cd ./Filtered
dir /a /b | findstr /r ".">NUL || goto :FolderEmpty
echo Merging filtered files as Merged_!Format! ...
%PathToMergecap% *.pcap -w ..\Merged\Merged_!Format!.pcap
goto :FilteringComplete
:FolderEmpty
echo There are no files to filter (Filter folder is empty^) 
goto :break

::delete temporary filtered files
:FilteringComplete
cd ..\
rd /s /q Filtered
echo -- Filtering completed --
pause
goto :eof

::break label to catch different kinds of errors
:break
echo -- Script terminated --
pause