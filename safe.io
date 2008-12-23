memoryLimit := 20 * 2**10
cpuLimitPerCommand := 2  # in integer seconds

resetTimeLimit := method(
	ULimit setCPUTimeLimit(Date clock ceil + cpuLimitPerCommand)
)

Sandbox makeSafe := method(
	doSandboxString("Importer turnOff")

	doSandboxString("""
		"System File Directory Importer Addon AddonLoader" split foreach(name,
			Protos Core removeSlot(name)
		)
	""")
)

sandbox := Sandbox clone do(
	printedData := Sequence clone

	printCallback := method(s,
		printedData appendSeq(s)
	)

	setup := method(
		makeSafe
		ULimit setDataMemoryLimit(memoryLimit)
	)

	sandboxEval := method(code,
		resetTimeLimit
		printedData = Sequence clone
		
		command := "method(s, e := try(r := Lobby doString(s) asString); if(e, e showStack, r)) call(\"" .. code asMutable escape .. "\")"
		r := sandbox doSandboxString(command)

		sandbox doSandboxString("Collector collect")

		if(printedData size > 0,
			printedData .. "==> " .. r
		,
			"==> " .. r
		)
	)
)
sandbox setup

runCommandLine := method(
	while(line := File standardInput readLine,
		writeln(sandbox sandboxEval)
	)
)

runSocket := method(

	server := Server clone do(
		setPort(8456)

		Echo := Object clone do(
			handleSocketFromServer := method(socket, aServer,
				writeln("[Got echo connection from ", socket ipAddress, "]")
				socket setReadTimeout(60*60)
				while(socket isOpen, 
					if(socket read, 
						data := socket readBuffer
						writeln(socket ipAddress, " ", data)
						socket write(sandbox sandboxEval(data))
					)
					socket readBuffer empty
				)
				writeln("[Closed ", socket ipAddress, "]")
			)
		)

		handleSocket := method(socket,
			Echo clone @handleSocketFromServer(socket, self)
		)
	)

	server start
)

runDOServer := method(
    sandbox ping := method("pong")
    doServer := DOServer clone
    doServer setRootObject(sandbox)
    doServer setPort(8456)
    doServer start
)

#runCommandLine
#runSocket
runDOServer
