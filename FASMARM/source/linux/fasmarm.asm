
; flat assembler interface for Linux
; Copyright (c) 1999-2016, Tomasz Grysztar.
; All rights reserved.

	format	ELF executable 3
	entry	start

stdin	= 0
stdout	= 1
stderr	= 2

segment readable executable

start:

	mov	[con_handle],stdout
	mov	[command_line],esp
	mov	ecx,[esp]
	lea	ebx,[esp+4+ecx*4+4]
	mov	[environment],ebx
	call	get_params
	pushf
	jc	show_logo
	cmp	[con_handle],stdout
	jnz	logo_done
      show_logo:
	mov	esi,_logo
	call	display_string
      logo_done:
	popf
	jc	information

	call	init_memory

	cmp	[con_handle],stdout
	jnz	memory_done
	mov	esi,_memory_prefix
	call	display_string
	mov	eax,[memory_end]
	sub	eax,[memory_start]
	add	eax,[additional_memory_end]
	sub	eax,[additional_memory]
	shr	eax,10
	call	display_number
	mov	esi,_memory_suffix
	call	display_string
      memory_done:

	mov	eax,78
	mov	ebx,buffer
	xor	ecx,ecx
	int	0x80
	mov	eax,dword [buffer]
	mov	ecx,1000
	mul	ecx
	mov	ebx,eax
	mov	eax,dword [buffer+4]
	div	ecx
	add	eax,ebx
	mov	[start_time],eax

	and	[preprocessing_done],0
	call	preprocessor
	or	[preprocessing_done],-1
	call	parser
	call	ARM_label_walker	;this line added for ARM
	call	assembler
	call	ARM_close_dwarf		;this line added for ARM
	call	formatter

	call	display_user_messages
	cmp	[con_handle],stdout
	jnz	details_done
	movzx	eax,[current_pass]
	inc	eax
	call	display_number
	mov	esi,_passes_suffix
	call	display_string
	mov	eax,78
	mov	ebx,buffer
	xor	ecx,ecx
	int	0x80
	mov	eax,dword [buffer]
	mov	ecx,1000
	mul	ecx
	mov	ebx,eax
	mov	eax,dword [buffer+4]
	div	ecx
	add	eax,ebx
	sub	eax,[start_time]
	jnc	time_ok
	add	eax,3600000
      time_ok:
	xor	edx,edx
	mov	ebx,100
	div	ebx
	or	eax,eax
	jz	display_bytes_count
	xor	edx,edx
	mov	ebx,10
	div	ebx
	push	edx
	call	display_number
	mov	dl,'.'
	call	display_character
	pop	eax
	call	display_number
	mov	esi,_seconds_suffix
	call	display_string
      display_bytes_count:
	mov	eax,[written_size]
	call	display_number
	mov	esi,_bytes_suffix
	call	display_string
      details_done:
	xor	al,al
	jmp	exit_program

information:
	mov	esi,_usage
	call	display_string
	mov	al,1
	jmp	exit_program

get_params:
	mov	ebx,[command_line]
	mov	[input_file],0
	mov	[output_file],0
	mov	[symbols_file],0
	mov	[memory_setting],0
	mov	[passes_limit],100
	mov	ecx,[ebx]
	add	ebx,8
	dec	ecx
	jz	bad_params
	mov	[definitions_pointer],predefinitions
      get_param:
	mov	esi,[ebx]
	mov	ax,[esi]
	cmp	ax,'-'
	jz	stdin_stdout
	cmp	al,'-'
	je	option_param
      stdin_stdout:
	cmp	[input_file],0
	jne	get_output_file
	mov	[input_file],esi
	jmp	next_param
      get_output_file:
	cmp	[output_file],0
	jne	bad_params
	mov	[output_file],esi
	jmp	next_param
      option_param:
	inc	esi
	lodsb
	cmp	al,'m'
	je	memory_option
	cmp	al,'M'
	je	memory_option
	cmp	al,'p'
	je	passes_option
	cmp	al,'P'
	je	passes_option
	cmp	al,'d'
	je	definition_option
	cmp	al,'D'
	je	definition_option
	cmp	al,'s'
	je	symbols_option
	cmp	al,'S'
	je	symbols_option
      bad_params:
	stc
	ret
      memory_option:
	cmp	byte [esi],0
	jne	get_memory_setting
	dec	ecx
	jz	bad_params
	add	ebx,4
	mov	esi,[ebx]
      get_memory_setting:
	call	get_option_value
	or	edx,edx
	jz	bad_params
	cmp	edx,1 shl (32-10)
	jae	bad_params
	mov	[memory_setting],edx
	jmp	next_param
      passes_option:
	cmp	byte [esi],0
	jne	get_passes_setting
	dec	ecx
	jz	bad_params
	add	ebx,4
	mov	esi,[ebx]
      get_passes_setting:
	call	get_option_value
	or	edx,edx
	jz	bad_params
	cmp	edx,10000h
	ja	bad_params
	mov	[passes_limit],dx
      next_param:
	add	ebx,4
	dec	ecx
	jnz	get_param
	mov	eax,[input_file]
	test	eax,eax
	je	bad_params
	mov	ecx,[output_file]
	cmp	word[eax],'-'
	jnz	output_file_okay
	test	ecx,ecx
	jnz	check_con_handle
	mov	[output_file],eax
	mov	ecx,eax
      output_file_okay:
	test	ecx,ecx
	jz	con_handle_okay
      check_con_handle:
	cmp	word[ecx],'-'
	jnz	con_handle_okay
	mov	[con_handle],stderr
      con_handle_okay:
	mov	eax,[definitions_pointer]
	mov	byte [eax],0
	mov	[initial_definitions],predefinitions
	clc
	ret
      definition_option:
	cmp	byte [esi],0
	jne	get_definition
	dec	ecx
	jz	bad_params
	add	ebx,4
	mov	esi,[ebx]
      get_definition:
	push	edi
	mov	edi,[definitions_pointer]
	call	convert_definition_option
	mov	[definitions_pointer],edi
	pop	edi
	jc	bad_params
	jmp	next_param
      symbols_option:
	cmp	byte [esi],0
	jne	get_symbols_setting
	dec	ecx
	jz	bad_params
	add	ebx,4
	mov	esi,[ebx]
      get_symbols_setting:
	mov	[symbols_file],esi
	jmp	next_param
      get_option_value:
	xor	eax,eax
	mov	edx,eax
      get_option_digit:
	lodsb
	cmp	al,20h
	je	option_value_ok
	or	al,al
	jz	option_value_ok
	sub	al,30h
	jc	invalid_option_value
	cmp	al,9
	ja	invalid_option_value
	imul	edx,10
	jo	invalid_option_value
	add	edx,eax
	jc	invalid_option_value
	jmp	get_option_digit
      option_value_ok:
	dec	esi
	clc
	ret
      invalid_option_value:
	stc
	ret
      convert_definition_option:
	mov	edx,edi
	cmp	edi,predefinitions+1000h
	jae	bad_definition_option
	xor	al,al
	stosb
      copy_definition_name:
	lodsb
	cmp	al,'='
	je	copy_definition_value
	cmp	al,20h
	je	bad_definition_option
	or	al,al
	jz	bad_definition_option
	cmp	edi,predefinitions+1000h
	jae	bad_definition_option
	stosb
	inc	byte [edx]
	jnz	copy_definition_name
      bad_definition_option:
	stc
	ret
      copy_definition_value:
	lodsb
	cmp	al,20h
	je	definition_value_end
	or	al,al
	jz	definition_value_end
	cmp	edi,predefinitions+1000h
	jae	bad_definition_option
	stosb
	jmp	copy_definition_value
      definition_value_end:
	dec	esi
	cmp	edi,predefinitions+1000h
	jae	bad_definition_option
	xor	al,al
	stosb
	clc
	ret

