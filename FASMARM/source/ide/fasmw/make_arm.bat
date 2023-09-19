@echo off
ren FASM.INC FASMx86.INC
ren FASMARM.INC FASM.INC
..\..\..\fasm fasmw.asm ..\..\..\FASMWARM.EXE
ren FASM.INC FASMARM.INC
ren FASMx86.INC FASM.INC
