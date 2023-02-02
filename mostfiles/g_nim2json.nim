#[ Exchange nim-structs with json-structs
]#

import std/[json]


proc createDropdownNodeFromSeq*(dropdownnamest, labelst: string, 
                                datalisq: seq[array[2, string]]): JsonNode = 

  #[ Create a json-object for the select-element (dropdown (dd) or picklist)
    From the datalisq, the first elem is the real-value, the second one the shown value.
   ]#

  var
    ddjnob: JsonNode = %*{}
    rowcountit: int = 0


  ddjnob.add(dropdownnamest, %*{})
  ddjnob[dropdownnamest].add("ddlab", %labelst)
  ddjnob[dropdownnamest].add("ddvalues", %*[])


  for ar in datalisq:
    ddjnob[dropdownnamest]["ddvalues"].add(%*{})
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("real-value", %ar[0])
    ddjnob[dropdownnamest]["ddvalues"][rowcountit].add("show-value", %ar[1])
    rowcountit += 1

  result = ddjnob




when isMainModule:
  echo createDropdownNodeFromSeq("mydd", "labeltje", @[["aap", "toon-aap"], ["noot", "toon-noot"]])

