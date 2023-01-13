#[ 
  This module contains the functions for the operation of 
  the cookie-tunnel called at the end of proj.startup.nim. 

]#


import tables, strutils, json, g_templates
#from g_html_json import nil


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

  

proc convertFileToSequence*(filepathst, skipst: string): seq[string] = 

  var lisq: seq[string]

  withFile(txt, filepathst, fmRead):  # special colon
    for line in txt.lines:
      #echo line
      if line.len > 0:
        if line.len < skipst.len:
          lisq.add(line)
        else:
          if line[0..skipst.len - 1] != skipst:
            lisq.add(line)

  result = lisq



proc convertSequenceToFile(filepathst: string, lisq: seq[string]) = 
  
  withFile(txt, filepathst, fmWrite):  # special colon
    for item in lisq:
      txt.writeLine(item)



when isMainModule:

  #echo split2("do Select after this", "SELECT")


  echo convertFileToSequence("fq_noise_word.dat", ">>>")

  var skiplistsq = @["through", "Through", "between", "because", "various", "against", 
                  "important", "something", "another", "themselves", "currently",
                  "particular", "possible", "without", "several", "certain"]

  convertSequenceToFile("fq_noise_word.dat", skiplistsq)

