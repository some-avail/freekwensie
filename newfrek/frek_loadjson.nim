
#[ Module-function: 
  This module concerns both the initial json-node
  and the stored json-node that is bound to a tab-ID.


  Initial node:
  Read the json-file, convert it to a jnob,
  load additional public data to the jnob, and 
  expose it as function.

  Public in this context means unchangable data
  relevant to all users.
  User-data must be loaded from the routes-location
  in project_startup.nim to avoid shared data.

  Stored node in memory:
  In this all tab-specific changes are stored, so 
  that the state of the tab's gui is saved. 
  When saved in memory this breaks no longer 
  multi-threading because of a global var,
  since now official locking-mechanisms are used.
  (always use withlock for all global heap-structure-ops, 
  preferably use pre-made operations to minimize errors).

  When you want to use this code in production (website) you 
  must add code to remove unused IDs from jsondefta. (see adap fut)

  ADAP HIS:
  - alternate persistance to disk has been deprecated / removed

  ADAP FUT:
  -implement periodical clearance of jsondefta to avoid 
  out-of-memory-situation
  -refactor this module by:
    -leaving the project-specific code in projprefix_loadjson
    -moving the generic code to g_loadjson.nim
 ]#


import std/[json, tables, os, times, strutils, locks]

# only import g_json_plus and g_db2json when needed
import jolibs/generic/[g_json_plus, g_disk2nim, g_nim2json, g_tools, g_templates]
#import jolibs/generic/[g_db2json]


let versionfl: float = 0.53


var liblock: Lock
initLock(liblock)


# create a table with jnobs, one for every tab
#when persisttype == persistInMem:
var jsondefta = initTable[string, JsonNode]()


proc addOrUpdateDefTable(jsondefta: var Table[string, JsonNode]; nodeob: JsonNode; tabidst: string) = 
  # gc-safe operations; add or update
  # do it present or not
  withLock liblock:
    jsondefta[tabidst] = nodeob

proc addDefTable(jsondefta: var Table[string, JsonNode]; nodeob: JsonNode; tabidst: string) = 
  # gc-safe operations; add
  # only if not yet present
  withLock liblock:
    if not jsondefta.hasKey(tabidst):
      jsondefta[tabidst] = nodeob

proc readDefTable*(jsondefta: var Table[string, JsonNode]; tabidst: string): JsonNode =
# gc-safe operations; read
  withLock liblock:
    if jsondefta.hasKey(tabidst):
      result = jsondefta[tabidst]
    else:
      wispbo = true
      wisp("No key present; returning newJNull")
      wispbo = false

      result = newJNull()



#[
#  BELOW PROCS ARE NOT YET USED

proc updateDefTable*(jsondefta: var Table[string, JsonNode]; nodeob: JsonNode; tabidst: string) = 
  # gc-safe operations; update
  # only if present
  withLock liblock:
    if jsondefta.hasKey(tabidst):
      jsondefta[tabidst] = nodeob

proc deleteDefTable*(jsondefta: var Table[string, JsonNode]; tabidst: string) =
  # gc-safe operations; delete
  withLock liblock:
    if jsondefta.hasKey(tabidst):
      jsondefta.del(tabidst)
]#


