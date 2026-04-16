

#[ Sample-project "controls" to learn how to use mummy, moustachu and
my json-modules (html-elements generated from a json-definition-file).

Beware of the fact  that there are two kinds of variables:
-moustachu-variables in the html-code, in which the generated html-controls are 
substituted. Designated with {{}} or {{{}}}. Sometimes two braces are enough,
but it is saver to use three to avoid premature evaluation.
-control-variables used by jester / mummy. Jester/mummy reads control-states and puts them 
in either of two variables (i dont know if they are fully equivalent):
* variables like @"controlname"
* request.params["controlname"]

Limit the use global vars because they are not "gc-safe". GC stands for garbage-collection.
My (layman-) theory is that all threads have there own garbage-collection.
When the main thread has nothing to do with other threads globals can gc-ed allright, 
but when extra threads have been spawned, the gc of different threads gets mixed up 
concerning the globals, and therefore in that case globals have been forbidden.
(use locks for careful use of globals)

Without globals or with locked globals you can compile for multi-threading
with switch --threads:on which is mandatory in mummy (but not in jester)

See also the module projectprefix_loadjson.nim

The cookie-tunnel code has been removed because one can easily run server-code thru
the cur-action variable . This is a textarea element that can be set from javascript,
and after a form-submit can be read on the server to execute the needed server-code.


ADAP HIS
-change static_config and calls

ADAP NOW

ADAP FUT
- implement persistInLockedMem

ABORT
x- implement persistInBrowser


]#

import mummy, mummy/routers, mummy_utils, moustachu
#import mummy, mummy/routers, moustachu

import std/[times, json, tables, strutils, os, locks, math]

import frek_loadjson, frek_logic

import jolibs/generic/[g_json_plus, g_json2html, g_nim2json]

import nimclipboard/libclipboard

import jolibs/generic/[g_nim2json, g_templates]

import extlibs/locking_tables

#-----------------

import jolibs/generic/[g_options, g_disk2nim, g_database, g_db2json, g_json_plus, g_mine, g_cookie, g_tools, g_json2html]

#-----------------

const 
  versionfl:float = 0.951
  project_prefikst = "frek"
  appnamebriefst = "FK"
  appnamenormalst = "Freekwensie"
  appnamelongst = "Freekwensie_new"
  appnamesuffikst = " showcase"
  portnumberit = 5120

# ~~~~~~~locking preparation ~~~~~~~~~~~~~~~~~

# After the chat-example in mummy i have created this sample-code for using a global var.
# It compiles and works apperently.
# Remarks:
# - Use globals not as working-vars but only as end-result-vars to put in the 
# result of previous cyles etc.
# - work with tabIDs and tables if you want to link the data to a tab

var
  mylock: Lock
  globalvarst: string

  # guard-pragma (according to an AI) in-necesitates individual locks of the guarded variable.
  # but is also dissuaded by AI as being inadequate. Using withLock is recommended.
  #globalvarst {.guard: mylock.}: string

initLock(mylock)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# -------------- locked thru locking-tables module ----------

var
  # new pre-locked tables
  datasqta = initRwTable[string, seq[array[5, string]]]()
  # does not need persisting:
  #globwordsqta = initRwTable[string, seq[string]]()

  # older ones disabled
  #datasqta = initTable[string, seq[array[5, string]]]()
  #globwordsqta = initTable[string, seq[string]]()

# ----------------------------------------------------------
  


#proc showPage(par_innervarob, par_outervarob: var Context, 
#              custominnerhtmlst:string=""): string = 

#  var innerhtmlst:string
#  if custominnerhtmlst == "":
#    innerhtmlst = render(readFile(project_prefikst & "_inner.html") , par_innervarob)    
#  else:
#    innerhtmlst = custominnerhtmlst
#  par_outervarob["controls-group"] = innerhtmlst

#  return render(readFile(project_prefikst & "_outer.html"), par_outervarob)


