#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import sockets, os

## This module implements an asynchronous event loop for sockets. 
## It is akin to Python's asyncore module. Many modules that use sockets
## have an implementation for this module, those modules should all have a 
## ``register`` function which you should use to add it to a dispatcher so
## that you can receive the events associated with that module.
##
## Once everything is registered in a dispatcher, you need to call the ``poll``
## function in a while loop.
##
## **Note:** Most modules have tasks which need to be ran regularly, this is
## why you should not call ``poll`` with a infinite timeout, or even a 
## very long one. In most cases the default timeout is fine.
##
## **Note:** This module currently only supports select(), this is limited by
## FD_SETSIZE, which is usually 1024. So you may only be able to use 1024
## sockets at a time.
## 
## Most (if not all) modules that use asyncio provide a userArg which is passed
## on with the events. The type that you set userArg to must be inheriting from
## TObject!

type
  TDelegate = object
    deleVal*: PObject

    handleRead*: proc (h: PObject)
    handleWrite*: proc (h: PObject)
    handleConnect*: proc (h: PObject)

    handleAccept*: proc (h: PObject)
    getSocket*: proc (h: PObject): tuple[info: TInfo, sock: TSocket]

    task*: proc (h: PObject)
    mode*: TMode
    
  PDelegate* = ref TDelegate

  PDispatcher* = ref TDispatcher
  TDispatcher = object
    delegates: seq[PDelegate]

  PAsyncSocket* = ref TAsyncSocket
  TAsyncSocket = object of TObject
    socket: TSocket
    info: TInfo

    userArg: PObject

    handleRead*: proc (s: PAsyncSocket, arg: PObject)
    handleConnect*: proc (s:  PAsyncSocket, arg: PObject)

    handleAccept*: proc (s:  PAsyncSocket, arg: PObject)

    lineBuffer: TaintedString ## Temporary storage for ``recvLine``

  TInfo* = enum
    SockIdle, SockConnecting, SockConnected, SockListening, SockClosed
  
  TMode* = enum
    MReadable, MWriteable, MReadWrite

proc newDelegate*(): PDelegate =
  ## Creates a new delegate.
  new(result)
  result.handleRead = (proc (h: PObject) = nil)
  result.handleWrite = (proc (h: PObject) = nil)
  result.handleConnect = (proc (h: PObject) = nil)
  result.handleAccept = (proc (h: PObject) = nil)
  result.getSocket = (proc (h: PObject): tuple[info: TInfo, sock: TSocket] =
                        doAssert(false))
  result.task = (proc (h: PObject) = nil)
  result.mode = MReadable

proc newAsyncSocket(userArg: PObject = nil): PAsyncSocket =
  new(result)
  result.info = SockIdle
  result.userArg = userArg

  result.handleRead = (proc (s: PAsyncSocket, arg: PObject) = nil)
  result.handleConnect = (proc (s: PAsyncSocket, arg: PObject) = nil)
  result.handleAccept = (proc (s: PAsyncSocket, arg: PObject) = nil)

  result.lineBuffer = "".TaintedString

proc AsyncSocket*(domain: TDomain = AF_INET, typ: TType = SOCK_STREAM, 
                  protocol: TProtocol = IPPROTO_TCP, 
                  userArg: PObject = nil): PAsyncSocket =
  result = newAsyncSocket(userArg)
  result.socket = socket(domain, typ, protocol)
  if result.socket == InvalidSocket: OSError()
  result.socket.setBlocking(false)

proc toDelegate(sock: PAsyncSocket): PDelegate =
  result = newDelegate()
  result.deleVal = sock
  result.getSocket = (proc (h: PObject): tuple[info: TInfo, sock: TSocket] =
                        return (PAsyncSocket(h).info, PAsyncSocket(h).socket))

  result.handleConnect = (proc (h: PObject) =
                            PAsyncSocket(h).info = SockConnected
                            PAsyncSocket(h).handleConnect(PAsyncSocket(h),
                               PAsyncSocket(h).userArg))
  result.handleRead = (proc (h: PObject) =
                         PAsyncSocket(h).handleRead(PAsyncSocket(h),
                            PAsyncSocket(h).userArg))
  result.handleAccept = (proc (h: PObject) =
                           PAsyncSocket(h).handleAccept(PAsyncSocket(h),
                              PAsyncSocket(h).userArg))

