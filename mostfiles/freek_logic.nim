import std/[random, tables, math]
import strutils
import g_mine, g_templates, g_tools, g_options


#[ Here logic that cannot be generalized out of the project ]#


var
  debugbo: bool = true
  versionfl: float = 0.1


# Beware: variable debugbo might be used globally, modularly and procedurally
# whereby lower scopes override the higher ones?
# Maybe best to use modular vars to balance between an overload of 
# messages and the need set the var at different places.

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest



randomize()


proc genTabId*(): string = 
  # 9 zeros is maximal int size, otherwise use int64
  let idst = $rand(1000000000)
  result = idst


proc getIntroText*(tekst: string, sizeit: int): string =
  var lenghit: int
  lenghit = tekst.len
  if lenghit > sizeit:
    result = tekst[0..sizeit]
  else:
    result = tekst[0..lenghit - 1]



proc getTagContent_old(link_or_tekst, startpartst, endpartst: string, 
                            maxlineit: int): string = 
  #[ 
    Retrieve a sequence of content-data between pairs of startpartst 
    and endpartst. 
   ]#
  var
    datasq, frag_onesq: seq[string]
    tempst, contentst, list: string
    itemcountit: int
  datasq = getDataSequence(link_or_tekst, startpartst, endpartst)

  list = ""
  if datasq.len > 0:
    itemcountit = 1
    for itemst in datasq:
      echo itemst
      echo "------------"
      # parse the data-sequence for the content between > and <
      frag_onesq = itemst.split('>', 1)
      tempst = frag_onesq[1]
      if ('>' in tempst) and ('<' in tempst):
        contentst = getInnerText2(tempst)
      else: 
        contentst = tempst

      if itemcountit <= maxlineit:
        if contentst != "":
          list &= contentst & "<br>\p"
      itemcountit += 1
    echo "========="
  result = list



proc getContentList*(link_or_tekst, startpartst, endpartst: string, 
                      output_doc: DocType, maxlineit: int): string =
  #[ 
    Create a list of content-data between pairs of startpartst 
    and endpartst. 
   ]#

  result = enlistSequenceToDoc(getTagContent(link_or_tekst, startpartst, endpartst), 
                        output_doc, maxlineit)


proc createSearchString*(inputst: string): string =
  result = inputst.splitWhitespace().join("+")



proc createFreqTableFromWordList*(wordlisq: seq[string], numcolsit, numrowsit: int): string = 

  var
    resultst: string = ""
    indexit: int = 0
    wordcountta = toCountTable(wordlisq)

  wordcountta.sort()

  resultst = "<table id=\"cumfreqs_table\">\p"
  resultst &= "<tr>\p"

  for colit in 0..numcolsit - 1:
    resultst &= "<td>\p"
    indexit = 0
    for k, v in wordcountta.pairs:
      if indexit < (numcolsit * numrowsit) + 2:
        if (indexit >= colit * numrowsit) and (indexit < (colit + 1) * numrowsit):
          resultst &= k & " - " & $v & "<br>\p"
      else:
        break
      indexit += 1

    resultst &= "</td>\p"
  resultst &= "</tr>\p"
  resultst &= "</table><br><br>\p"

  result = resultst




proc createNoiseWordsList_old(sourcefilest: string, threshold_fractionfl: float = 0.7) =
  
  #[
  threshold_fractionfl: value between 0 and 1; 
  If in more than 100 * threshold_fractionfl percent of the docs a word appears,
  then it is added to the noise-list (the below freq-list).

  Noise-words are words that appear in most texts and can be defined as 
  non-specific to the set of docs. By excluding the noise-words from the frequency-
  count what remains are the document-specific words.
  The list can be generic, or for a certain subject-area a specialized 
  noise-word-list can be created.
  ]#


  var
    freqlisq, nonfreqlisq: seq[string] = @[]
    listsq2: seq[seq[string]]
    filecountit, thresholdit, curfileit: int
    targetfilest: string


  withFile(txt, sourcefilest, fmRead):  # special colon
    for wlink in txt.lines:
      if wlink.len > 2:
        listsq2.add(createSeqOfUniqueWords(getInnerText2(getWebSite(wlink)), 1))
        log("Processed: " & wlink)

  thresholdit = toInt(round(float(listsq2.len) * threshold_fractionfl))
  log("listsq2.len = " & $listsq2.len)
  log("thresholdit = " & $thresholdit)

  curfileit = 1

  for filewordsq in listsq2:
    for wordst in filewordsq:
      if wordst notin nonfreqlisq and wordst notin freqlisq:
        filecountit = 0
        for filewordsq in listsq2:
          if wordst in filewordsq:
            filecountit += 1
        if filecountit >= thresholdit:   
          freqlisq.add(wordst)
        else:
          nonfreqlisq.add(wordst)
    echo $curfileit & " of " & $len(listsq2)
    curfileit += 1
    log("filewordsq.len = " & $filewordsq.len)

  targetfilest = "noise_words" & sourcefilest[len("noise_sources") .. len(sourcefilest) - 1]
  log(targetfilest)
  log("Items in freqlist = " & $freqlisq.len)

  convertSequenceToFile(targetfilest, freqlisq)



