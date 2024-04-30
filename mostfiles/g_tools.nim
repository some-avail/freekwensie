#[ 
  This module contains the functions for the operation of 
  the cookie-tunnel called at the end of proj.startup.nim. 

]#


# import tables, strutils, json, g_templates
import strutils, json, g_templates
#from g_html_json import nil

var versionfl: float = 0.11

var debugbo: bool = true

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: echo messagest




#func split(s: string; sep: char; maxsplit: int = -1): seq[string] {.....}


proc split2*(st: string, sepst: string, maxsplit: int = -1): seq[string] =
  # As strutils.split, but liberalizing letter-case for the seperator sepst
  # Tested are: WORD, word and Word

  var sepsmallst, sepbigst, sepcapst: string
  
  sepsmallst = sepst.toLowerAscii()
  sepbigst = sepst.toUpperAscii()
  sepcapst = sepsmallst.capitalizeAscii()


  if st.contains(sepst):
    result = split(st, sepst, maxsplit)
  elif st.contains(sepsmallst):
    result = split(st, sepsmallst, maxsplit)
  elif st.contains(sepbigst):
    result = split(st, sepbigst, maxsplit)
  elif st.contains(sepcapst):
    result = split(st, sepcapst, maxsplit)

  


proc convertSequenceToFile*(filepathst: string, lisq: seq[string]) = 
  
  withFile(txtfl, filepathst, fmWrite):  # special colon
    for item in lisq:
      txtfl.writeLine(item)


proc zipTwoSeqsToOne*(firstsq: seq[string], secondsq: seq[string] = @[]): seq[array[2, string]] = 
  var 
    newSeq: seq[array[2, string]]
    countit: int = 0

  if secondsq == @[]:
    for elemst in firstsq:
      newSeq.add([elemst, elemst])
  else:
    for elemst in firstsq:
      newSeq.add([elemst, secondsq[countit]])
      countit += 1

  result = newSeq


proc filterMatches(tekst, filterst: string): bool = 

  #[
  If the filter matches the text, true is returned.
  ]#
  discard


when isMainModule:

  #echo split2("do Select after this", "SELECT")


  #[ 
  var skiplistsq = @["through", "Through", "between", "because", "various", "against", 
                  "important", "something", "another", "themselves", "currently",
                  "particular", "possible", "without", "several", "certain"]

  convertSequenceToFile("fq_noise_word.dat", skiplistsq)
 ]#

 echo zipTwoSeqsToOne(@["1","2","3"], @["a","b","c"])

