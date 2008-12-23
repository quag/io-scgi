registerHandler("ping", message(ping))
ping := method(request,
    socket := request socket

    socket writeln("Status: 200 OK")
    socket writeln("Content-Type: text/plain")
    socket writeln

    socket writeln("pong")
)
