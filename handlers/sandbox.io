registerHandler("sandbox", message(IoSandbox index))
registerHandler("sandbox/", message(IoSandbox redirectToIndex))

registerHandler("sandbox", message(IoSandbox plainCreate)) do(
    matches := method(p, request,
		p == path and request isPost and request contentType == "text/plain"
    )
)

registerHandler("sandbox", message(IoSandbox formCreate)) do(
    matches := method(p, request,
		p == path and request isPost and request contentType == "application/x-www-form-urlencoded"
    )
)

registerHandler("sandbox", message(IoSandbox badCreate)) do(
    matches := method(p, request,
		p == path and request isPost and(
			contentType := request contentType
			contentType != "application/x-www-form-urlencoded" and contentType != "text/plain"
		)
    )
)

IoSandbox := Object clone do(

	con := nil

        openConnection := method(
            if(con isNil or con socket isOpen not or con serverObject ping != "pong",
                con = DOConnection clone setHost("127.0.0.1") setPort(8456) connect
            )
        )

        closeConnection := method(
            con = nil
        )
	
	index := method(request,
		socket := request socket

		socket writeln("Status: 200 OK")
		socket writeln("Content-Type: text/html")
		socket writeln

		socket writeln(
"""
<html>
<head>
    <title>Io Sandbox</title>
    <link rel="stylesheet" href="site.css">
</head>
<body>
<ul>
<br><span class=selectedMenu>Io Sandbox</span>
</ul>

<ul>
<form action="sandbox" method="POST">
<textarea name="text" cols="80" rows="10" wrap="off"></textarea></td>
<br>
<input type="submit" value="Run"/>
</form>
</ul>

</body>
</html>
""")
	)

	redirectToIndex := method(request,
		socket := request socket

		socket writeln("Status: 301 Moved Permanently")
		socket writeln("Content-Type: text/plain")
		socket writeln("Location: ", request url slice(0, -1))
		socket writeln
	)

	badCreate := method(request,
		socket := request socket

		socket writeln("Status: 406 Not Acceptable")
		socket writeln("Content-Type: text/plain")
		socket writeln

		socket writeln(
"""
Io Sandbox supports posts with the following content types:

Content-Type: text/plain

Content-Type: application/x-www-form-urlencoded
 - code in an argument named text
"""
		)
	)

	plainCreate := method(request,
            data := request body
            handleRun(request, data)
        )

	formCreate := method(request,
            form := request parse
            data := form at("text") ifNilEval("")
            handleRun(request, data)
        )

        handleRun := method(request, data,
            log writeln(data)
            log flush
            socket := request socket

            socket writeln("Status: 200 OK")
            socket writeln("Content-Type: text/html")
            socket writeln

            #request params foreach(k, v, socket writeln(k, ": ", v))

            socket writeln

            writeln("data: ", data)
            socket writeln(
"""
<html>
<head>
    <title>Io Sandbox</title>
    <link rel="stylesheet" href="site.css">
</head>
<body>
<ul>
<br><span class=selectedMenu>Io Sandbox</span>
</ul>

<ul>
<form action="sandbox" method="POST">
<textarea name="text" cols="80" rows="10" wrap="off">""")
            socket writeln(data)

            socket writeln(
"""</textarea></td>
<br>
<input type="submit" value="Run"/>
</form>
</ul>
<pre>
""")
            e := try(
                openConnection
                result := con serverObject sandboxEval(data)
                socket writeln(result)
                if(result == nil,
                    closeConnection
                )
            )
            if(e,
                e showStack
                return
            )
            socket writeln(
"""
</pre>
</body>
</html>
""")
	)
)

