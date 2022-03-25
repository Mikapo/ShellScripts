#!/bin/bash

SyncDir=Sync
ConfigFile=Sync/Config.ini
CacheFile=Sync/Cache.txt
ScriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function Setup()
{
	if [ ! -d $SyncDir ]; then
		mkdir $SyncDir
		echo "Sync folder created"
	fi

	if [ ! -f $ConfigFile ]; then
		touch $ConfigFile
		echo "SyncedFolder=" >> $ConfigFile
		echo "SyncInterval=20" >> $ConfigFile
		echo "Config file created"
	fi

	if [ ! -f $CacheFile ]; then
		touch $CacheFile
		echo "LastCheckTime=0" > $CacheFile
		echo "Cache file created"
	fi
	
	source "$ScriptDir/$ConfigFile"
	source "$ScriptDir/$CacheFile"

	local Succeeded=$1
	eval $Succeeded=1
	
	if ["$SyncedFolder" = ""]; then
		echo "Error: SyncedFolder has not been set in $ConfigFile"
		eval $Succeeded=0
	fi

	if [ ! -d "$SyncedFolder" ]; then
  		echo "Error: Did not find folder in $SyncedFolder"
		eval $Succeeded=0
	fi
}

function UpdateFile()
{
	local SourceFilePath=$1
	local TargetFilePath="$ScriptDir"${SourceFilePath#"$SyncedFolder"}
	local TargetDirPath=${TargetFilePath%/*}

	if [ ! -f "$TargetFilePath" ]; then
		mkdir -p "$TargetDirPath" && touch "$TargetFilePath"
		cat "$SourceFilePath" > "$TargetFilePath"
		echo "$TargetFilePath was created"
	else
		local PreviouslyEdited=$(date -r "$SourceFilePath" "+%Y%m%d%H%M%S")
		if [ $PreviouslyEdited -gt $LastCheckTime ]; then
			cat "$SourceFilePath" > "$TargetFilePath"
			echo "$TargetFilePath was updated"
		fi
	fi
}

function UpdateFiles()
{
	local DirPath="$1"
	cd "$DirPath"
	
	local FullFile=""
	local First=0

	local Files=$(find . -type f)
	local Index=0
	local LastPrintedIndex=0

	for File in $Files; do
		local Prefix=${File:0:2}
		if [ "$Prefix" = "./" ]; then

			if [ $First = 0 ]; then First=1
			else
				if [ "$FullFile" = "" ]; then FullFile=" $File"; fi
				FullFile=${FullFile:3}
				UpdateFile "$DirPath/$FullFile"
				FullFile=""
			fi
		fi	
		FullFile+=" $File"

		if ((Index > LastPrintedIndex + 19)); then
			echo "$Index files checked"
			LastPrintedIndex=$Index
		fi

		Index=$(($Index + 1))
	done

	if [ "$FullFile" != "" ]; then 
		FullFile=${FullFile:3}
		UpdateFile "$DirPath/$FullFile" 
	fi
}

function UpdateCheckTime()
{
	local CurrentCheckTime=$(date "+%Y%m%d%H%M%S")
	LastCheckTime=$CurrentCheckTime
	echo "LastCheckTime=$CurrentCheckTime" > "$ScriptDir/$CacheFile"
}

function StartSync()
{
	local FirstLoop=0
	local Input=""
	while [ "$Input" != "Exit" ] && [ "$Input" != "exit" ]; do
		Sleep $SyncInterval
		echo "Checks for changes"
		UpdateFiles "$SyncedFolder"
		UpdateCheckTime
		echo "Check finished"
		read Input </dev/tty
	done
}

function Main()
{
	Setup SetupSucceded
	if [ $SetupSucceded = 1 ]; then
		echo "Started sync"
		StartSync
		cd $ScriptDir
		echo "Sync stopped"
	else
		echo "Error: Sync failed to setup"
	fi
}

Main



