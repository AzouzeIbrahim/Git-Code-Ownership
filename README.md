# Git-Code-Ownership

```smalltalk
Metacello new
repository: 'github://Evref-BL/Git-Code-Ownership:main/src';
baseline: 'GitCodeOwnership';
onConflict: [ :ex | ex useLoaded ];
onUpgrade: [ :ex | ex useIncoming ];
onDowngrade: [ :ex | ex useLoaded ];
load
```
