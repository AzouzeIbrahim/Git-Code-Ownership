"
run metacello with:
""
Metacello new
repository: 'github//github.com:Evref-BL/Git-Code-Ownership:main/src';
baseline: 'GitCodeOwnership';
onConflict: [ :ex | ex useLoaded ];
onUpgrade: [ :ex | ex useLoaded ];
onDowngrade: [ :ex | ex useLoaded ];
ignoreImage;
load
""
"
Class {
	#name : 'BaselineOfGitCodeOwnership',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGitCodeOwnership',
	#package : 'BaselineOfGitCodeOwnership'
}

{ #category : 'baselines' }
BaselineOfGitCodeOwnership >> baseline: spec [
	 "donne l'ensmebe des package requis pour la baseline (à inclure dans l'archive définis par Iceberg)"
	<baseline>
	spec for: #common do: [ 
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec ]

]

{ #category : 'as yet unclassified' }
BaselineOfGitCodeOwnership >> defineDependencies: spec [ 
	"donne les ref vers le projet qui se trouve sur un depot distance (je crois)"

	spec baseline: 'GitLabHealth' with: [
		spec loads: #('Jira');
		repository:
			'github://moosetechnology/GitProjectHealth:main/src' ]

]

{ #category : 'as yet unclassified' }
BaselineOfGitCodeOwnership >> defineGroups: spec [ 
"aucune idée"

]

{ #category : 'as yet unclassified' }
BaselineOfGitCodeOwnership >> definePackages: spec [ 
	"mentionne l'ensemble des packages requis (ici 4 packages )"

	spec
		package: 'Git-Code-Ownership' with: [ spec requires: #( 'GitLabHealth' ) ].

]