open_stdin:
	cmp	word[edx],'-'
	jnz	adapt_path
	mov	ebx,stdin
	pop	eax ebp edi esi
	clc
	ret

open_stdout:
	cmp	word[edx],'-'
	jnz	adapt_path
	mov	ebx,stdout
	pop	eax edx ebp edi esi
	clc
	ret

ARM_preprocess_file:
	push	[memory_end]
	push	esi
	;ebx = file handle
	;edi = start of free memory
	push	edi
	mov	edx,edi		; destination
      keep_reading:
	mov	ecx,[memory_end]
	dec	ecx
	sub	ecx,edx		; memory buffer size
	jbe	out_of_memory
	call	read
	add	edx,eax
	test	eax,eax
	jnz	keep_reading
	lea	esi,[edx-1]
	sub	edx,edi		; input length
	mov	ecx,edx
	mov	edi,[memory_end]
	sub	edi,2
	mov	byte [edi+1],1Ah
	std
	rep	movs byte [edi],[esi]
	cld
	inc	edi
	mov	[memory_end],edi
	mov	esi,edi
	pop	edi
	call	close
	pop	edx
	xor	ecx,ecx
	mov	ebx,esi
	jmp	preprocess_source

include 'system.inc'

include '..\version.inc'

include '..\errors.inc'
include '..\symbdump.inc'
include '..\preproce.inc'
include '..\parser.inc'
include '..\exprpars.inc'
include '..\exprcalc.inc'
include '..\assemble.inc'
include '..\formats.inc'
include '..\armv8.inc'

;patches to enable "-" to read/write using stdin/stdout

patch open, call adapt_path, call open_stdin, 3
patch create, call adapt_path, call open_stdout, 4
patch read, <<cmp eax,ecx>>, <<cmp eax,eax>>, 23
patch predefinitions_ok, call preprocess_file, call ARM_preprocess_file, 25
patch copy_preprocessed_path, call preprocess_file, call ARM_preprocess_file, 28

;patch to fix bug with lseek error detection

patch lseek, <<cmp eax,-1>,<je file_error>,<clc>>, <<cmp eax,-4095>,<cmc>>, 13

include '..\armtable.inc'
include '..\messages.inc'

_copyright db	'Copyright (c) 2005-2023, revolution',0Ah,\
		'Some portions copyright (c) 1999-2016, Tomasz Grysztar',0Ah,0

_logo db 'flat assembler for ARM  version ',ARM_VERSION_STRING,' (built on fasm ',VERSION_STRING,')',0
_usage db 0xA
       db 'usage: fasmarm <source> [output]',0xA
       db 'optional settings:',0xA
       db ' -m <limit>         set the limit in kilobytes for the available memory',0Ah
       db ' -p <limit>         set the maximum allowed number of passes',0Ah
       db ' -d <name>=<value>  define symbolic variable',0Ah
       db ' -s <file>          dump symbolic information for debugging',0Ah
       db 0
_memory_prefix db '  (',0
_memory_suffix db ' kilobytes memory)',0xA,0
_passes_suffix db ' passes, ',0
_seconds_suffix db ' seconds, ',0
_bytes_suffix db ' bytes.',0xA,0

segment readable writeable

align 4

include '..\variable.inc'

command_line dd ?
memory_setting dd ?
definitions_pointer dd ?
environment dd ?
timestamp dq ?
start_time dd ?
con_handle dd ?
displayed_count dd ?
last_displayed db ?
character db ?
preprocessing_done db ?

predefinitions rb 1000h
buffer rb 1000h
