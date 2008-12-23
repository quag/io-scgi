registerHandler("inspect", message(ioRoot)) do(
    matches := method(p,
        p beginsWithSeq(path)
    )
)

ioRoot := method(request, p,
    socket := request socket

    socket writeln("Status: 200 OK")
    socket writeln("Content-Type: text/html")
    socket writeln

    writer := XmlWriter clone openFd(socket descriptorId)
    #writer setIndent(true) setIndentString("    ")

    delegateMethod := method(call delegateTo(writer))
    XmlWriter slotNames foreach(name,
        setSlot(name, getSlot("delegateMethod"))
    )

    ioPath := p split("/", " ", "%20", "+")

    Lobby inspect := Lobby

    target := Lobby
    ioPath foreach(slotName,
        if(getSlot("target") hasSlot(slotName),
            target = getSlot("target") getSlot(slotName)
        ,
            break
        )
    )

    if(getSlot("target") == Lobby, ioPath = list("Lobby"))

    startDocument
    startElement("html")

    startElement("head")
    writeElement("title", ioPath join(" "))
    endElement

    startElement("body")

    writeElement("h1", ioPath join(" "))

    absPath := request params at("REQUEST_URI")

    if(getSlot("target") hasSlot("asXml"),
        getSlot("target") asXml(writer)
    ,
        if(getSlot("target") asString != getSlot("target") slotSummary,
            writeElement("pre", getSlot("target") asString)
        )
    )

    startElement("ul")
    map := getSlot("target") slotDescriptionMap
    
    map keys sortInPlace foreach(name,
        value := map at(name)

        startElement("li")

        startElement("a")
        writeAttribute("href", absPath split("/") append(name) join("/"))
        writeString(name)
        endElement

        if (getSlot("target") getSlot(name) type == "Block",
            writeString(" :=")
            #startElement("div")
            getSlot("target") getSlot(name) asXml(writer)
            #endElement
        ,
            writeString(" ")
            writeElement("span", getSlot("value") asString)
        )

        endElement
    )
    endElement

    endElement
    endElement
    endDocument

    close
)

Block asString := method(
    getSlot("self") formatCode
)

Block asXml := method(writer,
    getSlot("self") formatCodeXml(writer)
)

Formatter := Object clone do(
    newSlot("seq")
    newSlot("lineNumber")
    newSlot("startOfLine", true)

    init := method(
        seq = Sequence clone
    )

    appendSeq := method(
        startOfLine = false
        call delegateTo(seq)
    )

    newLine := method(
        seq appendSeq("\n")
        lineNumber = lineNumber + 1
        startOfLine = true
    )

	newLinesTo := method(m,
		while(lineNumber < m lineNumber,
			newLine
		)
	)

    indent := method(depth,
        if(startOfLine not,
            writeln("eek! not start of line and are trying to indent")
        )
        depth repeat(
            seq appendSeq("    ")
        )
    )
)

Block formatCode := method(seq, depth,
    seq = seq ifNilEval(Formatter clone)
    depth = depth ifNilEval(0)

    msg := getSlot("self") message
    seq appendSeq("method(")
    if(getSlot("self") argumentNames size > 0,
        seq appendSeq(getSlot("self") argumentNames join(", "), ", ")
    )
    seq lineNumber = msg lineNumber
    msg formatCode(seq, depth + 1)

    if(msg lineNumber != seq lineNumber,
        seq newLine
    )
    seq appendSeq(")")
    seq seq
)

Map reverseMap := method(
    Map clone addKeysAndValues(values, keys)
)

OperatorTable reverseAssignOperators := OperatorTable assignOperators reverseMap

