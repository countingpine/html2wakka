const NEWLINE = !"\r\n"

sub lineinput(byval fn as integer, byref s as string)

#if 0
	dim as ubyte c
	dim as string r = ""

	do until eof(fn) orelse right(s, 1) = !"\n"
		get #fn, , c
		r &= chr(c)
	loop

	s = r
#else
	line input #fn, s
#endif

end sub

function getfile(byref fname as const string) as string
	if open(fname for binary as #1) <> 0 then return ""
	dim as string s = space(lof(1))
	get #1, 1, s
	close #1
	return s
end function

function fixup(byref convfile as const string, byref origfile as const string, byref outfile as const string) as integer

	#define STRIPINDENT(s) ltrim(s, any !"\t ")
	#define ISBLANKLINE(s) (len(s) = 0 orelse len(STRIPINDENT(s)) = 0)
	#define INDENT(s) left(s, len(s) - len(STRIPINDENT(s)) )

	dim as string lines = "", lines2
	dim as string l1 = "", l2 = ""

	if open(origfile for input as #1) <> 0 then
		return 1
	end if

	if open(convfile for input as #2) <> 0 then
		return 2
	end if

	do until eof(1)

		lineinput 1, l1
		while ISBLANKLINE(l2)
			if eof(2) then l2 = l1: exit while
			lineinput 2, l2
		wend

		if ISBLANKLINE(l1) then
			lines &= l1
		else
			l2 = INDENT(l1) & STRIPINDENT(l2)
			if lcase(l2) = lcase(l1) orelse l2 = "%%(freebasic)" then
				l2 = l1
			end if
			lines &= l2
			l2 = ""
		end if

		lines &= NEWLINE

	loop

	close #1, #2

	lines = rtrim(lines, any !" \t\r\n")
	lines2 = getfile(origfile)
	lines &= right(lines2, len(lines2) - len(rtrim(lines2, any !" \t\r\n" & chr(0))))

	if len(outfile) then
		open outfile for output as #1
		print #1, lines;
		close #1
	else
		print lines;
	end if

	return 0

end function

function main() as integer
	dim as string convfile = command(1), origfile = command(2), outfile = command(3)

	if origfile = "" then
		var ppath = instrrev(convfile, any "/\")
		origfile = left(convfile, ppath) & "../cache/"
		
		#if 0
			var pext = instrrev(convfile, ".")
			if pext = 0 then 
				origfile &= mid(convfile, ppath+1) & ".wakka"
			else
				origfile &= mid(convfile, ppath+1, pext-(ppath+1)) & ".wakka"
			end if
		#else
			origfile &= mid(convfile, ppath+1)
		#endif
	end if

	'print "fixup " & convfile & " " & origfile
	return fixup(convfile, origfile, outfile)

end function

end main()

