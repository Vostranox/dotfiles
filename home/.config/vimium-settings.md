# Custom key mappings

```
map o scrollPageDown
map u scrollPageUp

map h goBack
map a scrollDown
map e scrollUp
map i goForward
map E previousTab
map A nextTab

map , performFind
map . performBackwardsFind

map l reload
map c Vomnibar.activate
map C Vomnibar.activateInNewTab

map r LinkHints.activateMode
map R LinkHints.activateModeToOpenInNewTab
map t enterInsertMode
map s enterFindMode

map + scrollToTop
map - scrollToBottom
```

# Characters used for link hints

```
nrtsgyhaeildcfou
```

# CSS for Vimium UI

```css
div > .vimiumHintMarker {
  background: #f0ca54;
  border: 1px solid #181818;
}

div > .vimiumHintMarker span {
  color: #000000;
  font-weight: bold;
  font-size: 12px;
  text-shadow: none;
}

div > .vimiumHintMarker > .matchingCharacter {
  color: #484848;
}

body.vimium-find-mode ::selection,
body.vimiumFindMode ::selection {
  background-color: #87bc61 !important;
  color: #181818 !important;
  text-shadow: none !important;
}

body::selection,
body *::selection {
  background-color: #87bc61 !important;
  color: #181818 !important;
}
```
