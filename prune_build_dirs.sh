#!/bin/bash


# This script will decend down a directory structure starting with the directory identified by ROOT_DIRECTORY.
# It will delete Maven and Gradle build directories (target and build) in project directories. It identifies
# project directories by the pesence of the build configuration files "pom.xml" and "build.gradle".



declare -r ROOT_DIRECTORY=.                             # Directory to decend into look for Maven and Gradle build directories. Must be a full path!
declare -r INDICATOR_FILE_MAVEN="pom.xml"               # File indicating a Maven source directory
declare -r INDICATOR_FILE_GRADLE="build.gradle"         # File indicating a Gradle source directory
declare -r KILL_LIST_MAVEN="target"                     # Name of Maven build dir to delete
declare -r KILL_LIST_GRADLE="build"                     # Name of Gradle build dir to delete
declare -i PROJECT_TYPE_MAVEN=1                         # Bitwise indicator type for a Maven project direcotry
declare -i PROJECT_TYPE_GRADLE=2                        # Bitwise indicator type for a Gradle project directory




# ARGS:
#   1: Full path to a directory
#
# RETURN:
#   No direct return value. Mutates the global variable "project_types" with:
#      0:  Not a project directory
#      $PROJECT_TYPE_MAVEN:  Maven project directory
#      $PROJECT_TYPE_GRADLE:  Gradle project directory
#      $PROJECT_TYPE_MAVEN + $PROJECT_TYPE_GRADLE:  Maven and Grade project directory
#
# INTENT:
#   This method will identify directories that are the root of a Maven or Gradle project.
#   The determination is made based on the presence of one, or both, files identifed by the
#   variables INDICATOR_FILE_MAVEN and INDICATOR_FILE_GRADLE. The global variable "project_types"
#   will be mutated based on the type of directory as document above under "RETURN".
source_directory_types () {
	for dir_entry_name in $(ls "$1"); do
		local dir_entry="${1}/${dir_entry_name}"
		if [ -f "$dir_entry" ]; then
			if [ "$dir_entry_name" == "$INDICATOR_FILE_MAVEN" ]; then
				project_types=$((project_types + $PROJECT_TYPE_MAVEN))
				if [ $(( project_types ^ PROJECT_TYPE_MAVEN )) -gt 0 ]; then  # this optimization targets precisely two build systems, any more or less and this won't work!
					return
				fi
			elif [ "${dir_entry_name}" == "$INDICATOR_FILE_GRADLE" ]; then
				project_types=$((project_types + $PROJECT_TYPE_GRADLE))
				if [ $(( project_types ^ PROJECT_TYPE_GRADLE )) -gt 0 ]; then   # this optimization targets precisely two build systems, any more or less and this won't work!
					return
				fi
			fi
		fi
	done
}


# ARGS:
#   1: Relative path from the directory identified by ROOT_DIRECTORY.
#
# RETURN:
#   N/A: Nothing returned.
#
# INTENT:
#   Investigate the directory tree passed in as an argument. Descend through the
#   directory structure identifying directories housing Maven and/or Gradle projects.
#   Delete the ephemeral build directories for the Maven and Gradle systems identified
#   by the variables KILL_LIST_MAVEN and KILL_LIST_GRADLE.
#
#   Do not decend into the directories identified as Maven or Gradle projects (So projects
#   wihin projects will not be found (or cleaned).
prune_ephemeral_directories () {
	for file_name in $(ls "${ROOT_DIRECTORY}${1}"); do
		local file_path_relative="${1}/${file_name}"
		local file_path_full="${ROOT_DIRECTORY}${file_path_relative}"

		if [ ! -d "$file_path_full" ]; then continue; fi   # Optimization to skip non-directories. Will not follow symlinks as a result

		declare -i project_types=0
		source_directory_types "$file_path_full"
		if [ $project_types -ne 0 ]; then
			maven_target="${file_path_full}/${KILL_LIST_MAVEN}"
			gradle_target="${file_path_full}/${KILL_LIST_GRADLE}"
			if [ $PROJECT_TYPE_MAVEN -eq $(( project_types & PROJECT_TYPE_MAVEN )) -a  -d "${maven_target}" ]; then
				echo "KILLING: ${maven_target}"
				rm -r "${maven_target}"
			fi
			# NOT an elif so dual typed projects will get both build system cleaned
			if [ $PROJECT_TYPE_GRADLE -eq $(( project_types & PROJECT_TYPE_GRADLE )) -a -d "${gradle_target}" ]; then
				echo "KILLING: ${gradle_target}"
				rm -r "${gradle_target}"
			fi
		else
			# Recursive call to decend into non-project directories.
			prune_ephemeral_directories "${file_path_relative}"
		fi
	done
}


# Let's go ahead an call this a one line script...
prune_ephemeral_directories

