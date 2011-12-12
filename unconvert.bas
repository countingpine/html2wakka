'' usage: unconvert infile.html [outfile.wakka]
'' (if outfile.wakka missing it outputs to screen)

function replace(byref s as string, byref oldtxt as const string, byref newtxt as const string = "", byval times as integer = 0) as integer
	'' Replace instances of oldtxt in s with newtxt
	dim as integer ret = 0
	assert(len(oldtxt))
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

function substring(byref s as const string, byval n1 as integer, byval n2 as integer) as string
	return mid(s, n1, n2-n1)
end function

function findbetween(byref s as const string, byref n1 as const string, byref n2 as const string, byref ret as string = "", byval keepn1n2 as integer = 0) as integer
	'' Find instance of n1+(...)+n2 in s, set ret equal to (...) or n1+(...)+n2 and return its position

	dim as integer p1start, p1end, p2start, p2end
	p1start = instr(s, n1)
	if p1start = 0 then return 0
	p1end = p1start + len(n1)

	p2start = instr(p1end, s, n2)
	if p2start = 0 then return 0
	p2end = p2start + len(n2)

	if keepn1n2 then
		ret = substring(s, p1start, p2end)
		return p1start
	else
		ret = substring(s, p1end, p2start)
		return p1end
	end if


end function

function findbetween3(byref s as const string, byref n1 as const string, byref n2 as const string, byref n3 as const string, byref ret1 as string = "", byref ret2 as string = "") as integer
	'' Find instance of n1+(...)+n2+(''')+n3 in s, set ret1/ret2 equal to (...)/(''') and return n1's position

	dim as integer p1start, p1end, p2start, p2end, p3start', p3end
	p1start = instr(s, n1)
	if p1start = 0 then return 0
	p1end = p1start + len(n1)

	p2start = instr(p1end, s, n2)
	if p2start = 0 then return 0
	p2end = p2start + len(n2)

	p3start = instr(p2end, s, n3)
	if p3start = 0 then return 0
	'p3end = p3start + len(n3)

	ret1 = substring(s, p1end, p2start)
	ret2 = substring(s, p2end, p3start)
	return p1start

end function

function replacebetween(byref s as string, byref n1 as const string, byref n2 as const string, byref rep as const string = "", byval keepn1n2 as integer = 0) as integer

	'' Replace n1+(...)+n2 in s with rep (or n1+rep+n2)

	dim as integer p1start, p1end, p2start, p2end
	p1start = instr(s, n1)
	if p1start = 0 then return 0
	p1end = p1start + len(n1)

	p2start = instr(p1end, s, n2)
	if p2start = 0 then return 0
	p2end = p2start + len(n2)

	if keepn1n2 then
		s = left(s, p1end-1) & rep & mid(s, p2start)
		return p1end
	else
		s = left(s, p1start-1) & rep & mid(s, p2end)
		return p1start
	end if

end function

