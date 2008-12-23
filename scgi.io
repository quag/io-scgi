#!/usr/bin/env io

log := File with("scgi.log") openForAppending
log writeln := method(
    self write(call evalArgs join)
    self write("\n")
)

Dispatcher := Object clone do(
    newSlot("root", "/io/")
    newSlot("target", Lobby)

    dispatch := method(path, request,
        p := path slice(root size)

        handlers detect(matches(p, request)) ifNilEval(fileNotFoundHandler) handle(p, request)
    )

    Handler := Object clone do(
        newSlot("path")
        newSlot("msg")
        newSlot("target")
        newSlot("file")

        matches := method(p, request,
            path == p and request isGet
        )

        handle := method(p, request,
            target doMessage(
				m := msg clone
				n := m
				while(n next and n next ?(isEndOfLine) not, n = n next)
                n appendArg(Message clone setName("request") setCachedResult(request)) \
                  appendArg(Message clone setName("p") setCachedResult(p))

				writeln(p, " -> ", file, " ", m)
				log writeln(p, " -> ", file, " ", m)
				m
            )
        )
    )

    handlers := list()

    registerHandler := method(path, msg, file,
        handler := Handler clone setPath(path) setMsg(msg) setTarget(target) setFile(file)
        handlers append(handler)
        handler
    )

    fileNotFoundHandler := Handler clone setMsg(message(fileNotFound)) do(
        matches := true
    )
)

registerHandler := method(path, msg, Dispatcher registerHandler(path, msg, call message label))

reloadScripts := method(
    Directory with("handlers") filesWithExtension(".io") foreach(script,
        writeln("loading: ", script name, " ", script lastDataChangeDate)
        Lobby doFile(script path)
    )
    writeln
    writeln("loaded handlers")
    writeln
)

fileNotFound := method(request, p,
    socket := request socket

    socket writeln("Status: 404 File Not Found")
    socket writeln("Content-Type: text/plain")
    socket writeln

    socket writeln("404 File Not Found")
    socket writeln(p)
)


Socket writeln := method(
    self write(call evalArgs join)
    self write("\n")
)

Request := Object clone do(
    newSlot("socket")
    newSlot("body")
    newSlot("params")

	requestMethod := method(
		params at("REQUEST_METHOD") asMutable uppercase
	)

	isGet := method(requestMethod == "GET")
	isPost := method(requestMethod == "POST")
	isPut := method(requestMethod == "PUT")
	isDelete := method(requestMethod == "DELETE")

	url := method(
		s := Sequence clone appendSeq("http://", params at("SERVER_NAME"))
		if(params at("SERVER_PORT") != "80",
			s appendSeq(":", params at("SERVER_PORT"))
		)
		s appendSeq(params at("REQUEST_URI"))
	)

	contentType := method(
		params at("CONTENT_TYPE")
	)

	parse := method(
		cgi := CGI clone 
		cgi System := cgi
		cgi getenv := method(call delegateToMethod(params, "at"))
		cgi params := params

		cgi File := Object clone
		cgi File standardInput := Object clone
		cgi File standardInput open := Object clone
		cgi File standardInput open contents := body
		cgi File standardInput readStringOfLength := body

		form := cgi parse
	)
)

SCGI := Object clone do(
    newSlot("socket")
    newSlot("dispatcher")

    handle := method(
        writeln("[Got scgi request connection from ", socket ipAddress, "]")

        while(socket isOpen,
            if(socket streamReadNextChunk) then(
                input := socket readBuffer 
                i := input findSeq(":")
                count := input slice(0, i) asNumber
                params := input slice(i + 1, i + 1 + count) split("\0")
                rest := input slice(i + 1 + count + 1)

                pmap := Map clone
                key := nil
                params foreach(i, value,
                    if(i isEven,
                        key = value
                    ,
                        pmap atPut(key, value)
                    )
                )

                writeln("request from: ", pmap at("REMOTE_ADDR"), ":", pmap at("REMOTE_PORT"))
                log writeln("request from: ", pmap at("REMOTE_ADDR"), ":", pmap at("REMOTE_PORT"))

                request := Request clone setParams(pmap) setSocket(socket) setBody(rest)
                dispatcher dispatch(pmap at("REQUEST_URI"), request)
                socket close

                break
            )
        )

        writeln("[Closed ", socket ipAddress, "]")
    )
)

dispatcher := Dispatcher clone
SCGI setDispatcher(dispatcher)

reloadScripts

s := Server clone do(
    handleSocket := method(socket,
        #SCGI clone setSocket(socket) @@handle
        coroDo(SCGI clone setSocket(socket) handle)
    )
)

#"AVCodec CGI Fnmatch Libxml2 Postgres SHA1 SoundTouch Thunder AppleExtras ContinuedFraction Font Loki Python SQLite Syslog User AsyncRequest Contracts GLFW MD5 Random SQLite3 SystemCall Vector BigNum Curses Image ObjcBridge Rational SampleRateConverter TagDB Zlib Blowfish DBI LZO OpenGL Regex SkipDB TagLib CFFI Flux LibSndFile PortAudio SGML Socket Thread" split foreach(addon,

if(true,
    "CGI Fnmatch Libxml2 Postgres SHA1 SoundTouch Thunder AppleExtras ContinuedFraction Font Loki Python Syslog User AsyncRequest Contracts GLFW MD5 Random SystemCall Vector BigNum Curses Image ObjcBridge Rational Socket Thread" split foreach(addon,
        writeln(addon)
        try(doString(addon))
    )
)

writeln("Started")
s setPort(6666)
s start

