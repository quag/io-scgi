Socket
con := DOConnection clone setHost("127.0.0.1") setPort(8456) connect

while(line := File standardInput readLine,
	writeln(con serverObject sandboxEval(line))
)