Message formatCode := method(seq, depth,
    seq = seq ifNilEval(Formatter clone)
    depth = depth ifNilEval(0)
    seq lineNumber = seq lineNumber ifNilEval(self lineNumber)

    m := self
    while(m,
        if(m isEndOfLine,
            seq newLine
        ,
			seq newLinesTo(m)

            if(seq startOfLine,
                seq indent(depth)
            ,
                if(m != self,
                    seq appendSeq(" ")
                )
            )

            loop(
                if(OperatorTable reverseAssignOperators hasKey(m name),
                    args := m arguments
                    seq appendSeq(args first cachedResult, " ", OperatorTable reverseAssignOperators at(m name), " ")
                    args at(1) formatCode(seq, depth)
                    break
                )

                if(OperatorTable operators hasKey(m name),
                    seq appendSeq(m name, " ")
                    m arguments first formatCode(seq, depth)
                    break
                )
            
                seq appendSeq(m name)
                m formatCodeArgs(seq, depth)
                break
            )
        )

        m = m next
    )

    seq seq
)

Message formatCodeArgs := method(seq, depth,
    if(arguments size > 0,
        seq appendSeq("(")
        lineNo := seq lineNumber
        arguments foreach(i, arg,
            if(i > 0,
                if(lineNo == seq lineNumber,
                    seq appendSeq(", ")
                ,
                    seq newLine
                    seq indent(depth)
                    seq appendSeq(",")
                )
            )
            arg formatCode(seq, depth + 1)
        )
        if(lineNo != seq lineNumber,
            seq newLine
            seq indent(depth)
        )
        seq appendSeq(")")
    )
)

Block formatCodeXml := method(writer, seq, depth,
    seq = seq ifNilEval(FormatterXml clone setWriter(writer))
    depth = depth ifNilEval(0)

    seq start

    msg := getSlot("self") message
	localVariables := msg localVariables(getSlot("self") argumentNames)

    seq appendSeq("method")
    seq writer startElement("span")
    seq writer writeAttribute("style", "font-weight: bold")
    seq appendSeq("(")
    seq writer endElement
    if(getSlot("self") argumentNames size > 0,
		getSlot("self") argumentNames foreach(i, name,
			if(i > 0,
				seq appendSeq(", ")
			)

			if(name in(localVariables),
				seq writer startElement("span")
				seq writer writeAttribute("style", "color: grey")
				seq appendSeq(name)
				seq writer endElement
			,
				seq appendSeq(name)
			)
		)

		seq appendSeq(", ")
    )
    seq writer startElement("span")
    seq writer writeAttribute("style", "color: green")
	seq appendSeq(" # " .. msg label .. ":" .. msg lineNumber)
    seq writer endElement

    seq newLine
    msg formatCodeXml(seq, depth + 1, localVariables)
    seq newLine
    seq writer startElement("span")
    seq writer writeAttribute("style", "font-weight: bold")
    seq appendSeq(")")
    seq writer endElement

    seq finish
)

FormatterXml := Formatter clone do(
    newSlot("writer")
    newSlot("lineNumber", 0)
    newSlot("startOfLine", true)
    newSlot("openLine", false)

    init := method(
    )

    appendSeq := method(
        if(startOfLine,
            writer startElement("div")
            openLine = true
        )
        startOfLine = false
        call evalArgs foreach(arg,
            writer writeString(arg asString)
        )
    )

    newLine := method(
        if(openLine not,
            writer startElement("div")
            writer writeRaw("&nbsp;")
            openLine = true
        )
        writer endElement("div")
        openLine = false

        lineNumber = lineNumber + 1
        startOfLine = true
    )

	newLinesTo := method(m,
		original := lineNumber
		while(lineNumber < m lineNumber,
			newLine

			if(lineNumber - original > 2,
				lineNumber = m lineNumber
				break
			)
		)
	)

    indent := method(depth,
        if(startOfLine not,
            writeln("eek! not start of line and are trying to indent")
        )

        writer startElement("div")
        startOfLine = false
        openLine = true
        writer writeAttribute("style", "margin-left: " .. depth * 2 .. "em")
    )

    start := method(
        writer startElement("div")
        writer writeAttribute("style", "font-family: monospace")
    )

    finish := method(
        if(startOfLine not,
            writer endElement("div")
            openLine = false
        )
        startOfLine = true

        writer endElement
    )
)

