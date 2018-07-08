#=============================================================================#
# Author:    Konstantin Gredeskoul (kigster)
# Home:      https://github.com/kigster/arli-cmake
# License:   MIT
#
#=============================================================================#
# prepend
# [PUBLIC]
#
# prepend(var prefix)
#
#      var      - variable containing a list
#      prefix   - string to prepend to each list item
#
#=============================================================================#
function(prepend var prefix)
  SET(listVar "")
  FOREACH (f ${ARGN})
    LIST(APPEND listVar "${prefix}/${f}")
  ENDFOREACH (f)
  SET(${var} "${listVar}" PARENT_SCOPE)
endfunction(prepend)

#=============================================================================#
# arli_build_arduino_library
# [PUBLIC]
#
# build_library(LIB LIB_SOURCE_PATH)
#
#      LIB               - name of the library to build
#      LIB_SOURCE_PATH   - path to the top-level 'libraries' folder.
#
# Builds a library as a static .a library that can be linked by the main
# target.
#=============================================================================#

FUNCTION(arli_build_arduino_library LIB LIB_SOURCE_PATH)
  if (NOT DEFINED LIB_SOURCE_PATH)
    set(LIB_SOURCE_PATH ${ARDUINO_SDK_PATH}/libraries)
  endif ()

  set(${LIB}_RECURSE True)

  include_directories(${LIB_SOURCE_PATH} ${LIB_SOURCE_PATH}/utility ${LIB_SOURCE_PATH}/src)
  link_directories(${LIB_SOURCE_PATH})

  set(LIB_SOURCES $ENV{${LIB}_SOURCES})
  set(LIB_HEADERS $ENV{${LIB}_HEADERS})

  separate_arguments(LIB_SOURCES)
  separate_arguments(LIB_HEADERS)

  prepend(LIB_SOURCES ${LIB_SOURCE_PATH} ${LIB_SOURCES})
  prepend(LIB_HEADERS ${LIB_SOURCE_PATH} ${LIB_HEADERS})

  if (NOT DEFINED ${LIB}_ONLY_HEADER)
    if (EXISTS ${LIB_SOURCE_PATH}/${LIB}.cpp)
      list(APPEND LIB_SOURCES ${LIB_SOURCE_PATH}/${LIB}.cpp)
    elseif(EXISTS ${LIB_SOURCE_PATH}/src/${LIB}.cpp)
      list(APPEND LIB_SOURCES ${LIB_SOURCE_PATH}/src/${LIB}.cpp)
    endif()
  else()
    if (EXISTS ${LIB_SOURCE_PATH}/${LIB}.h)
      list(APPEND LIB_SOURCES ${LIB_SOURCE_PATH}/${LIB}.h)
    elseif(EXISTS ${LIB_SOURCE_PATH}/src/${LIB}.h)
      list(APPEND LIB_SOURCES ${LIB_SOURCE_PATH}/src/${LIB}.h)
    endif()
  endif()

  if (NOT LIB_SOURCES)
    set(LIB_SOURCES ${LIB_HEADERS})
  endif ()

  if(DEFINED $ENV{DEBUG})
    message(STATUS "generating library [${LIB}]")
    if (DEFINED ${${LIB}_DEPENDS_ON_LIBS})
      message(STATUS "${LIB} depends on ${${LIB}_DEPENDS_ON_LIBS}")
    endif()
  endif() 

  generate_arduino_library(${LIB}
    SRCS ${LIB_SOURCES}
    HDRS ${LIB_HEADERS}
    LIBS ${${LIB}_DEPENDS_ON_LIBS}
    BOARD_CPU ${BOARD_CPU}
    BOARD ${BOARD_NAME})
 
ENDFUNCTION(arli_build_arduino_library)

