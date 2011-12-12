#include "file.bi"
dim as string f1, f2, f3, f4
dim as string nm
dim params as string, r as integer

f1 = dir("*.html")
do while len(f1)

	nm = left(f1, instrrev(f1, ".")-1)
	print nm

	f2 = nm & ".wakka"
	f3 = "../cache/" & nm & ".wakka.fixup"
	f4 = "../cache/" & nm & ".wakka"

	if fileexists(f4) then

		if 1 or not fileexists(f2) then
			params = f1 & " " & f2
			r = exec( "unconvert", params )
			if r then
				print "unconvert (&) failed: &"; params; r
				sleep
				'end 1
			end if
		end if
		if 1 or not fileexists(f3) then
			params = f2 & " " & f4 & " " & f3
			r = exec( "fixup", params )
			if r then
				print using "fixup (&) failed: &"; params; r
				sleep
				'end 2
			end if
		end if
	end if

	f1 = dir()
loop