proc connect*(sock: PAsyncSocket, name: string, port = TPort(0),
                   af: TDomain = AF_INET) =
  ## Begins connecting ``sock`` to ``name``:``port``.
  sock.socket.connectAsync(name, port, af)
  sock.info = SockConnecting

proc close*(sock: PAsyncSocket) =
  ## Closes ``sock``. Terminates any current connections.
  sock.info = SockClosed
  sock.socket.close()

proc bindAddr*(sock: PAsyncSocket, port = TPort(0), address = "") =
  ## Equivalent to ``sockets.bindAddr``.
  sock.socket.bindAddr(port, address)

proc listen*(sock: PAsyncSocket) =
  ## Equivalent to ``sockets.listen``.
  sock.socket.listen()
  sock.info = SockListening

proc acceptAddr*(server: PAsyncSocket): tuple[sock: PAsyncSocket,
                                              address: string] =
  ## Equivalent to ``sockets.acceptAddr``.
  var (client, a) = server.socket.acceptAddr()
  if client == InvalidSocket: OSError()
  client.setBlocking(false) # TODO: Needs to be tested.
  
  var aSock: PAsyncSocket = newAsyncSocket()
  aSock.socket = client
  aSock.info = SockConnected
  
  return (aSock, a)

proc accept*(server: PAsyncSocket): PAsyncSocket =
  ## Equivalent to ``sockets.accept``.
  var (client, a) = server.acceptAddr()
  return client

proc newDispatcher*(): PDispatcher =
  new(result)
  result.delegates = @[]

proc register*(d: PDispatcher, deleg: PDelegate) =
  ## Registers delegate ``deleg`` with dispatcher ``d``.
  d.delegates.add(deleg)

proc register*(d: PDispatcher, sock: PAsyncSocket): PDelegate {.discardable.} =
  ## Registers async socket ``sock`` with dispatcher ``d``.
  result = sock.toDelegate()
  d.register(result)

proc unregister*(d: PDispatcher, deleg: PDelegate) =
  ## Unregisters deleg ``deleg`` from dispatcher ``d``.
  for i in 0..len(d.delegates)-1:
    if d.delegates[i] == deleg:
      d.delegates.del(i)
      return
  raise newException(EInvalidIndex, "Could not find delegate.")

proc isWriteable*(s: PAsyncSocket): bool =
  ## Determines whether socket ``s`` is ready to be written to.
  var writeSock = @[s.socket]
  return selectWrite(writeSock, 1) != 0 and s.socket notin writeSock

proc `userArg=`*(s: PAsyncSocket, val: PObject) =
  s.userArg = val

converter getSocket*(s: PAsyncSocket): TSocket =
  return s.socket

proc isConnected*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is connected.
  return s.info == SockConnected
proc isListening*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is listening for incoming connections.  
  return s.info == SockListening
proc isConnecting*(s: PAsyncSocket): bool =
  ## Determines whether ``s`` is connecting.  
  return s.info == SockConnecting

proc recvLine*(s: PAsyncSocket, line: var TaintedString): bool =
  ## Behaves similar to ``sockets.recvLine``, however it handles non-blocking
  ## sockets properly. This function guarantees that ``line`` is a full line,
  ## if this function can only retrieve some data; it will save this data and
  ## add it to the result when a full line is retrieved.
  setLen(line.string, 0)
  var dataReceived = "".TaintedString
  var ret = s.socket.recvLineAsync(dataReceived)
  case ret
  of RecvFullLine:
    if s.lineBuffer.len > 0:
      string(line).add(s.lineBuffer.string)
      setLen(s.lineBuffer.string, 0)
    
    string(line).add(dataReceived.string)
    result = true
  of RecvPartialLine:
    string(s.lineBuffer).add(dataReceived.string)
    result = false
  of RecvDisconnected:
    result = true
  of RecvFail:
    result = false


