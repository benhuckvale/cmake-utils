##
# Function: tabulate_variables
#
# This CMake function takes a list of variable names as arguments and prints them in a tabulated
# format, aligning the variable values for easy readability.
#
# The padding length for alignment is dynamically calculated based on the
# longest variable name provided. Optionally, you can specify a title to be
# displayed above the list of variables.
#
# Usage:
#   tabulate_variables([TITLE title_string] VAR1 VAR2 VAR3 ...)
#
# Parameters:
#   TITLE title_string (optional) - A title string to be displayed above the list of variables.
#   VAR1, VAR2, VAR3, ... - Variable names to be tabulated.
#
# Example:
#   set(CMAKE_VERSION "3.25.2")
#   set(CMAKE_BUILD_TYPE "Release")
#   set(CMAKE_GENERATOR "Unix Makefiles")
#
#   tabulate_variables(TITLE "CMake Variables:" CMAKE_VERSION CMAKE_BUILD_TYPE CMAKE_GENERATOR)
#
# This will produce output similar to the following:
#   CMake Variables:
#      CMAKE_VERSION = 3.25.2
#   CMAKE_BUILD_TYPE = Release
#    CMAKE_GENERATOR = Unix Makefiles
#
# The padding for the variable names is adjusted based on the longest variable name provided.
#
# Script Mode:
#
# When run in script mode with `cmake -P`, this module, as a script, will call
# the tabulate_variables function so as to display important variables from a
# likely nearby CMakeCache.txt file if it exists.
##
function(tabulate_variables)
    set(has_title FALSE)
    if (ARGV0 STREQUAL "TITLE")
        set(has_title TRUE)
        list(GET ARGV 1 title)
        list(SUBLIST ARGV 2 -1 var_names)
    else()
        list(SUBLIST ARGV 0 -1 var_names)
    endif()

    set(max_var_length 0)

    # Find the length of the longest variable name
    foreach(var ${var_names})
        string(LENGTH "${var}" var_length)
        if (var_length GREATER max_var_length)
            set(max_var_length ${var_length})
        endif()
    endforeach()
    # Apply minimum length
    if (max_var_length LESS 30)
        set(max_var_length 30)
    endif()

    set(output "")

    if (has_title)
        string(APPEND output "${title}\n")
    endif()

    foreach(var ${var_names})
        string(LENGTH "${var}" var_length)
        math(EXPR padding_length "${max_var_length} - ${var_length}")
        string(REPEAT " " ${padding_length} padding)
        string(APPEND output "  ${padding}${var} = ${${var}}\n")
    endforeach()
    message(STATUS "${output}")
endfunction()

if (CMAKE_SCRIPT_MODE_FILE AND NOT CMAKE_PARENT_LIST_FILE)
    get_filename_component(SCRIPT_NAME ${CMAKE_SCRIPT_MODE_FILE} NAME_WE)
    set(title "${SCRIPT_NAME} running in script mode - displaying important CMake variables")

    # Edit this list as needed
    set(important_variables
        CMAKE_VERSION
        CMAKE_BUILD_TYPE
        CMAKE_GENERATOR
        CMAKE_BINARY_DIR
        CMAKE_C_COMPILER
        CMAKE_CXX_COMPILER
        CMAKE_MAKE_PROGRAM
    )

    # Try a few paths to find the nearby likely CMakeCache.txt
    foreach(try_path ${CMAKE_SOURCE_DIR}/build ${CMAKE_SOURCE_DIR})
      if (EXISTS "${try_path}")
          set(CMAKE_BINARY_DIR "${try_path}")
      endif()
      set(CANDIDATE_CACHE_FILE ${CMAKE_BINARY_DIR}/CMakeCache.txt)
      if (EXISTS "${CANDIDATE_CACHE_FILE}")
          # If found, read into a variable
          file(READ "${CANDIDATE_CACHE_FILE}" CMAKE_CACHE_CONTENT)
          set(title "${title} from cache file ${CANDIDATE_CACHE_FILE}")
          # Loop through and set important variables
          foreach(variable_name ${important_variables})
              string(REGEX MATCH ".*${variable_name}:(FILEPATH|STRING|PATH|BOOL|INTERNAL|STATIC)=([^\n]*)\n" _ "${CMAKE_CACHE_CONTENT}")
              if (CMAKE_MATCH_2)
                  set(${variable_name} "${CMAKE_MATCH_2}")
              endif()
          endforeach()
          break()
      endif()
    endforeach()

    tabulate_variables(TITLE "${title}" ${important_variables})
endif()