proc showPage(par_innervarob, par_outervarob: var Context, 
            sequencest: string = "", custominnerhtmlst:string=""): string = 

  var innerhtmlst, resultst:string
  if custominnerhtmlst == "":
    innerhtmlst = render(readFile(project_prefikst & "_inner" & sequencest & ".html") , par_innervarob)    
  else:
    innerhtmlst = custominnerhtmlst
  par_outervarob["controls-group"] = innerhtmlst
  #echo "=================== innerhtmlst ========================="
  #echo innerhtmlst

  resultst = render(readFile(project_prefikst & "_outer.html"), par_outervarob)

  return resultst



# ************************ PAGE-HANDLERS STARTING HERE ****************************************

proc getRoot(request: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"

  const respondst = "Type: localhost:" & $portnumberit & "/" & project_prefikst
  request.respond(204, headers, respondst)

  

proc sayHello(request: Request) = 
  const respondst = "Hello world"
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"

  request.respond(200, headers, respondst)




proc getFreekwensie(request: Request) {.gcsafe.} = 

# ?? to understand why a project is not gcsafe, add the pragma {.gcsafe.} to get more info
#proc getProject(request: Request) {.gcsafe.} = 


  var
    innervarob: Context = newContext()  # inner html insertions
    outervarob: Context = newContext()   # outer html insertions

  innervarob["statustext"] = """Status OK"""

  var initialjnob = frek_loadjson.readInitialNode(project_prefikst)

  innervarob["newtab"] = "_self"
  outervarob["version"] = $versionfl
  outervarob["loadtime"] ="Page-load: " & $now()
  outervarob["namenormal"] = appnamenormalst
  outervarob["namelong"] = appnamelongst
  outervarob["namesuffix"] = appnamesuffikst
  outervarob["pagetitle"] = appnamelongst & appnamesuffikst   
  outervarob["project_prefix"] = project_prefikst

  innervarob["project_prefix"] = project_prefikst  
  


  # ****************** custom-logic starting here *******************

  var
    statustekst:string

  outervarob["sequence_nr"] = ""

  innervarob["statustext"] = """OK"""
  innervarob["newtab"] = "_self"
  outervarob["version"] = versionfl.formatFloat(ffDecimal, 3)
  outervarob["loadtime"] ="Page-load: " & $now()
  outervarob["namenormal"] = appnamenormalst
  outervarob["namelong"] = appnamelongst
  outervarob["namesuffix"] = appnamesuffikst
  outervarob["pagetitle"] = appnamenormalst & " _ " & appnamelongst & appnamesuffikst   
  outervarob["project_prefix"] = project_prefikst

  innervarob["project_prefix"] = project_prefikst  

  innervarob["sel_depth"] = setDropDown(initialjnob, "sel_parsing_depth", "1", 1)
  innervarob["sel_number_results"] = setDropDown(initialjnob, "sel_number_results", 
                                                                "20", 1)

  innervarob["check_show"] = setCheckBoxSet(initialjnob, "check_show_pre-results", 
                                                  @["default"])
  innervarob["set_nr"] = "1"

  innervarob["sel_alt_freqs"] = setDropDown(initialjnob, "sel_alt_freqs", "0", 1)
  # innervarob["pasted_link"] = readOptionFromFile("pastebox-default", optValue)
  innervarob["pasted_link"] = setDatalist(initialjnob, "pasted_link", readOptionFromFile("pastebox-default", optValue), "")

  innervarob["dali_expert_start"] = setDatalist(initialjnob, "dali_expert_start", "", "")
  innervarob["dali_expert_end"] = setDatalist(initialjnob, "dali_expert_end", "", "")


  innervarob["check_globfreqlist"] = setCheckBoxSet(initialjnob, "check_globfreqlist", @["default"], true)
  innervarob["check_filter_results"] = setCheckBoxSet(initialjnob, "check_filter_results", @["default"], true)
  innervarob["sel_noise_words"] = setDropDown(initialjnob, "sel_noise_words", 
                                            "noise_words_english_generic.dat", 10)


  # ****************** end of custom-logic ***************************



  let respondst = showPage(innervarob, outervarob)
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  request.respond(200, headers, respondst)




proc postFreekwensie(request: Request) {.gcsafe.} = 


  try:

    # boiler-plate code
    var
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions
      #firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp"]
      gui_jnob: JsonNode
      tabidst: string = ""

    {.gcsafe.}:
      if len(@"tab_ID") == 0:
      #if len(request.queryparams("tab_ID")) == 0:
        tabidst = genTabId()
      else:
        tabidst = @"tab_ID"
        #tabidst = request.queryparams("tab_ID")

      gui_jnob = readStoredNode(tabidst, project_prefikst, "")
      innervarob["tab_id"] = tabidst



    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()

    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamelongst & appnamesuffikst   
    outervarob["project_prefix"] = project_prefikst     


    innervarob["project_prefix"] = project_prefikst  
    innervarob["linkcolor"] = "red"



    # ****************** custom-logic starting here ***********************************

    if @"curaction" == "set new ID..":
      # regeneration of the ID and copying of the current config after cloning of tab
      tabidst = genTabId()
      {.gcsafe.}:
        # write the current page-layout to the jnob belonging to this tabID
        copyStoredNode(@"tab_ID", tabidst)
        innervarob["tab_id"] = tabidst


    # ****************** end of app-logic ***************************


    # ****************** old freek-logic **************************

    var
      statustekst, righttekst, tempst:string
      cookievaluest, locationst, mousvarnamest: string
      funcpartsta =  initOrderedTable[string, string]()
      firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "your-element"]
      #gui_jnob: JsonNode
      clipob = clipboard_new(nil)
      resultst, freqlist, sitest, parent_titlest, child_titlest, innertekst, reversest: string
      extra_list, button_nekst, button_prevst, nav_noticest: string
      linkcountit, setsizeit, setcountit, itemstartit, itemendit, getchildscountit: int
      excludesubsq, includesubsq: seq[string]
      weblinkst, globfreqtablest: string
      seqcountit, wordcountit, p_linkcountit: int
      calcglobalfreqsbo: bool = false
      words_per_linkfl: float
      start_profilingbo: bool
      filter_match_resultst, filter_test: string
      items_filtered_countit, items_total_countit: int


      # skip-list created from file:
      skiplisq: seq[string] = convertFileToSequence(@"sel_noise_words", ">>>")
      # options:
      fqwordlenghit = parseInt(readOptionFromFile("freq-word-length", optValue))
      fqlistlengthit = parseInt(readOptionFromFile("freq-list-length", optValue))
      maxcontentitemsit =  parseInt(readOptionFromFile("max-content-items", optValue))
      maxheaderitemsit =  parseInt(readOptionFromFile("max-header-items", optValue))
      introtextsizit = parseInt(readOptionFromFile("intro-text-char-number", optValue))
      targetwindowst = readOptionFromFile("target-window", optValue)
      maxshortitemit = parseInt(readOptionFromFile("max_short_items", optValue))

      weblinklisq: seq[array[5, string]]
      globalwordsq: seq[string]


    # first version of html, css-sheet, script and json-file
    outervarob["sequence_nr"] = ""


    innervarob["sel_depth"] = setDropDown(gui_jnob, "sel_parsing_depth", 
                                                        @"sel_parsing_depth", 1)

    innervarob["sel_number_results"] = setDropDown(gui_jnob, "sel_number_results", 
                                                        @"sel_number_results", 1)

    innervarob["check_show"] = setCheckBoxSet(gui_jnob, "check_show_pre-results", 
                                                    @[@"chkshow_preresults"])

    # innervarob["pasted_link"] = @"pasted_link"
    innervarob["pasted_link"] = setDatalist(gui_jnob, "pasted_link", @"pasted_link", "")

    innervarob["statustext"] = "..."
    innervarob["set_nr"] = @"set_nr"
    innervarob["sel_alt_freqs"] = setDropDown(gui_jnob, "sel_alt_freqs", @"sel_alt_freqs", 1)

    innervarob["dali_expert_start"] = setDatalist(gui_jnob, "dali_expert_start", replace(@"dali_expert_start", "\"","&quot;"), "")
    innervarob["dali_expert_end"] = setDatalist(gui_jnob, "dali_expert_end", replace(@"dali_expert_end", "\"","&quot;"), "")

    innervarob["seekbox"] = @"seekbox"
    innervarob["check_globfreqlist"] = setCheckBoxSet(gui_jnob, "check_globfreqlist", 
                                                    @[@"chkCalcGlobFreqs"], true)
    innervarob["check_filter_results"] = setCheckBoxSet(gui_jnob, "check_filter_results", 
                                                    @[@"chkFilterResults"], true)


    innervarob["sel_noise_words"] = setDropDown(gui_jnob, "sel_noise_words", 
                                                              @"sel_noise_words", 10)

    innervarob["include_in_lnx"] = @"includable"
    innervarob["exclude_from_lnx"] = @"excludable"


    if @"curaction" == "pasting..":
      outervarob["pagetitle"] = appnamelongst & appnamesuffikst    
      innervarob["pasted_link"] = setDatalist(gui_jnob, "pasted_link", $clipob.clipboard_text(), "")

      innervarob["statustext"] = "Pasting ready."


    if @"curaction" == "retrieving..":
      # (re)set the dataseq which will hold the mined weblinks for the specific tabID

      #datasqta[tabidst] = @[]
      weblinklisq = @[]

      weblinkst = @"pasted_link" & createSearchString(@"seekbox")
      echo "\p-----------------------------------------------------"
      echo "Downloading website for link-retrieval: " & weblinkst      
      sitest = getWebSite(weblinkst)
      echo "Site downloaded."
      echo "Preparing..."
      parent_titlest = getTitleFromWebsite2(weblinkst)
      outervarob["pagetitle"] = appnamebriefst & "_LNX_" & parent_titlest & "  -- " & appnamenormalst
      includesubsq = split(@"includable", ",,")
      excludesubsq = split(@"excludable", ",,") & getValList(readOptionFromFile("subs-not-in-childlinks", optValueList))
      if sitest != "":
        echo "Retrieving child-links..."
        getchildscountit = getChildLinks(weblinkst, parseint(@"sel_parsing_depth"), 1, 1, 
                                          includesubsq, excludesubsq , weblinklisq)
        echo $getchildscountit & " sublinks retrieved.."

        {.gcsafe.}:
          datasqta[tabidst] = weblinklisq

        if @"chkshow_preresults" == "chkshow_preresults":
          echo "Rendering html-table.."
          resultst = "<table id=\"weblinks_table\">\p"
          for item in weblinklisq:
            resultst &= "<tr>\p"
            reversest = ""
            seqcountit = 0
            for datum in item:
              if seqcountit == 2:
                reversest = "<td><a href=\"" & datum & "\" target=\"" & targetwindowst & "\">" & datum & "</a></td>\p" & reversest
              else:
                reversest = "<td>" & datum & "</td>\p" & reversest
              seqcountit += 1
            resultst &= reversest
            resultst &= "</tr>\p"

          resultst &= "</table>\p"
          innervarob["results_list"] = resultst

        innervarob["statustext"] = $len(weblinklisq) & " weblinks retrieved.."
        echo "Rendering complete!"
      else:
        innervarob["statustext"] = "Could not acquire website.."
        echo "No rendering of sublinks requested. Ready"
      echo "-----------------------------------------------------"


    if @"curaction" == "profiling..":
      {.gcsafe.}:
        weblinklisq = datasqta[tabidst]

      # reset the global word-store (to create later global word-freqs)
      globalwordsq = @[]
      
      filter_test = filterIsMatching("", @"seekbox", true)
      var keyfoundbo: bool
      {.gcsafe.}:
        keyfoundbo = datasqta.hasKey(tabidst)

      if $innervarob["tab_id"] != "" and keyfoundbo and (@"chkFilterResults" == "" or filter_test == "filter_ok"):

        if @"chkCalcGlobFreqs" == "chkCalcGlobFreqs": calcglobalfreqsbo = true
        button_nekst = "<button name=\"butNext\" class=\"allbuttons but_prev_next\" type=\"button\" onclick=\"getNextSet()\">Next set</button>"
        button_prevst = "<button name=\"butPrev\" class=\"allbuttons but_prev_next\" type=\"button\" onclick=\"getPrevSet()\">Previous set</button>"
        weblinkst = @"pasted_link" & createSearchString(@"seekbox")      
        parent_titlest = getTitleFromWebsite2(weblinkst)
        outervarob["pagetitle"] = appnamebriefst & "_" & parent_titlest & "  -- " & appnamenormalst
        linkcountit = 1
        setsizeit = parseint(@"sel_number_results")
        setcountit = parseint(@"set_nr") - 1
        itemstartit = (setcountit * setsizeit) + 1
        itemendit  = (setcountit + 1) * setsizeit
        nav_noticest = "<center>" & button_prevst & "Results from " & $itemstartit & " thru " & $itemendit & button_nekst & "</center><br><br>\p"

        echo "\p--------------start profiling-------------------------"
        items_total_countit = 0
        items_filtered_countit = 0

        for item in weblinklisq:
          if linkcountit >= itemstartit and linkcountit <= itemendit:
            start_profilingbo = true
            sitest = getWebSite(item[2])
            innertekst = getInnerText2(sitest, -1, 80)
            items_total_countit += 1

            if @"chkFilterResults" == "chkFilterResults":
              filter_match_resultst = filterIsMatching(innertekst, @"seekbox", false, item[4])
              if filter_match_resultst != "yes":
                start_profilingbo = false
              else:
                items_filtered_countit += 1

            child_titlest = getTitleFromWebsite2(item[2])
            if sitest != "" and start_profilingbo:
              echo "Profiling nr...... " & $item[4]
              freqlist = calcWordFrequencies(innertekst, fqwordlenghit, skiplisq, true, fqlistlengthit, parseint(@"sel_alt_freqs"))

              if calcglobalfreqsbo: calcCumulFrequencies(innertekst, fqwordlenghit, skiplisq, parseint(@"sel_alt_freqs"), globalwordsq)

              resultst &= "<table>\p"
              resultst &= "<tr>\p"
              resultst &= "<td id=\"first_row_prof_table\" colspan=\"3\">- " & child_titlest & "<br>- " & item[3] & "</td>\p"
              resultst &= "<td id=\"freq_col_prof_table\" rowspan=\"5\">" & freqlist & "</td>\p"
              if @"dali_expert_start" != "" and @"dali_expert_end" != "":
                extra_list = getContentList(sitest, @"dali_expert_start", @"dali_expert_end", docHtml, maxcontentitemsit)
              else:
                extra_list = getHtmlHeaders(sitest, docHtml, maxheaderitemsit)

              if extra_list.len > 0:
                resultst &= "<td id=\"extra_col_prof_table\" rowspan=\"5\">" & extra_list & "</td>\p"

              resultst &= "<tr>\p"
              resultst &= "<td colspan=\"3\"><a href=\"" & item[2] & "\" target=\"" & targetwindowst & "\">" & item[2] & "</a></td>\p"
              resultst &= "</tr>\p"

              resultst &= "<tr>\p"
              resultst &= "<td colspan=\"3\">" & getIntroText(getInnerText3(sitest, 80, "__", maxshortitemit), introtextsizit) & "</td>\p"
              resultst &= "</tr>\p"

              wordcountit = countWords(innertekst)
              p_linkcountit = count(sitest, "<a ")
              words_per_linkfl = round(float(wordcountit) / float(p_linkcountit))

              resultst &= "<tr>\p"
              resultst &= "<td>Depth: " & item[1] & 
                          "<br>Words: " & $wordcountit & "</td>\p"
              resultst &= "<td>Links: " & $p_linkcountit & 
                            "<br>Images: " & $count(sitest, "<img ") & 
                            "<br>Words/link: " & $words_per_linkfl & "</td>\p"

              resultst &= "<td>" & getYearInfo(innertekst) & "</td>\p"
              resultst &= "</tr>\p"


              resultst &= "<tr>\p"
              resultst &= "<td>" & item[4] & "</td>\p"
              resultst &= "<td colspan=\"2\">" & item[0] & "</td>\p"
              resultst &= "</tr>\p"

              resultst &= "</table><br><br>\p"

          linkcountit += 1

        echo "\pRendering tables..."
        echo "--------------end profiling-------------------------\p"


        if calcglobalfreqsbo:
          globfreqtablest = createFreqTableFromWordList(globalwordsq, 6, 20)
          resultst = nav_noticest & globfreqtablest & resultst & nav_noticest
        else:
          resultst = nav_noticest & resultst & nav_noticest

        innervarob["results_list"] = resultst

        statustekst = "Results " & $itemstartit & " thru " & $itemendit & 
                            " shown of " & $len(weblinklisq) & " retrieved weblinks "
        if @"chkFilterResults" == "chkFilterResults":
          statustekst &=  "(" & $items_filtered_countit & " filtered of " & $items_total_countit & ")"
        else:
          statustekst &= "(" & $items_total_countit & " shown)"
        innervarob["statustext"] = statustekst
      elif $innervarob["tab_id"] == "" or not (keyfoundbo):
        innervarob["statustext"] = "Please retrieve web-links before profiling..."
      elif filter_test != "filter_ok":
        innervarob["statustext"] = filter_test


    # ****************** end old freek *****************************




    {.gcsafe.}:
      # write the current page-layout to the jnob belonging to this tabID
      writeStoredNode(tabidst, gui_jnob)



    let respondst = showPage(innervarob, outervarob, "")
    var headers: HttpHeaders
    headers["Content-Type"] = "text/html"
    request.respond(200, headers, respondst)

  
  #except ValueError:
  #  let errob = getCurrentException()
  #  echo "\p-----error start-----" 
  #  echo "Custom error information here"
  #  echo "System-error-description:"
  #  echo errob.name
  #  echo errob.msg
  #  #echo repr(errob) 
  #  echo "----End error-----\p"

    #unanticipated errors come here
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo errob.name
    echo errob.msg
    echo repr(errob) 
    echo "\p****End exception****\p"
  finally:
    #echo "do this always afterwards"
    discard



proc cssHandler*(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/css"
  request.respond(200, headers, readFile("public/" & project_prefikst & "_sheet.css"))


proc scriptHandler*(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/javascript"
  request.respond(200, headers, readFile("public/" & project_prefikst & "_script.js"))




# ************** ROUTE-DEFINITIONS HERE *******************************

var router: Router

router.get("/public/" & project_prefikst & "_sheet.css", cssHandler)
router.get("/public/" & project_prefikst & "_script.js", scriptHandler)
router.get("/", getRoot)
router.get("/hello", sayHello)
router.get("/" & project_prefikst, getFreekwensie)
router.post("/" & project_prefikst, postFreekwensie)



let server = newServer(router)
echo "Serving on http://localhost:" & $portnumberit
server.serve(Port(portnumberit))


