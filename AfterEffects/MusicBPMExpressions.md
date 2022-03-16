# Consistent Music BPM Thing

1. Create a Text layer
2. Enable Expressions in "Source Text" and paste this:
```
$.bpm=240
$.bpmeasure=16
$.minscale=80
$.maxscale=100
$.delaytime=1.2
$.curbeat=Math.floor((time.toFixed(6)-$.delaytime)/(60/$.bpm))
$.curbeat=Math.max(0,$.curbeat)
$.curmusicbeat=$.curbeat%$.bpmeasure+1
$.lastmarker=$.curbeat*(60/$.bpm)
$.nextmarker=($.curbeat+1)*(60/$.bpm)
text.source=$.curmusicbeat
```
3. Enable Expressions in Transform.scale and paste this:
```
var t=(time-$.delaytime-$.lastmarker)/(60/$.bpm);
var ret=1+(--t)*t*t*t*t;
ret=ret*($.maxscale-$.minscale)+$.minscale
if ($.bpm>180 && $.curmusicbeat!=1) {
	ret=$.maxscale;
}
ret=Math.max($.minscale, ret)
thisLayer.scale=[ret,ret]
```

Made for a composition of 1920x1080 @ 60fps
