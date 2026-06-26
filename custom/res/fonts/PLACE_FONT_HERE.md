# ქართული ფონტი

ჩასვი `NotoSansGeorgian.ttf` ამ დირექტორიაში.

წყარო (OFL ლიცენზია, კომერციულად თავისუფალი):
- Noto Sans Georgian — https://fonts.google.com/noto/specimen/Noto+Sans+Georgian
- ალტერნატივა: BPG фонтები (bpg-fonts), ან Fira GO (ქართულის მხარდაჭერით)

ფაილის სახელი ზუსტად `NotoSansGeorgian.ttf` უნდა იყოს — ემთხვევა:
- `custom/CMakeLists.txt` (qt_add_resources)
- `custom/src/CustomPlugin.cc` (addApplicationFont)

variable font-ის შემთხვევაში გამოიყენე static weight (Regular + Medium + Bold) ცალკე ფაილებად
და დაარეგისტრირე სამივე.
