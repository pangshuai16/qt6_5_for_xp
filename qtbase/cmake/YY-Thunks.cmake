#[[
  MIT License

  Copyright (C) 2023 by wangwenx190 (Yuhang Zhao)
  Copyright (C) 2026 qt6_5_for_xp contributors (ARM64 support)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]

# https://github.com/Chuyu-Team/YY-Thunks
#
# Architecture notes
# ------------------
# Upstream YY-Thunks ships per-arch thunk objects:
#   objs/x86/    objs/x64/    objs/arm64/
# and per-OS targets: WinXP, Vista, Win7, Win8, Win81, Win10.
#
# Windows on ARM64 starts at Windows 10 1709, so the only meaningful thunk
# target for arm64 is Win10 (there is no XP/Vista/Win7 ARM64 OS). Requesting
# WinXP for an arm64 build would look for a non-existent obj, and — before this
# guard existed — the arch was inferred from CMAKE_SIZEOF_VOID_P, which is 8 on
# ARM64 too, so the x64 obj got linked and the link failed with
#   LNK1112: module machine type 'x64' conflicts with target machine type 'ARM64'.
#
# If this repo vendors objs/arm64/YY_Thunks_for_Win10.obj, it is used
# automatically. If it is not vendored, the thunk layer is skipped: on Windows
# 10+ ARM64 every API Qt needs is present in the OS, so the layer is optional
# there (it is mandatory for the x86/x64 XP builds).

if(NOT MSVC OR DEFINED __YY_THUNKS_CMAKE_INCLUDE_GUARD)
    return()
endif()
set(__YY_THUNKS_CMAKE_INCLUDE_GUARD 1)

# --- Target architecture of the produced binaries -----------------------------
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64)$" OR CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64")
    set(__yy_thunks_arch arm64)
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(__yy_thunks_arch x64)
else()
    set(__yy_thunks_arch x86)
endif()

# --- Per-arch default thunk target OS ----------------------------------------
if(__yy_thunks_arch STREQUAL "arm64")
    # No XP/Vista/Win7/Win8 ARM64 exists; Win10 is the only valid target.
    if(NOT DEFINED YYTHUNKS_TARGET_OS
       OR YYTHUNKS_TARGET_OS STREQUAL "WinXP"
       OR YYTHUNKS_TARGET_OS STREQUAL "Vista"
       OR YYTHUNKS_TARGET_OS STREQUAL "Win7"
       OR YYTHUNKS_TARGET_OS STREQUAL "Win8")
        set(YYTHUNKS_TARGET_OS "Win10" CACHE STRING "Supported values: Win10 (arm64); Vista/WinXP/... (x86/x64)" FORCE)
    endif()
else()
    if(NOT DEFINED YYTHUNKS_TARGET_OS)
        set(YYTHUNKS_TARGET_OS "Vista" CACHE STRING "Supported values: Vista, WinXP" FORCE)
    endif()
endif()

# --- Locate the YY-Thunks installation ---------------------------------------
set(__yy_thunks_dir)
if(DEFINED ENV{YYTHUNKS_INSTALL_DIR} AND EXISTS "$ENV{YYTHUNKS_INSTALL_DIR}")
    set(__yy_thunks_dir "$ENV{YYTHUNKS_INSTALL_DIR}")
else()
    set(__yy_thunks_reg)
    cmake_host_system_information(RESULT __yy_thunks_reg
        QUERY WINDOWS_REGISTRY "HKCU/Code/YY-Thunks"
        VALUE "Root")
    if(__yy_thunks_reg AND EXISTS "${__yy_thunks_reg}")
        set(__yy_thunks_dir "${__yy_thunks_reg}")
    elseif(EXISTS "${CMAKE_CURRENT_LIST_DIR}/YY-Thunks")
        set(__yy_thunks_dir "${CMAKE_CURRENT_LIST_DIR}/YY-Thunks")
    elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/YY-Thunks")
        set(__yy_thunks_dir "${CMAKE_CURRENT_SOURCE_DIR}/YY-Thunks")
    elseif(EXISTS "${PROJECT_SOURCE_DIR}/YY-Thunks")
        set(__yy_thunks_dir "${PROJECT_SOURCE_DIR}/YY-Thunks")
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/YY-Thunks")
        set(__yy_thunks_dir "${CMAKE_SOURCE_DIR}/YY-Thunks")
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/../YY-Thunks")
        set(__yy_thunks_dir "${CMAKE_SOURCE_DIR}/../YY-Thunks")
    endif()
endif()

if(__yy_thunks_dir AND EXISTS "${__yy_thunks_dir}")
    set(__yy_thunks_obj "${__yy_thunks_dir}/objs/${__yy_thunks_arch}/YY_Thunks_for_${YYTHUNKS_TARGET_OS}.obj")
    if(EXISTS "${__yy_thunks_obj}")
        set(YYTHUNKS_FOUND TRUE CACHE BOOL "" FORCE)
        set(YYTHUNKS_INSTALL_DIR "${__yy_thunks_dir}" CACHE STRING "" FORCE)
        set(YYTHUNKS_OBJ_PATH "${__yy_thunks_obj}" CACHE STRING "" FORCE)
        add_link_options("${__yy_thunks_obj}")
        message("###################################################################################################")
        message("#                                                                                                 #")
        message("#           ██    ██ ██    ██       ████████ ██   ██ ██    ██ ███    ██ ██   ██ ███████           #")
        message("#            ██  ██   ██  ██           ██    ██   ██ ██    ██ ████   ██ ██  ██  ██                #")
        message("#             ████     ████   █████    ██    ███████ ██    ██ ██ ██  ██ █████   ███████           #")
        message("#              ██       ██             ██    ██   ██ ██    ██ ██  ██ ██ ██  ██       ██           #")
        message("#              ██       ██             ██    ██   ██  ██████  ██   ████ ██   ██ ███████           #")
        message("#                                                                                                 #")
        message("###################################################################################################")
        message("")
        message(" YY-Thunks install dir     :" ${__yy_thunks_dir})
        message(" YY-Thunks target platform :" ${YYTHUNKS_TARGET_OS})
        message(" YY-Thunks target arch     :" ${__yy_thunks_arch})
        message(" YY-Thunks obj file path   :" ${__yy_thunks_obj})
        message("")
    elseif(__yy_thunks_arch STREQUAL "arm64" AND YYTHUNKS_TARGET_OS STREQUAL "Win10")
        # Optional on Windows 10+ ARM64: the OS already provides every API Qt
        # needs. Vendoring objs/arm64/YY_Thunks_for_Win10.obj enables the layer.
        set(YYTHUNKS_FOUND FALSE CACHE BOOL "" FORCE)
        unset(YYTHUNKS_OBJ_PATH CACHE)
        message(STATUS "YY-Thunks: no arm64 obj at ${__yy_thunks_obj}; skipping "
                       "thunk layer (not required on Windows 10+ ARM64).")
    else()
        message(WARNING "YY-Thunks's obj file is missing: ${__yy_thunks_obj}")
    endif()
else()
    if(__yy_thunks_arch STREQUAL "arm64")
        set(YYTHUNKS_FOUND FALSE CACHE BOOL "" FORCE)
        message(STATUS "YY-Thunks: installation directory not found; skipping "
                       "thunk layer (not required on Windows 10+ ARM64).")
    else()
        message(WARNING "Can't locate the YY-Thunks installation directory!")
    endif()
endif()
