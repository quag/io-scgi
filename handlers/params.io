registerHandler("params", message(params))

params := method(request,
    socket := request socket

    socket writeln("Status: 200 OK")
    socket writeln("Content-Type: text/plain")
    socket writeln

	request params foreach(k, v,
		socket writeln(k, ": ", v)
	)
)
