#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `mySQL`:idx: database wrapper. The same interface is 
## implemented for other databases too.

import strutils, mysql

type
  TDbConn* = PMySQL    ## encapsulates a database connection
  TRow* = seq[string]  ## a row of a dataset
  EDb* = object of EIO ## exception that is raised if a database error occurs

  TSqlQuery* = distinct string ## an SQL query string
 
proc dbError(db: TDbConn) {.noreturn.} = 
  ## raises an EDb exception.
  var e: ref EDb
  new(e)
  e.msg = $mysql.error(db)
  raise e

proc dbError*(msg: string) {.noreturn.} = 
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
  raise e

when false:
  proc dbQueryOpt*(db: TDbConn, query: string, args: openarray[string]) =
    var stmt = mysql_stmt_init(db)
    if stmt == nil: dbError(db)
    if mysql_stmt_prepare(stmt, query, len(query)) != 0: 
      dbError(db)
    var 
      binding: seq[MYSQL_BIND]
    discard mysql_stmt_close(stmt)

proc dbQuote(s: string): string =
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: TSqlQuery, args: openarray[string]): string =
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else: 
      add(result, c)
  
proc TryExec*(db: TDbConn, query: TSqlQuery, args: openarray[string]): bool =
  ## tries to execute the query and returns true if successful, false otherwise.
  var q = dbFormat(query, args)
  return mysql.RealQuery(db, q, q.len) == 0'i32

proc Exec*(db: TDbConn, query: TSqlQuery, args: openarray[string]) =
  ## executes the query and raises EDB if not successful.
  var q = dbFormat(query, args)
  if mysql.RealQuery(db, q, q.len) != 0'i32: dbError(db)
    
proc newRow(L: int): TRow = 
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
proc properFreeResult(sqlres: mysql.PRES, row: cstringArray) =  
  if row != nil:
    while mysql.FetchRow(sqlres) != nil: nil
  mysql.FreeResult(sqlres)
  
iterator FastRows*(db: TDbConn, query: TSqlQuery,
                   args: openarray[string]): TRow =
  ## executes the query and iterates over the result dataset. This is very 
  ## fast, but potenially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For MySQL this is the case!.
  Exec(db, query, args)
  var sqlres = mysql.UseResult(db)
  if sqlres != nil:
    var L = int(mysql.NumFields(sqlres))
    var result = newRow(L)
    var row: cstringArray
    while true:
      row = mysql.FetchRow(sqlres)
      if row == nil: break
      for i in 0..L-1: 
        setLen(result[i], 0)
        add(result[i], row[i])
      yield result
    properFreeResult(sqlres, row)

proc getRow*(db: TDbConn, query: TSqlQuery,
             args: openarray[string]): TRow =
  ## retrieves a single row.
  Exec(db, query, args)
  var sqlres = mysql.UseResult(db)
  if sqlres != nil:
    var L = int(mysql.NumFields(sqlres))
    result = newRow(L)
    var row = mysql.FetchRow(sqlres)
    if row != nil: 
      for i in 0..L-1: 
        setLen(result[i], 0)
        add(result[i], row[i])
    properFreeResult(sqlres, row)

proc GetAllRows*(db: TDbConn, query: TSqlQuery, 
                 args: openarray[string]): seq[TRow] =
  ## executes the query and returns the whole result dataset.
  result = @[]
  Exec(db, query, args)
  var sqlres = mysql.UseResult(db)
  if sqlres != nil:
    var L = int(mysql.NumFields(sqlres))
    var row: cstringArray
    var j = 0
    while true:
      row = mysql.FetchRow(sqlres)
      if row == nil: break
      setLen(result, j+1)
      newSeq(result[j], L)
      for i in 0..L-1: result[j][i] = $row[i]
      inc(j)
    mysql.FreeResult(sqlres)

iterator Rows*(db: TDbConn, query: TSqlQuery, 
               args: openarray[string]): TRow =
  ## same as `FastRows`, but slower and safe.
  for r in items(GetAllRows(db, query, args)): yield r

proc GetValue*(db: TDbConn, query: TSqlQuery, 
               args: openarray[string]): string = 
  ## executes the query and returns the result dataset's the first column 
  ## of the first row. Returns "" if the dataset contains no rows. This uses
  ## `FastRows`, so it inherits its fragile behaviour.
  result = ""
  for row in FastRows(db, query, args): 
    result = row[0]
    break

proc TryInsertID*(db: TDbConn, query: TSqlQuery, 
                  args: openarray[string]): int64 =
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row or -1 in case of an error.
  var q = dbFormat(query, args)
  if mysql.RealQuery(db, q, q.len) != 0'i32: 
    result = -1'i64
  else:
    result = mysql.InsertId(db)
  
proc InsertID*(db: TDbConn, query: TSqlQuery, args: openArray[string]): int64 = 
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row.
  result = TryInsertID(db, query, args)
  if result < 0: dbError(db)

proc ExecAffectedRows*(db: TDbConn, query: TSqlQuery, 
                       args: openArray[string]): int64 = 
  ## runs the query (typically "UPDATE") and returns the
  ## number of affected rows
  Exec(db, query, args)
  result = mysql.AffectedRows(db)

proc Close*(db: TDbConn) = 
  ## closes the database connection.
  if db != nil: mysql.Close(db)

proc Open*(connection, user, password, database: string): TDbConn =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established.
  result = mysql.Init(nil)
  if result == nil: dbError("could not open database connection") 
  if mysql.RealConnect(result, "", user, password, database, 
                       0'i32, nil, 0) == nil:
    var errmsg = $mysql.error(result)
    db_mysql.Close(result)
    dbError(errmsg)

