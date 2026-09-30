# -*- coding: utf-8 -*-
"""
Verify Qt static build artifacts under Output/Binaries/x86-static.
Checks:
  1) Every *.lib in lib/ is a valid static (COFF archive) library  -> file signature '!<arch>\n'
  2) No *.dll shared libraries exist anywhere under the install prefix
  3) Print representative library names + machine type (x86 expected)
"""
import struct
import sys
from pathlib import Path

ROOT = Path(r"D:\code\qt6_5_for_xp\Output\Binaries\x86-static")

ARCH_MAGIC = b"!<arch>\n"          # static library (COFF .lib) signature
PE_MAGIC = b"MZ"                    # PE (exe/dll) signature


def check_arch(path: Path) -> str:
    """Return 'static-lib (.lib archive)' or 'ARCHIVE-bad' after checking the archive header."""
    with open(path, "rb") as f:
        sig = f.read(8)
    if sig == ARCH_MAGIC:
        return "STATIC_LIB"
    if sig.startswith(PE_MAGIC):
        return "PE_IMAGE"
    return "UNKNOWN"

def main() -> int:
    if not ROOT.exists():
        print(f"[FATAL] install prefix not found: {ROOT}")
        return 1

    libdir = ROOT / "lib"
    lib_files = sorted(libdir.rglob("*.lib")) if libdir.exists() else []
    dll_files = list(ROOT.rglob("*.dll")) + list(ROOT.rglob("*.so"))
    pdb_files = list(ROOT.rglob("*.pdb"))
    so_files = list(ROOT.rglob("*.so"))

    print("=" * 78)
    print(f"Qt static build verification report")
    print(f"Install prefix : {ROOT}")
    print(f"lib dir exists : {libdir.exists()}")
    print(f"*.lib found    : {len(lib_files)}")
    print(f"*.dll found    : {len(dll_files)}")
    print(f"*.so found     : {len(so_files)}")
    print("=" * 78)

    bad = 0
    arch_libs = 0
    for p in lib_files:
        kind = check_arch(p)
        if kind != "STATIC_LIB":
            bad += 1
            print(f"[FAIL] {p.relative_to(ROOT)} -> {kind}")
        else:
            arch_libs += 1

    print(f"\nStatic-archive .lib valid : {arch_libs}/{len(lib_files)}")
    if bad:
        print(f"[FAIL] {bad} library(ies) are NOT static archives!")
        return 1

    if dll_files:
        print("[FAIL] Shared libraries (DLL/SO) present under install prefix:")
        for p in dll_files:
            print(f"       {p.relative_to(ROOT)}")
        return 1
    print("[ OK ] No .dll / .so shared libraries under install prefix")

    print("\nSample static libraries (name + size):")
    for p in lib_files[:12]:
        print(f"  {p.relative_to(ROOT)}  {p.stat().st_size/1024:.0f} KB")
    if len(lib_files) > 12:
        print(f"  ... and {len(lib_files)-12} more")

    # Print machine type of first lib (x86 -> 0x14C) by walking first member header
    if lib_files:
        p = lib_files[0]
        with open(p, "rb") as f:
            f.seek(len(ARCH_MAGIC))
            hdr = f.read(60)
        # member header: name(16) date(12) uid(6) gid(6) mode(8) size(10) "`\n"
        # then COFF header: Machine(2) NumberOfSections(2) ...
        fsize = -1
        try:
            fsize = int(hdr[48:58].decode().strip())
        except Exception:
            pass
        if fsize >= 2:
            with open(p, "rb") as f:
                f.seek(len(ARCH_MAGIC) + 60)
                coff = f.read(2)
            machine = struct.unpack("<H", coff)[0]
            mname = {0x14C: "x86 (i386)", 0x8664: "x64 (AMD64)", 0xAA64: "ARM64"}.get(machine, hex(machine))
            print(f"\nMachine type of first lib ({p.name}): {mname}")

    # show any .a files too (mingw style, not expected)
    if list(ROOT.rglob("*.a")):
        print("\n[INFO] .a files present (unexpected for MSVC build):",
              [str(x.relative_to(ROOT)) for x in ROOT.rglob("*.a")])

    print("\n[ PASS ] All artifacts are static libraries; no shared libraries found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())