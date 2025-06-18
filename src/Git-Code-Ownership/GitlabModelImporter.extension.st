Extension { #name : 'GitlabModelImporter' }

{ #category : '*Git-Code-Ownership' }
GitlabModelImporter >> UserContributionFromBlameInFile: blame [
    | emails totalLines result  |
       "bl := blame reject: [:item | item isEmpty ]."
    "Extract unique emails from the blame list"
    emails := (blame collect: [ :element | 
        (element at: 'commit') at: 'author_email' 
    ]) asSet.

    "Calculate total number of lines"
    totalLines := (blame collect: [ :element | 
        (element at: 'lines') size 
    ]) sum.

    "Initialize result dictionary"
    result := Dictionary new.
    emails do: [ :email | result at: email put: 0. ].

    "Distribute line contributions proportionally"
    blame do: [ :element | 
        | authorEmail linesSize |
        authorEmail := (element at: 'commit') at: 'author_email'.
        linesSize := (element at: 'lines') size.

        "Ensure authorEmail exists before updating count"
        (result at: authorEmail ifAbsent: [ 0 ]) 
            ifNotNil: [ result at: authorEmail put: ((result at: authorEmail) + (linesSize / totalLines) ) ].
    ].

    ^ result.

]

{ #category : '*Git-Code-Ownership' }
GitlabModelImporter >> UserContributionFromBlames: blamesArray [
    | dictionary_Emails_Lines line blames   |
     "filter if  the blame isn't nil  bacause some file like media and photo doesn't have blame  "
    blames := blamesArray reject: [:item | item isNil].
    "Step 1: Initialize dictionary to store email -> total lines count"
    dictionary_Emails_Lines := Dictionary new.
    "calculer le nombre totale des ligns "
    line :=  blames collect: [ :bl |
    bl  collect: [ :element |
	    |  lines |
        lines :=  ((element at: 'lines')size) .
    ]
   ].
    line:=( line flattened) sum .

    "Step 2: Process each blame dictionary"
     blames do: [:blameEntries |
        blameEntries isArray ifTrue: [  "Ensure it's a valid blame entry"
            blameEntries do: [:element | 
                | authorEmail linesSize |
                authorEmail := (element at: 'commit') at: 'author_email'.
                linesSize := (element at: 'lines') size.  "Number of lines modified"

                "Update dictionary (add lines if email exists, otherwise initialize)"
                (dictionary_Emails_Lines includesKey: authorEmail)
                    ifTrue: [ dictionary_Emails_Lines at: authorEmail put: ((dictionary_Emails_Lines at: authorEmail) + ((linesSize)/line)asFloat ) ]
                    ifFalse: [ dictionary_Emails_Lines at: authorEmail put:((linesSize/line)asFloat) ].
            ].
        ].
    ].

    "Return the final dictionary of email -> total modified lines"
    ^ dictionary_Emails_Lines

]

{ #category : '*Git-Code-Ownership' }
GitlabModelImporter >> getBlameOf: filePath inBranch: branch ofProject: projectId [

	| results   jsonObject  result |
		
	           results := self repoApi repositories getBlameOf: filePath  inRef:    branch ofProject: projectId       .
              jsonObject := NeoJSONReader fromString: results .
              result:= (jsonObject isArray ifTrue: [jsonObject ] ifFalse: [#()]).
"              result:= result reject: [:item | item isNil]."
   ^result 
	

	
]

{ #category : '*Git-Code-Ownership' }
GitlabModelImporter >> getBlameOf: filePath inBranch: ref withRange:gitlabRange ofProject:projectId [
	| results    jsonObject  result |
	           results := self repoApi repositories 	getBlameOf: filePath inRef: ref withRange:gitlabRange ofProject:projectId      .
              jsonObject := NeoJSONReader fromString: results .
              result:= (jsonObject isArray ifTrue: [jsonObject ] ifFalse: [nil]).
"              result:= result reject: [:item | item isNil]."
   ^result 
	

	
]