proc createNoiseWordsList*(weblink_or_filest: string, threshold_fractionfl: float,
                            maxlinksit: int, precalc_onlybo: bool = false): string =
  
  #[
  threshold_fractionfl: value between 0 and 1; 
  If in more than 100 * threshold_fractionfl percent of the docs a word appears,
  then it is added to the noise-list (the below freq-list).

  Noise-words are words that appear in most texts and can be defined as 
  non-specific to the set of docs. By excluding the noise-words from the frequency-
  count what remains are the document-specific words.
  The list can be generic, or for a certain subject-area a specialized 
  noise-word-list can be created.
  ]#


  var
    freqlisq, nonfreqlisq, weblinksq, linesq: seq[string] = @[]
    listsq2: seq[seq[string]]
    filecountit, thresholdit, curfileit, linkdepthit, linkcountit, getchildscountit: int
    zerocountit, onecountit: int = 0
    targetfilest, wlinkst, precalc_logst, logst: string
    datasq: seq[array[5, string]]
    excludesubsq: seq[string] = getValList(readOptionFromFile("subs-not-in-childlinks", optValueList))


  withFile(txt, weblink_or_filest, fmRead):  # special colon
    for linest in txt.lines:
      if linest.len > 2:
        linesq = linest.split("___")
        linkdepthit = parseInt(linesq[0])
        wlinkst = linesq[1]
        case linkdepthit:
        of 0:
          weblinksq.add(wlinkst)
          zerocountit += 1
        of 1:
          getchildscountit = getChildLinks(wlinkst, 1, 1, 1,excludesubsq ,datasq)
          linkcountit = 1
          for ar in datasq:
            if linkcountit <= maxlinksit:
              weblinksq.add(ar[2])
            else:
              break
            linkcountit += 1
          onecountit += 1
        else:
          discard

  precalc_logst = "Sources-file has " & $zerocountit & " type-0 links and " & $onecountit & " type-1 links."
  log(precalc_logst)
  logst = "Formula nr. weblinks = nr. type-0 links + nr. type-1 links * maxlinks"
  precalc_logst &= "\p<br>" & logst
  logst = "Total nr. of weblinks = " & $weblinksq.len
  precalc_logst &= "\p<br>" & logst
  log(logst)

  
  linkcountit = 0
  if not precalc_onlybo:
    for linkst in weblinksq:
      listsq2.add(createSeqOfUniqueWords(getInnerText2(getWebSite(linkst)), 1))
      linkcountit += 1
      log("Processed nr. " & $linkcountit & " = " & linkst)


  thresholdit = toInt(round(float(weblinksq.len) * threshold_fractionfl))
  logst = "thresholdit = " & $thresholdit
  log(logst)
  precalc_logst &= "\p<br>" & "Formula: Threshold = nr. of weblinks * threshold-fraction"
  precalc_logst &= "\p<br>" & logst

  if not precalc_onlybo:
    curfileit = 1

    for filewordsq in listsq2:
      for wordst in filewordsq:
        if wordst notin nonfreqlisq and wordst notin freqlisq:
          filecountit = 0
          for filewordsq in listsq2:
            if wordst in filewordsq:
              filecountit += 1
          if filecountit >= thresholdit:   
            freqlisq.add(wordst)
          else:
            nonfreqlisq.add(wordst)
      echo $curfileit & " of " & $len(listsq2)
      curfileit += 1
      log("filewordsq.len = " & $filewordsq.len)

    targetfilest = "noise_words" & weblink_or_filest[len("noise_sources") .. len(weblink_or_filest) - 1]
    convertSequenceToFile(targetfilest, freqlisq)

    precalc_logst &= "\p\p<br><br>" & "Generated file = " & targetfilest
    log(targetfilest)
    logst = "Noise-words in file = " & $freqlisq.len
    log(logst)
    precalc_logst &= "\p<br>" & logst

  result = precalc_logst


#[  ]#
proc noiseVarMessages*(filename, fraction, max_num_of_links: string): string =

  # validation

  var 
    validbo: bool = true
    messt: string = ""
    fractfl: float
    maxlinksit: int


  try:
    if filename.len == 0:
      validbo = false
      messt = "\p<br>" & "Select a source-file!"
    else:
      fractfl = parseFloat(fraction)
      if fractfl <= 0 or fractfl >= 1:
        validbo = false
        messt &= "\p<br>" & "Enter a fraction between 0 and 1."
      else:
        maxlinksit = parseInt(max_num_of_links)
        if maxlinksit < 1 or maxlinksit > 1000:
          validbo = false
          messt &= "\p<br>" & "Enter max_num_of_links between 1 and 1000"

  

  except ValueError:
    let errob = getCurrentException()
    echo "\p-----error start-----" 
    echo "Variable is of wrong type.."
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    messt &= "\p<br>" & $errob.name
    messt &= "\p<br>" & $errob.msg
    #echo repr(errob) 
    echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo "Custom error information here"
    echo errob.name
    echo errob.msg
    messt &= "\p<br>" & $errob.name
    messt &= "\p<br>" & $errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"
  finally:
    result = messt



when isMainModule:
  #echo genTabId()
  #var linkst = "https://www.bibliotecapleyades.net/vida_alien/xenology/papers_xeno/galacticempires.htm"
  echo "********"
  #echo getTagContent_old(linkst, "<font size", "</font>", 100)
  #echo getContentList(linkst, "990012", "</font>", docHtml, 100)
  #[  
  var st: string = "  aap noot  mies"
  echo createSearchString(st)
  ]#

  #createNoiseWordsList("noise_sources_english_generic.dat", 0.4, 15)
  #createNoiseWordsList("noise_sources_english_galact-hist.dat", 0.08, 100)
  #createNoiseWordsList("noise_sources_dutch_generic.dat", 0.3, -1)
  #echo createNoiseWordsList("noise_sources_dutch_generic.dat", 0.3, -1, true)
  echo noiseVarMessages("sdf", "0.5", "-1")

