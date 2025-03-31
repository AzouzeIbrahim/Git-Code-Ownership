Class {
	#name : 'GitBlame',
	#superclass : 'Object',
	#instVars : [
		'commit',
		'lines'
	],
	#category : 'Git-Code-Ownership-Objects',
	#package : 'Git-Code-Ownership',
	#tag : 'Objects'
}

{ #category : 'accessing' }
GitBlame >> creator [
	^ commit author
]