Message formatCodeXml := method(seq, depth, localVariables,
    depth = depth ifNilEval(0)
    seq setLineNumber(self lineNumber)

    m := self
    while(m,
        if(m isEndOfLine,
            if(seq lineNumber == m next ?lineNumber,
                seq appendSeq(m name, " ")
            )
        ,
            if(seq lineNumber > m lineNumber,
                seq lineNumber = m lineNumber
            )
			seq newLinesTo(m)

            if(seq startOfLine,
                seq indent(depth)
            ,
                if(m != self,
                    seq appendSeq(" ")
                )
            )

            loop(
                if(OperatorTable reverseAssignOperators hasKey(m name),
                    args := m arguments
					if(args first cachedResult in(localVariables),
						seq writer startElement("span")
						seq writer writeAttribute("style", "color: grey")
						seq appendSeq(args first cachedResult, " ")
						seq writer endElement
					,
						seq appendSeq(args first cachedResult, " ")
					)

                    seq writer startElement("span")
                    seq writer writeAttribute("style", "color: green; font-weight: bold")
                    seq appendSeq(OperatorTable reverseAssignOperators at(m name))
                    seq writer endElement

                    seq appendSeq(" ")
                    args at(1) ?formatCodeXml(seq, depth, localVariables)
                    break
                )

                if(OperatorTable operators hasKey(m name),
                    seq writer startElement("span")
                    seq writer writeAttribute("style", "color: green; font-weight: bold")
                    seq appendSeq(m name)
                    seq writer endElement

                    seq appendSeq(" ")
                    m arguments first ?formatCodeXml(seq, depth, localVariables)
                    break
                )

                if(m cachedResult != nil,
                    seq writer startElement("span")
                    seq writer writeAttribute("style", "color: blue")
                    seq appendSeq(m name)
                    seq writer endElement
                    m formatCodeArgsXml(seq, depth, localVariables)
                    break
                )

				if(m name in(localVariables),
                    seq writer startElement("span")
                    seq writer writeAttribute("style", "color: grey")
                    seq appendSeq(m name)
                    seq writer endElement
                    m formatCodeArgsXml(seq, depth, localVariables)
					break
				)
            
                seq appendSeq(m name)
                m formatCodeArgsXml(seq, depth, localVariables)
                break
            )
        )

        m = m next
    )

    seq seq
)

Message formatCodeArgsXml := method(seq, depth, localVariables,
    if(arguments size > 0,
        seq writer startElement("span")
        seq writer writeAttribute("style", "font-weight: bold")
        seq appendSeq("(")
        seq writer endElement

        lineNo := seq lineNumber
        arguments foreach(i, arg,
            if(i > 0,
                if(lineNo == seq lineNumber,
                    seq writer startElement("span")
                    seq writer writeAttribute("style", "font-weight: bold")
                    seq appendSeq(",")
                    seq writer endElement
                    seq appendSeq(" ")
                ,
                    seq newLine
                    seq indent(depth)
                    seq writer startElement("span")
                    seq writer writeAttribute("style", "font-weight: bold")
                    seq appendSeq(",")
                    seq writer endElement
                    seq newLine
                )
            )
            if(seq lineNumber > arg lineNumber,
                seq lineNumber = arg lineNumber
            )
			seq newLinesTo(arg)
            arg formatCodeXml(seq, depth + 1, localVariables)
        )
        if(lineNo != seq lineNumber,
            seq newLine
            seq indent(depth)
        )
        seq writer startElement("span")
        seq writer writeAttribute("style", "font-weight: bold")
        seq appendSeq(")")
        seq writer endElement
    )
)

Message localVariables := method(locals,
	locals = locals ifNilEval(list)

	if(name == "setSlot" and argAt(0) hasCachedResult,
		locals appendIfAbsent(argAt(0) cachedResult)
	)

	if(name in(list("foreach", "method", "repeat", "detect", "select", "map", "selectInPlace", "mapInPlace")),
		for(i, 0, argCount - 2,
			locals appendIfAbsent(argAt(i) name)
		)
	)

	if(name == "for",
		locals appendIfAbsent(argAt(0) name)
	)

	arguments foreach(localVariables(locals))
	next localVariables(locals)

	locals
)

nil localVariables := method(list)