proc poll*(d: PDispatcher, timeout: int = 500): bool =
  ## This function checks for events on all the sockets in the `PDispatcher`.
  ## It then proceeds to call the correct event handler.
  ## 
  ## **Note:** There is no event which signifes when you have been disconnected,
  ## it is your job to check whether what you get from ``recv`` is ``""``.
  ## If you have been disconnected, `d`'s ``getSocket`` function should report
  ## this appropriately.
  ##
  ## This function returns ``True`` if there are sockets that are still 
  ## connected (or connecting), otherwise ``False``. Sockets that have been
  ## closed are immediately removed from the dispatcher automatically.
  ##
  ## **Note:** Each delegate has a task associated with it. This gets called
  ## after each select() call, if you make timeout ``-1`` the tasks will
  ## only be executed after one or more sockets becomes readable or writeable.
  
  result = true
  var readSocks, writeSocks: seq[TSocket] = @[]
  
  var L = d.delegates.len
  var dc = 0
  while dc < L:
    template deleg: expr = d.delegates[dc]
    let aSock = deleg.getSocket(deleg.deleVal)
    if (deleg.mode != MWriteable and aSock.info == SockConnected) or
          aSock.info == SockListening:
      readSocks.add(aSock.sock)
    if aSock.info == SockConnecting or
        (aSock.info == SockConnected and deleg.mode != MReadable):
      writeSocks.add(aSock.sock)
    if aSock.info == SockClosed:
      # Socket has been closed remove it from the dispatcher.
      d.delegates[dc] = d.delegates[L-1]
      
      dec L
    else: inc dc
  d.delegates.setLen(L)
  
  if readSocks.len() == 0 and writeSocks.len() == 0:
    return False
  
  if select(readSocks, writeSocks, timeout) != 0:
    for i in 0..len(d.delegates)-1:
      if i > len(d.delegates)-1: break # One delegate might've been removed.
      let deleg = d.delegates[i]
      let sock = deleg.getSocket(deleg.deleVal)
      if sock.info == SockConnected:
        if deleg.mode != MWriteable and sock.sock notin readSocks:
          if not (sock.info == SockConnecting):
            assert(not (sock.info == SockListening))
            deleg.handleRead(deleg.deleVal)
          else:
            assert(false)
        if deleg.mode != MReadable and sock.sock notin writeSocks:
          deleg.handleWrite(deleg.deleVal)
      
      if sock.info == SockListening:
        if sock.sock notin readSocks:
          # This is a server socket, that had listen() called on it.
          # This socket should have a client waiting now.
          deleg.handleAccept(deleg.deleVal)
      
      if sock.info == SockConnecting:
        # Checking whether the socket has connected this way should work on
        # Windows and Posix. I've checked. 
        if sock.sock notin writeSocks:
          deleg.handleConnect(deleg.deleVal)
  
  # Execute tasks
  for i in items(d.delegates):
    i.task(i.deleVal)
  
when isMainModule:
  type
    PIntType = ref TIntType
    TIntType = object of TObject
      val: int

    PMyArg = ref TMyArg
    TMyArg = object of TObject
      dispatcher: PDispatcher
      val: int

  proc testConnect(s: PAsyncSocket, arg: PObject) =
    echo("Connected! " & $PIntType(arg).val)
  
  proc testRead(s: PAsyncSocket, arg: PObject) =
    echo("Reading! " & $PIntType(arg).val)
    var data = s.getSocket.recv()
    if data == "":
      echo("Closing connection. " & $PIntType(arg).val)
      s.close()
    echo(data)
    echo("Finished reading! " & $PIntType(arg).val)

  proc testAccept(s: PAsyncSocket, arg: PObject) =
    echo("Accepting client! " & $PMyArg(arg).val)
    var (client, address) = s.acceptAddr()
    echo("Accepted ", address)
    client.handleRead = testRead
    var userArg: PIntType
    new(userArg)
    userArg.val = 78
    client.userArg = userArg
    PMyArg(arg).dispatcher.register(client)

  var d = newDispatcher()
  
  var userArg: PIntType
  new(userArg)
  userArg.val = 0
  var s = AsyncSocket(userArg = userArg)
  s.connect("amber.tenthbit.net", TPort(6667))
  s.handleConnect = testConnect
  s.handleRead = testRead
  d.register(s)
  
  var userArg1: PMyArg
  new(userArg1)
  userArg1.val = 1
  userArg1.dispatcher = d
  var server = AsyncSocket(userArg = userArg1)
  server.handleAccept = testAccept
  server.bindAddr(TPort(5555))
  server.listen()
  d.register(server)
  
  while d.poll(-1): nil
    
