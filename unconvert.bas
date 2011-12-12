'' usage: unconvert infile.html [outfile.wakka]
'' (if outfile.wakka missing it outputs to screen)

function replace(byref s as string, byref oldtxt as const string, byref newtxt as const string = "", byval times as integer = 0) as integer
	'' Replace instances of oldtxt in s with newtxt
	dim as integer ret = 0
	dim as integer i = instr(s, oldtxt)
	while i > 0
		s = left(s, i-1) & newtxt & mid(s, i + len(oldtxt))
	ret += 1
	if ret = times then exit while
		i = instr(i+len(newtxt), s, oldtxt)
	wend
	return ret
end function

function tagreplace(byref s as string, byref oldtxt as const string, byref newtxt as const string = "") as integer
	'' Replace instances of <oldtxt> and </oldtxt> in s with newtxt
	return replace( s, "<" & oldtxt & ">", newtxt ) _
	     + replace( s, "</" & oldtxt & ">", newtxt )
end function

function q(byref txt as const string) as string
	'' Replace instances of \' with \"
	dim as string ret = txt
	replace( ret, "'", """" )
	return ret
end function

function unconvert(byref infile as const string, byref outfile as const string) as integer

	dim as string s, lines = ""
	dim as string origline1, origline2
	dim as integer pre = 0
	#ifdef __FB_WIN32__
	const NEWLINE = !"\r\n"
	#else
	const NEWLINE = !"\n"
	#endif

	if open(infile for input as #1) then return 1
	do until eof(1)

		line input #1, s

		'' Remove html/head/body tags
		tagreplace s, "html"
		tagreplace s, "head"
		tagreplace s, "body"

		'' Remove misceallaneous tags near start
		replace s, q("<div id='fb_body_wrapper'>")
		replace s, q("<div id='fb_tab'>")

		scope'replace s, q("<div id='fb_tab_l'>[keyword]</div>")
			var i1 = instr(s, q("<div id='fb_tab_l'>" ))
			if i1 then
				var i2 = instr(i1, s, "</div>")
				s = left(s, i1-1) & mid(s, i2 + len("</div>"))
			end if
		end scope

		replace s, q("<div id='fb_tab_r'>&nbsp;<img src='images/fblogo_mini.gif' /></div>")
		replace s, q("<div id='fb_pg_wrapper'>")
		replace s, q("<div id='fb_pg_body'>")

		replace s, q("<link rel='stylesheet' type='text/css' href='style.css'>")


		'' Title
		replace s, "<title>", q("{{fbdoc item='title' value='")
		replace s, q("</title>"), q("'}}----")

		'' Section headers (Eng)
		replace s, q("<div class='fb_sect_title'>Syntax</div>"), q("{{fbdoc item='syntax'}}")
		replace s, q("<div class='fb_sect_title'>usage</div>"), q("{{fbdoc item='usage'}}")
		replace s, q("<div class='fb_sect_title'>Parameters</div>"), q("{{fbdoc item='param'}}")
		replace s, q("<div class='fb_sect_title'>Return Value</div>"), q("{{fbdoc item='ret'}}")
		replace s, q("<div class='fb_sect_title'>Description</div>"), q("{{fbdoc item='desc'}}")
		replace s, q("<div class='fb_sect_title'>Example</div>"), q("{{fbdoc item='ex'}}")
		replace s, q("<div class='fb_sect_title'>Platform Differences</div>"), q("{{fbdoc item='target'}}")
		replace s, q("<div class='fb_sect_title'>Dialect Differences</div>"), q("{{fbdoc item='lang'}}")
		replace s, q("<div class='fb_sect_title'>Differences from QB</div>"), q("{{fbdoc item='diff'}}")
		replace s, q("<div class='fb_sect_title'>See also</div>"), q("{{fbdoc item='see'}}")

		'' Section headers (French)
		replace s, q("<div class='fb_sect_title'>Syntaxe</div>"), q("{{fbdoc item='syntax'}}")
		replace s, q("<div class='fb_sect_title'>Usage</div>"), q("{{fbdoc item='usage'}}")
		replace s, q("<div class='fb_sect_title'>Param&egrave;tres</div>"), q("{{fbdoc item='param'}}")
		replace s, q("<div class='fb_sect_title'>Return Value</div>"), q("{{fbdoc item='ret'}}")
		replace s, q("<div class='fb_sect_title'>Description</div>"), q("{{fbdoc item='desc'}}")
		replace s, q("<div class='fb_sect_title'>Exemple</div>"), q("{{fbdoc item='ex'}}")
		replace s, q("<div class='fb_sect_title'>Diff&eacute;rences de plate-forme</div>"), q("{{fbdoc item='target'}}")
		replace s, q("<div class='fb_sect_title'>Diff&eacute;rences de dialectes</div>"), q("{{fbdoc item='lang'}}")
		replace s, q("<div class='fb_sect_title'>Diff&eacute;rences de dialecte</div>"), q("{{fbdoc item='lang'}}")
		replace s, q("<div class='fb_sect_title'>Diff&eacute;rences avec QB</div>"), q("{{fbdoc item='diff'}}")
		replace s, q("<div class='fb_sect_title'>Voir aussi</div>"), q("{{fbdoc item='see'}}")

		'' Miscellaneous section titles
		'if instr(s, "<div class=") then print s
		if replace(s, q("<div class='fb_sect_title'>"), q("{{fbdoc item='section' value='")) then
			replace "</div>", q("'}}")
		end if

		replace s, q("<div class='fb_sect_cont'>")

		replace s, q("<div class='fb_indent'>"), !"\t\t"

		'' Code examples header/footer
		replace s, q("<tt><div class='freebasic'>"), ("%%(freebasic)" & NEWLINE)
		replace s, "</div></tt><br />", "%%<br />"

		'' Syntax highlighting in code examples
		replace s, q("<span class='com'>")
		replace s, q("<span class='key'>")
		replace s, q("<span class='oth'>")
		replace s, q("<span class='wrd'>")
		replace s, q("<span class='quo'>")
		replace s, q("<span class='num'>")
		replace s, q("<span class='def'>")
		replace s, "</span>"


		'' Formatting tags
		tagreplace s, "b", "**"
		tagreplace s, "i", "//"
		tagreplace s, "tt", "##"
		tagreplace s, "ul"
		replace s, "<li> ", !"\t- "

		'' Newline tags
		replace s, "</div>", NEWLINE
		replace s, "<br />", NEWLINE
		replace s, "<br \>", NEWLINE ''(bad emitter?)

		'' Wiki links
		if replace(s, q("<a href='"), "[[") then
			replace s, q(".html'>"), " "
			replace s, "</a>", "]]"
		end if

		'' <pre>
		if instr(s, "pre") then
			if instr(s, "</pre") then
				pre = 0
			elseif instr(s, "<pre") then
				pre = 1
			end if
			replace s, q("<pre class='fb_pre'>"), "%%"
			replace s, "</pre>", "%%"
		end if

		'' Tables
		'' note: columns= value left blank, must be filled in manually
		'' note2: escape characters are handled differently within tables
		if replace(s, q("<div class='fb_table'>"), q("{{table columns='' cellpadding='2' cells='")) then
			replace s, ";" '' remove semicolons from any escape chars - apparently that's how Wakka tables work
		end if
		replace s, "</tr></td></table>", q("'}}")
		tagreplace s, "tr"
		replace s, "<td>"
		replace s, "</td>", ";"

		'' Escapes
		replace s, "&nbsp;", " "
		replace s, "&amp;", "&"
		replace s, "&gt;", ">"
		replace s, "&lt;", "<"


		'' add to output lines
		lines &= rtrim(s, any !"\t ")
		if pre then lines &= NEWLINE

	loop
	close #1

	'' Output file
	if len(outfile) then

	if open(outfile for output as #1) then return 2
		print #1, lines
		close #1
	else
		print lines
	end if

	return 0

end function

function main() as integer
dim as string infile = command(1), outfile = command(2)
	'print "unconvert " & infile & " " & outfile
	return unconvert( infile, outfile )
end function

end main()