proc initialLoading(parjnob: JsonNode, pagest: string): JsonNode = 
  #[
  custom - load extra public data to the json-object (for example a user-list from a database)
  This is the only custom / project-specific function in this module.
  ]#
  wispbo = true
  wisp("pagest = ", pagest)
  wispbo = false
  var 
    tablesq: seq[string]
    firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "your-elem-type"]
    newjnob: JsonNode = parjnob
    datalisq: seq[array[2, string]]
    tempjnob: JsonNode
    datasq: seq[string]

  if pagest == "":   # first page: project_inner.html
    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "dropdowns fp")
    datalisq = addShowValuesToSeq(writeFilePatternToSeq("noise_words"), "noise_words", "*")
    tempjnob = createDropdownNodeFromSeq("sel_noise_words", "Pick noise-filter(s):", datalisq)
    graftJObjectToTree("sel_noise_words", firstelems_pathsq, newjnob, tempjnob)

    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "datalists fp")
    datasq = convertFileToSequence("lists/parent_links.dat", "##")
    datalisq = zipTwoSeqsToOne(datasq)
    tempjnob = createPicklistNodeFromSeq(pickDataList, "pasted_link", "", datalisq)
    graftJObjectToTree("pasted_link", firstelems_pathsq, newjnob, tempjnob)    

    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "datalists fp")
    datasq = convertFileToSequence("lists/expert_start.dat", "##")
    datalisq = zipTwoSeqsToOne(datasq)
    tempjnob = createPicklistNodeFromSeq(pickDataList, "dali_expert_start", "", datalisq)
    graftJObjectToTree("dali_expert_start", firstelems_pathsq, newjnob, tempjnob)    

    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "datalists fp")
    datasq = convertFileToSequence("lists/expert_end.dat", "##")
    datalisq = zipTwoSeqsToOne(datasq)
    tempjnob = createPicklistNodeFromSeq(pickDataList, "dali_expert_end", "", datalisq)
    graftJObjectToTree("dali_expert_end", firstelems_pathsq, newjnob, tempjnob)    

    # below database-code was sleeping db-code and is now disabled

  elif pagest == "02":  # second page: project_inner02.html
    discard

  #  firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "dropdowns fp")
  #  #graftJObjectToTree("All_tables", firstelems_pathsq, newjnob, 
  #  #                  createDropdownNodeFromDb("All_tables", "sqlite_master", @["name", "name"], 
  #  #                      compString, @[["type", "table"]], @["name"], "ASC"))
  #  graftJObjectToTree("All_tables", firstelems_pathsq, newjnob, 
  #                    createDropdownNodeFromDb("All_tables", "sqlite_master", @["name", "name"], 
  #                        compNotSub, @[["type", "index"],["name", "sqlite"]], @["name"], "ASC"))

  elif pagest == "03":   # third page: project_inner03.html
    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "dropdowns fp")
    
    datalisq = addShowValuesToSeq(writeFilePatternToSeq("noise_sources"), "", "")
    tempjnob = createDropdownNodeFromSeq("sel_noise_sources", "Select a noise-source:", datalisq)
    graftJObjectToTree("sel_noise_sources", firstelems_pathsq, newjnob, tempjnob)

    datalisq = addShowValuesToSeq(writeFilePatternToSeq("noise_words"), "", "")
    tempjnob = createDropdownNodeFromSeq("sel_noise_words", "Noise-word-lists:", datalisq)
    graftJObjectToTree("sel_noise_words", firstelems_pathsq, newjnob, tempjnob)

  #result = parjnob
  result = newjnob




proc readInitialNode*(proj_prefikst: string, pagest: string = ""): JsonNode = 

  # read a stored json-file and use it as the initial gui-config
  # pagest enables alternative inner html pages

  var 
    filest: string
    jnob, secondjnob: JsonNode

  filest = proj_prefikst & "_gui" & pagest & ".json"
  #echo "readInitialNode says: ", filest
  
  jnob = parseFile(filest)
  # optionally add data below
  secondjnob = initialLoading(jnob, pagest)

  result = secondjnob



proc readStoredNode*(tabIDst, project_prefikst: string, pagest: string = ""): JsonNode  = 

  # read the memory-stored json-config belonging to this webpage-id

  wispbo = true
  wisp("tabIDst = ", tabIDst)
  wispbo = false


  var initnodeob: JsonNode = readInitialNode(project_prefikst, pagest)

  {.gcsafe.}:
    addDefTable(jsondefta, initnodeob, tabIDst)  #  adds initnode only if not present
    #result = jsondefta[tabIDst]
    result = readDefTable(jsondefta, tabIDst)



proc copyStoredNode*(oldtabIDst, newtabIDst: string) = 

  # copy a stored node and link it a new ID (usefull after cloning a tab)

  var 
    oldstoredjnob: JsonNode

  {.gcsafe.}:
    oldstoredjnob = readDefTable(jsondefta, oldtabIDst)
    # store in table of json-nodes
    addDefTable(jsondefta, oldstoredjnob, newtabIDst) 



proc writeStoredNode*(tabIDst: string, storedjnob: JsonNode) = 

  # when a page has changed config you must write a to the ID-linked json-node

  {.gcsafe.}:
    # store in table of json-nodes
    addOrUpdateDefTable(jsondefta, storedjnob, tabIDst)   # existing or not

    



when isMainModule:
  #deleteExpiredFromAccessBook()
  echo "hi"

