#[ Exchange disk- and file-structures with nim-structures 
]#

import strutils
import os


var debugbo: bool = false
  
template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



proc writeFilePatternToSeq*(filestartwithst: string): seq[string] = 

#[ Write the files from pattern in the current dir to the sequence and
 return that]#

  var
    filelisq: seq[string]
    filenamest: string
  

  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > len(filestartwithst):
        if filenamest[0..len(filestartwithst) - 1] == filestartwithst:
          log(filenamest)
          filelisq.add(filenamest)

  result = filelisq


proc addShowValuesToSeq*(listsq: seq[string], startingclipst, substitutionst: string): 
                                        seq[array[2, string]] = 

#[  ]#
  var 
    valuelisq: seq[array[2, string]]
    shownamest: string

  for filest in listsq:

    shownamest = substitutionst & filest[len(startingclipst) .. len(filest) - 1]
    valuelisq.add([filest, shownamest])

  result = valuelisq



when isMainModule:
  #echo writeFilePatternToSeq("freek")
  echo addShowValuesToSeq(writeFilePatternToSeq("freek"), "freek", "*")