function replacebetween3(byref s as string, byref n1 as const string, byref n2 as const string, byref n3 as const string, byref rep as string = "") as integer
	'' Replace n1+(...)+n2+(''')+n3 in s with rep

	dim as integer p1start, p1end, p2start, p2end, p3start, p3end
	p1start = instr(s, n1)
	if p1start = 0 then return 0
	p1end = p1start + len(n1)

	p2start = instr(p1end, s, n2)
	if p2start = 0 then return 0
	p2end = p2start + len(n2)

	p3start = instr(p2end, s, n3)
	if p2start = 0 then return 0
	p3end = p3start + len(n3)

	s = left(s, p1start-1) & rep & mid(s, p3end)
	return p1start

end function


function unconvert(byref infile as const string, byref outfile as const string) as integer

	dim as string s, lines = ""
	dim as string origline1, origline2
	dim as string middle, middle2

	dim as integer inpre = 0
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

		if findbetween(s, q("<div id='fb_tab_l'>"), "</div>") then
			replacebetween(s, q("<div id='fb_tab_l'>"), "</div>")
		end if

		replace s, q("<div id='fb_tab_r'>&nbsp;<img src='images/fblogo_mini.gif' /></div>")
		replace s, q("<div id='fb_pg_wrapper'>")
		replace s, q("<div id='fb_pg_body'>")

		replace s, q("<link rel='stylesheet' type='text/css' href='style.css'>")


		'' Title
		replace s, "<title>", q("{{fbdoc item='title' value='")
		replace s, q("</title>"), q("'}}----")

		'' Section headers (Eng)
		if findbetween(s, q("<div class='fb_sect_title'>"), "</div>", middle) then
			dim as string title
			select case middle
				case "Syntax", "Syntaxe"
					title = "syntax"
				case "Usage"
					title = "usage"
				case "Parameters", "Param&egrave;tres"
					title = "param"
				case "Return Value", "Valeur retourn&eacute;e"
					title = "ret"
				case "Description"
					title = "desc"
				case "Example", "Exemple"
					title = "ex"
				case "Platform Differences", "Diff&eacute;rences de plate-forme"
					title = "target"
				case "Dialect Differences", "Diff&eacute;rences de dialecte", "Diff&eacute;rences de dialectes"
					title = "lang"
				case "Differences from QB", "Diff&eacute;rences avec QB"
					title = "diff"
				case "See also", "Voir aussi"
					title = "see"
			end select
			if title = "" then
				title = q("{{fbdoc item='section' value='" & middle & "'}}")
			else
				title = q("{{fbdoc item='" & title & "'}}")
			end if
			replacebetween s, q("<div class='fb_sect_title'>"), "</div>", title
		end if

		replace s, q("<div class='fb_sect_cont'>")

		replace s, q("<div class='fb_indent'>"), !"\t\t"

		replace s, q("<div style='clear:both'>"), "::c::"

		'' Code examples header/footer
		replace s, q("<tt><div class='freebasic'>"), ("%%(freebasic)" & NEWLINE)
		replace s, "</div></tt><br />", "%%<br />"

		'' Syntax highlighting in code examples
		while findbetween3(s, "<span class=", ">", "</span>", middle, middle2)
			replacebetween3 s, "<span class=", ">", "</span>", middle2
		wend

		'' fbdoc links (do before <br \> processing)
		if findbetween3(s, q("<b><a href='"), q(".html'>"), q("</a></b><br \>"), middle, middle2) then
			replacebetween3 s, q("<b><a href='"), q(".html'>"), q("</a></b><br \>"), _
				q("=={{fbdoc item='keyword' value='") & middle & "|" & middle2 & q("'}}==") & NEWLINE
		end if

		'' fbdoc anchor links
		while findbetween3(s, q("<a href='#"), q("'>"), "</a>", middle, middle2)
			replacebetween3 s, q("<a href='#"), q("'>"), "</a>", _
				q("{{anchor name='") & middle & "|" & middle2 & q("'}}")
		wend

		'' fbdoc anchors (do before <b> processing)
		while findbetween3(s, q("<a name='"), q("'></a><b><u>"), "</u></b>", middle, middle2)
			replacebetween3 s, q("<a name='"), q("'></a><b><u>"), "</u></b>", _
				q("{{anchor name='") & middle & q("'}}") & _
				q("{{fbdoc item='section' value='") & middle2 & q("'}}")
		wend

		'' Wiki links
		while findbetween3(s, q("<a href='"), q(".html'>"), "</a>", middle, middle2)
			replacebetween3 s, q("<a href='"), q(".html'>"), "</a>", "[[" & middle & " " & middle2 & "]]"
		wend

		'' <pre>
		if instr(s, "pre") then
			if instr(s, "</pre") then
				inpre = 0
			elseif instr(s, "<pre") then
				inpre = 1
			end if
			replace s, q("<pre class='fb_pre'>"), "%%"
			replace s, "</pre>", "%%"
		end if

		'' Tables (all on one line)
		'' note: columns= value left blank, must be filled in manually
		'' note2: escape characters are handled differently within tables
		if replace(s, q("<div class='fb_table'>"), q("{{table columns='' cellpadding='2' cells='")) then
			replace s, ";" '' remove semicolons from any escape chars - apparently that's how Wakka tables work
			replace s, "</tr></td></table>", q("'}}")
			tagreplace s, "tr"
			replace s, "<td>"
			replace s, "</td>", ";"
		end if
		
		'' Tables (<<>>)
		replace s, q("<table class='fb_box'>"), "<<"
		replace s, "</div></td></tr></table>", ">>"
		replace s, "</div></td><td>", "<<>>"

		tagreplace s, "td"
		tagreplace s, "tr"


		'' Unprocessed newline tags
		replace s, "</div>", NEWLINE
		replace s, "<br />", NEWLINE
		replace s, "<br \>", NEWLINE ''(bad emitter?)


		'' Formatting tags
		tagreplace s, "b", "**"
		tagreplace s, "i", "//"
		tagreplace s, "tt", "##"
		'tagreplace s, "u", '?
		tagreplace s, "ul"
		replace s, "<li> ", !"\t- "


		'' Escapes
		replace s, "&nbsp;", " "
		replace s, "&amp;", "&"
		replace s, "&gt;", ">"
		replace s, "&lt;", "<"


		'' add to output lines
		lines &= rtrim(s, any !"\t ")
		if inpre then lines &= NEWLINE

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