#=============================================================================#
# arli_detect_serial_device
# [PUBLIC]
#
# arli_detect_serial_device()
#
# Automatically detects a USB Arduino Serial port by doing ls on /dev
# Errors if more than 1 port was found, or if none were found.
# Set environment variable BOARD_DEVICE to override auto-detection.
#=============================================================================#
function(arli_detect_serial_device DEFAULT_DEVICE)
  if (DEFINED ENV{BOARD_DEVICE})
    message(STATUS "Using device from environment variable BOARD_DEVICE")
    set(BOARD_DEVICE $ENV{BOARD_DEVICE} PARENT_SCOPE)
  else ()
    message(STATUS "Auto-detecting board device from /dev")
    execute_process(
      COMMAND "/usr/bin/find" "-s" "/dev" "-name" "cu.*serial*"
      OUTPUT_VARIABLE BOARD_DEVICE
      ERROR_VARIABLE STDERR
    OUTPUT_STRIP_TRAILING_WHITESPACE)

    string(REGEX REPLACE "\n" ";" BOARD_DEVICE "${BOARD_DEVICE}")
    separate_arguments(BOARD_DEVICE)
    list(LENGTH BOARD_DEVICE NUM_DEVICES)
    message(STATUS "Total of ${NUM_DEVICES} devices have been found.")

    if (${NUM_DEVICES} EQUAL 0)
      set(BOARD_DEVICE ${DEFAULT_DEVICE} PARENT_SCOPE)
    elseif (${NUM_DEVICES} EQUAL 1)
      message(STATUS "Auto-detected 1 device ${BOARD_DEVICE}, continuing...")
      set(BOARD_DEVICE ${BOARD_DEVICE} PARENT_SCOPE)
    else ()
      message(FATAL_ERROR "Too many devices have been detected!
        Force device by setting 'BOARD_DEVICE' variable,
      or unplug one or more devices!")
    endif ()
  endif ()
endfunction(arli_detect_serial_device)

#=============================================================================#
# arli_detect_board_and_cpu
# [PUBLIC]
#
# arli_detect_board DEFAULT_BOARD_NAME DEFAULT_BOARD_CPU
#
# Checks if $ENV{BOARD_NAME} or $ENV{BOARD_CPU} are set in the ENV and if
# so use the environment values; otherwise use the defaults.
#
#=============================================================================#
function(arli_detect_board DEFAULT_BOARD_NAME DEFAULT_BOARD_CPU)
  arli_set_env_or_default(BOARD_NAME ${DEFAULT_BOARD_NAME})
  arli_set_env_or_default(BOARD_CPU ${DEFAULT_BOARD_CPU})

  set(BOARD_NAME ${BOARD_NAME} PARENT_SCOPE)
  set(BOARD_CPU ${BOARD_CPU} PARENT_SCOPE)
endfunction(arli_detect_board)

#=============================================================================#
# arli_set_env_or_default
# [PUBLIC]
#
# arli_detect_board DEFAULT_BOARD_NAME DEFAULT_BOARD_CPU
#
# Checks if $ENV{BOARD_NAME} or $ENV{BOARD_CPU} are set in the ENV and if
# so use the environment values; otherwise use the defaults.
#
#=============================================================================#
function(arli_set_env_or_default OUTPUT_VAR DEFAULT)
  if (DEFINED ENV{${OUTPUT_VAR}})
    message(STATUS "Setting ${OUTPUT_VAR} from Environment to $ENV{${OUTPUT_VAR}}")
    set(${OUTPUT_VAR} $ENV{${OUTPUT_VAR}} PARENT_SCOPE)
  else ()
    set(${OUTPUT_VAR} ${DEFAULT} PARENT_SCOPE)
    message(STATUS "Setting ${OUTPUT_VAR} to the default ${DEFAULT}")
  endif()
endfunction(arli_set_env_or_default)

#=============================================================================#
# arli_setup
# [PUBLIC]
#
# arli_setup SOURCE_FOLDER
#
# Runs bin/setup if arduino-cmake is not installed.
#=============================================================================#
function(arli_setup SOURCE_FOLDER)
  if (NOT EXISTS ${SOURCE_FOLDER}/cmake/ArduinoToolchain.cmake)
    message(STATUS "Setting up Project Dependencies...")
    execute_process(
      COMMAND "bash" "bin/setup"
      WORKING_DIRECTORY ${SOURCE_FOLDER}
      OUTPUT_VARIABLE ARLI_SETUP_STDOUT
      RESULT_VARIABLE ARLI_SETUP_RESULT
      ERROR_VARIABLE ARLI_SETUP_STDERR
    OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Setup Output:\n" ${ARLI_SETUP_STDOUT})
  endif()
endfunction(arli_setup)


#=============================================================================#
# arli_bundle
# [PRIVATE]
#
# arli_bundle SOURCE_FOLDER
#
# Runs arli bundle if Arlifile.cmake does not exist or
# Arlifile is newer.
#=============================================================================#
function(arli_bundle SOURCE_FOLDER)
  if (EXISTS "${SOURCE_FOLDER}/Arlifile")
    message(STATUS "running arli bundle")
    execute_process(
      COMMAND "arli" "bundle"
      WORKING_DIRECTORY ${SOURCE_FOLDER}
      OUTPUT_VARIABLE ARLI_BUNDLE_STDOUT
      RESULT_VARIABLE ARLI_BUNDLE_RESULT
      ERROR_VARIABLE ARLI_BUNDLE_STDERR
    OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Command Output: " ${ARLI_BUNDLE_STDOUT})
  endif()
endfunction(arli_bundle)

#=============================================================================#
# arli_bundle_command
# [PUBLIC]
#
# arli_bundle SOURCE_FOLDER
#
# Runs arli bundle if Arlifile.cmake does not exist or
# Arlifile is newer.
#=============================================================================#
function(arli_bundle_command SOURCE_FOLDER)
  if (NOT EXISTS "${SOURCE_FOLDER}/Arlifile.cmake")
    arli_bundle(${SOURCE_FOLDER})
  elseif("${SOURCE_FOLDER}/Arlifile" IS_NEWER_THAN "${SOURCE_FOLDER}/Arlifile.cmake")
    arli_bundle(${SOURCE_FOLDER})
  endif()

  if (NOT EXISTS "${SOURCE_FOLDER}/Arlifile.cmake")
    message(FATAL_ERROR
      "Unable to generate Arlifile.cmake in ${SOURCE_FOLDER}
       Please check that you have a recent ruby installed
       and that you installed 'arli' gem by running
      'gem install arli'. If in doubt, run bin/setup!"
    )
  endif()
endfunction(arli_bundle_command)


#=============================================================================#
# arli_build_all_libraries
# [PUBLIC]
#
# arli_build_all_libraries
#
# Builds all libraries.
#=============================================================================#
function(arli_build_all_libraries)
  set(ARDUINO_SDK_HARDWARE_LIBRARY_PATH "${ARDUINO_SDK_PATH}/hardware/arduino/avr/libraries")
  set(ARDUINO_SDK_LIBRARY_PATH "${ARDUINO_SDK_PATH}/libraries")
  set(ARDUINO_CUSTOM_LIBRARY_PATH "${ARLI_CUSTOM_LIBS_PATH}")

  set(ENV{Wire_HEADERS} utility/twi.h)
  set(ENV{Wire_SOURCES} utility/twi.c)

  FOREACH(LIB ${ARLI_CUSTOM_LIBS})
    arli_build_arduino_library(${LIB} "${ARDUINO_CUSTOM_LIBRARY_PATH}/${LIB}")
  ENDFOREACH(LIB)

  FOREACH(LIB ${ARLI_ARDUINO_HARDWARE_LIBS})
    arli_build_arduino_library(${LIB} "${ARDUINO_SDK_HARDWARE_LIBRARY_PATH}/${LIB}/src")
  ENDFOREACH(LIB)

  FOREACH(LIB ${ARLI_ARDUINO_LIBS})
    arli_build_arduino_library(${LIB} "${ARDUINO_SDK_LIBRARY_PATH}/${LIB}/src")
  ENDFOREACH(LIB)


endfunction(arli_build_all_libraries)
