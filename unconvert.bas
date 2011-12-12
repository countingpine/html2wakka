'' usage: unconvert infile.html [outfile.wakka]
'' (if outfile.wakka missing it outputs to screen)

sub replace(byref s as string, byref oldtxt as const string, byref newtxt as const string = "")
	'' Replace instances of oldtxt in s with newtxt
	dim as integer i = instr(s, oldtxt)
	while i > 0
		s = left(s, i-1) & newtxt & mid(s, i + len(oldtxt))
		i = instr(i+len(newtxt), s, oldtxt)
	wend
end sub

sub tagreplace(byref s as string, byref oldtxt as const string, byref newtxt as const string = "")
	'' Replace instances of <oldtxt> and </oldtxt> in s with newtxt
	replace( s, "<" & oldtxt & ">", newtxt )
	replace( s, "</" & oldtxt & ">", newtxt )
end sub

function q(byref txt as const string) as string
	'' Replace instances of \' with \"
	dim as string ret = txt
	replace( ret, "'", """" )
	return ret
end function

sub unconvert(byref infile as const string, byref outfile as const string)

	dim as string s, lines = ""
	dim as string origline1, origline2
	const NEWLINE = !"\r\n"

	open infile for input as #1
	do until eof(1)

		line input #1, s

		'' html/head/body tags
		tagreplace s, "html"
		tagreplace s, "head"
		tagreplace s, "body"

		'' Misceallaneous tags near start
		replace s, q("<div id='fb_body_wrapper'>")
		replace s, q("<div id='fb_tab'>")

		scope'replace s, q("<div id='fb_tab_l'>[keyword]</div>")
			var i1 = instr(s, q("<div id='fb_tab_l'>" ))
			var i2 = instr(i1, s, "</div>")
			if i1 then s = left(s, i1-1) & mid(s, i2 + len("</div>"))
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
		replace s, q("<div class='fb_sect_title'>Diff&eacute;rences avec QB</div>"), q("{{fbdoc item='diff'}}")
		replace s, q("<div class='fb_sect_title'>Voir aussi</div>"), q("{{fbdoc item='see'}}")

		replace s, q("<div class='fb_sect_cont'>")

		replace s, q("<div class='fb_indent'>"), !"\t\t"

		'' Code examples header/footer
		replace s, q("<tt><div class='freebasic'>"), "%%(freebasic)"
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
		if instr(s, q("<a href='")) then
			replace s, q("<a href='"), "[["
			replace s, q(".html'>"), " "
			replace s, "</a>", "]]"
		end if


		'' Escapes
		replace s, "&nbsp;", " "
		replace s, "&amp;", "&"
		replace s, "&gt;", ">"
		replace s, "&lt;", "<"


		lines &= rtrim(s, any !"\t ")

	loop
	close #1

		'' Output file
	if len(outfile) then
		open outfile for output as #1: close #1
		open outfile for binary as #1
			put #1, 1, lines
		close #1
	else
		print lines
	end if

end sub

dim as string infile = command(1), outfile = command(2)
unconvert( infile, outfile )
